echo "coping image..."
sudo cp \
    ./images/amzn2-template.qcow2 \
    /var/lib/libvirt/images/amzn2-root.qcow2

echo "making iso..."
sudo genisoimage \
    -output /var/lib/libvirt/images/seed.iso \
    -volid cidata \
    -joliet \
    -rock \
    ./seedconfig/user-data \
    ./seedconfig/meta-data \

echo "installing kvm..."
sudo virt-install \
    --name Amazon-Linux-2023 \
    --memory 2048 \
    --vcpus 2 \
    --disk path=/var/lib/libvirt/images/amzn2-root.qcow2,format=qcow2 \
    --disk path=/var/lib/libvirt/images/seed.iso,device=cdrom \
    --os-variant fedora36 \
    --virt-type kvm \
    --graphics vnc \
    --console pty,target_type=serial \
    --import