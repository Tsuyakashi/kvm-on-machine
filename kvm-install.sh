#!/bin/bash

set -e

ROOT_PASSWORD="root123"

APT_UPDATED_PACKS=false
    
IMAGE_SIZE=20g
VM_MEMORY=2048
VM_CPUS=2

FULL_FLAG=false
DEBUG_FLAG=false
VM_OS="ubuntu" # default distribution

function isRoot() {
	if [ "${EUID}" -ne 0 ]; then
		echo "[KVM INSTALLER]: You need to run this script as root"
		exit 1
	fi
}

isRoot

function init() {
	echo "Welcome to kvm-on-machine installer!"
	echo "The git repository is available at: https://github.com/Tsuyakashi/kvm-on-machine"
	echo ""
    echo "[KVM INSTALLER]: Start $VM_NAME autoinstallaion?"
	read -n1 -r -p "Press any key to continue..."

    fullInstall
}

function installRequirements() {
    # add installation check
    echo " "
    echo "[KVM INSTALLER]: Installing requied packages with apt"
    echo " "
    
    checkPacks "bridge-utils" 
    checkPacks "cpu-checker" 
    checkPacks "libvirt-clients" 
    checkPacks "libvirt-daemon" 
    checkPacks "libvirt-daemon-system" 
    checkPacks "qemu-system-x86" 
    checkPacks "virtinst" 
    checkPacks "virt-manager" 
    checkPacks "genisoimage"

    echo " "
    echo "[KVM INSTALLER]: All packages are installed"
    echo " "
}

function checkPacks() {
    local PACKAGE_NAME="$1" 
    if ! dpkg -s "$PACKAGE_NAME" &>/dev/null; then
        if [[ $APT_UPDATED_PACKS != true ]]; then
            apt update &> /dev/null
            APT_UPDATED_PACKS=true
        fi
        echo "[KVM INSTALLER]: installing $PACKAGE_NAME"
        apt install -y "$PACKAGE_NAME" &> /dev/null
    else
        echo "[KVM INSTALLER]: $PACKAGE_NAME is installed."
    fi
}    

function getImage() {
    echo "[KVM INSTALLER]: Getting $VM_NAME image"
    if [ ! -f "./images/$VM_IMAGE_TEMPLATE" ]; then
        mkdir -p ./images/
        wget -O ./images/$VM_IMAGE_TEMPLATE $VM_IMAGE_LINK
        chown -R $SUDO_USER:$SUDO_USER ./images
    else 
        echo "[KVM INSTALLER]: Already downloaded"
    fi
} 

function mkLibvirtDir() {
    mkdir -p /var/lib/libvirt/images/
}

function cpImage() {
    #add reinstalling
    echo "[KVM INSTALLER]: Coping image"
    if [ ! -f "/var/lib/libvirt/images/$VM_IMAGE" ]; then
        cp ./images/$VM_IMAGE_TEMPLATE /var/lib/libvirt/images/$VM_IMAGE
    else
        echo "[KVM INSTALLER]: Root disk already exists"
    fi
}

function resizeImage() {
    echo "[KVM INSTALLER]: Resizing image for $IMAGE_SIZE"
    if [[ "$VM_IMAGE" != "amzn2-root.qcow2" ]]; then
        qemu-img resize /var/lib/libvirt/images/$VM_IMAGE $IMAGE_SIZE >/dev/null
    else
        echo "[KVM INSTALLER]: Amazon Linux does not support resizing, skipping"
    fi
}

function createDiskB() {
    additionalDiskName="$VM_NAME-disk.qcow2"
    echo "[KVM INSTALLER]: Creating additional disk"
    if [ ! -f "/var/lib/libvirt/images/$additionalDiskName" ]; then
        qemu-img create -f qcow2 /var/lib/libvirt/images/$additionalDiskName 25G &>/dev/null
    else
        echo "[KVM INSTALLER]: Additional disk already exists"
    fi
}

function keysGen() {
    echo "[KVM INSTALLER]: Generating rsa keys"
    mkdir -p ./keys/
    if [ ! -f "./keys/rsa.key" ]; then
        ssh-keygen -f ./keys/rsa.key -t rsa -N "" > /dev/null
        chmod 600 ./keys/rsa.key
        chmod 644 ./keys/rsa.key.pub
        chown -R $SUDO_USER:$SUDO_USER ./keys
    else
        echo "[KVM INSTALLER]: Keys already exist"
    fi
    
}

function seedConfigGen() {
    echo "[KVM INSTALLER]: Creating seed config"
    mkdir -p ./seedconfig/
    if [ ! -f "./seedconfig/user-data" ] || ! grep "$VM_USER" ./seedconfig/user-data >/dev/null; then
        tee ./seedconfig/user-data &>/dev/null <<EOF
#cloud-config
#vim:syntax=yaml
users:
  - name: $VM_USER
    gecos: some text can be here
    sudo: ALL=(ALL) NOPASSWD:ALL
    plain_text_passwd: $ROOT_PASSWORD # it will be better to edit and even to encrypt
    groups: sudo, admin
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ./keys/rsa.key.pub)
EOF
    else 
        echo "[KVM INSTALLER]: user-data already exists"
    fi
    
    if [ ! -f "./seedconfig/meta-data" ] || ! grep "$VM_NAME" ./seedconfig/meta-data >/dev/null; then
        tee ./seedconfig/meta-data &>/dev/null <<EOF
