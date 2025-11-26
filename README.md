# Amazon AWS EC2 on KVM/QEMU
### Bash скрипт автоматизирующий установку VM Amazon Linux 2023
## Quick start run:
### 1. Clone the repo:
```bash
git clone https://github.com/Tsuyakashi/kvm-on-machine.git
```
### 2. `cd` to the dir
```bash
cd kvm-on-machine
```
### 3. Make sure script executable
```bash
chmod +x kvm-install.sh
```
### 4. Run script with `sudo`
```bash
sudo ./kvm-install.sh
```

  ### !! restart may be requiered !! 

## How to connect:
### 1. Check VM's ip
```bash
virsh domifaddr Amazon-Linux-2023
```
### 2. Check access rights for `rsa.key`
```bash
sudo chmod 644 ./keys/rsa.key
```
### 3. Connect by ssh
```bash
ssh -i "./keys/keys/rsa.key" ec2-user@vm.ip
```  
## Added:
### Ubuntu distro by running:
```bash
sudo ./kvm-install.sh --ubuntu
```
- but personal seedconfig didn't added yet
- same with resize img func
### Also exists:
```bash
sudo ./kvm-install.sh --full # to skip instalation approve

sudo ./kvm-install.sh --debug # for debug menu
```
## Reqs:
  ```bash
  sudo apt update
  sudo apt -y install \
    bridge-utils \
    cpu-checker \
    libvirt-clients \
    libvirt-daemon \
    libvirt-daemon-system \
    qemu-system-x86 \
    virtinst \
    virt-manager \
    genisoimage
  ```  

## XML network config:
  ```XML
  <network>
  <name>default</name>
  <forward mode="nat">
    <nat>
      <port start="1024" end="65535"/>
    </nat>
  </forward>
  <bridge name="virbr0" stp="on" delay="0"/>
  <mac address="52:54:00:e5:c6:b3"/>
  <ip address="192.168.122.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.122.2" end="192.168.122.254"/>
    </dhcp>
  </ip>
</network>
  ``` 

## Useful links:
  - amazon download page: https://docs.aws.amazon.com/linux/al2023/ug/outside-ec2-download.html
  - amzn2 image download link: https://cdn.amazonlinux.com/al2023/os-images/2023.9.20251105.0/kvm/al2023-kvm-2023.9.20251105.0-kernel-6.1-x86_64.xfs.gpt.qcow2
  - how to install by yourself guide: https://cloudspinx.com/how-to-install-amazon-linux-2023-on-kvm-using-qcow2-image/
  - kvm in container: https://github.com/qemus/qemu