#cloud-config
local-hostname: $VM_NAME.local
EOF
    else 
        echo "[KVM INSTALLER]: meta-data already exists"
    fi
    chown -R $SUDO_USER:$SUDO_USER ./seedconfig
}

function mkIso() {
    echo "[KVM INSTALLER]: Making iso"
    # I: -input-charset not specified, using utf-8 (detected in locale settings)
    genisoimage \
        -output /var/lib/libvirt/images/seed-$VM_NAME.iso \
        -volid cidata \
        -joliet \
        -rock \
        ./seedconfig/user-data \
        ./seedconfig/meta-data &>/dev/null
}

function initKvm() {
    echo "[KVM INSTALLER]: Installing $VM_NAME VM"
    virt-install \
        --name $VM_NAME \
        --memory $VM_MEMORY \
        --vcpus $VM_CPUS \
        --disk path=/var/lib/libvirt/images/$VM_IMAGE,format=qcow2 \
        --disk path=/var/lib/libvirt/images/seed-$VM_NAME.iso,device=cdrom \
        --disk path=/var/lib/libvirt/images/$additionalDiskName,format=qcow2 \
        --os-variant $OS_VARIANT \
        --virt-type kvm \
        --graphics none \
        --console pty,target_type=serial \
        --noautoconsole \
        --import 
}

function checkInit() {
    for i in {1..30}; do
        if virsh domifaddr $VM_NAME | grep -q "ipv4"; then
            echo "[KVM INSTALLER]: VM is running on $(virsh domifaddr $VM_NAME \
            | awk '/ipv4/ { split($4, a, "/"); print a[1] }')"
            return 0
        fi
        echo "[KVM INSTALLER]: VM is still starting"
        sleep 5
    done
    echo "VM did not become available in time"
    return 1
}

function fullInstall() {
    installRequirements
    getImage
    mkLibvirtDir
    cpImage
    resizeImage
    createDiskB
    keysGen
    seedConfigGen
    mkIso
    initKvm
    checkInit
}

function manageMenu() {
	echo "Welcome to kvm-on-machine installer!"
	echo "The git repository is available at: https://github.com/Tsuyakashi/kvm-on-machine"
	echo ""
	echo "It looks like kvm-on-machine is already running/installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Show VM"
	echo "   2) Check VM ip"
	echo "   3) Shutdown VM"
	echo "   4) Destroy VM"
	echo "   5) Exit"
    until [[ ${MENU_OPTION} =~ ^[1-5]$ ]]; do
		read -rp "Select an option [1-5]: " MENU_OPTION
	done
	case "${MENU_OPTION}" in
	1)
		listVM
		;;
	2)
        showIP
        ;;
    3)
		shutVMDown
		;;
	4)
		destroyVM
		;;
	5)
		exit 0
		;;
	esac
}

function listVM () {
    virsh list | grep $VM_NAME
}

function showIP () {
    virsh domifaddr $VM_NAME
}

function shutVMDown() {
    virsh shutdown $VM_NAME
}

function destroyVM () {
    virsh destroy $VM_NAME
    virsh undefine $VM_NAME --remove-all-storage
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dist)
            if [[ -z "$2" ]]; then
                echo "Error: --dist requires a distribution name"
                exit 1
            fi
            VM_OS="$2"
            shift 2
            ;;
        --full)
            FULL_FLAG=true
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dist <distribution> - set distribution (default: ubuntu)"
            echo "  --full - full install (default: false)"
            echo "  --help - show this help message"
            exit 0
            ;;
        --debug)
            DEBUG_FLAG=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if $DEBUG_FLAG; then
    echo "debug mode is enabled"
fi

if [[ "$VM_OS" == "ubuntu" ]]; then
    VM_NAME="Ubuntu-Noble"
    VM_USER="ubuntu"
    OS_VARIANT="ubuntujammy"
    VM_IMAGE="ubuntu-root.qcow2"
    VM_IMAGE_TEMPLATE=ubuntu-template.qcow2
    VM_IMAGE_LINK=https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.qcow2
elif [[ "$VM_OS" == "amazon" ]]; then
    VM_NAME="Amazon-Linux"
    VM_USER="ec2-user"
    OS_VARIANT="fedora38"
    VM_IMAGE="amzn2-root.qcow2"
    VM_IMAGE_TEMPLATE="amzn2-template.qcow2"
    VM_IMAGE_LINK=https://cdn.amazonlinux.com/al2023/os-images/2023.9.20251105.0/kvm/al2023-kvm-2023.9.20251105.0-kernel-6.1-x86_64.xfs.gpt.qcow2
else
    echo "Unknown distribution: $VM_OS"
    exit 1
fi

if $FULL_FLAG; then
    fullInstall
    exit
fi

if virsh list --all --name | grep -q "$VM_NAME"; then
    manageMenu
    exit
fi

init
