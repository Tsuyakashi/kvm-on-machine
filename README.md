# Amazon AWS EC2 on KVM/QEMU
## How to run:
  - clone repo
  - download amzn2 image as amzn2-template.qcow2 in images/
  - generate rsa keys with 
    ```bash
      ssh-keygen -t rsa   
    ```
  - update user-data with rsa.pub
  - run install-kvm.sh

## How to connect:
  ```bash
    ssh -i "REPO_DIR/keys/rsa.key" ec2-user@ip.from.kvm
  ```  

## Needs:
  - in progress...

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
  - amzn2 image: https://cdn.amazonlinux.com/al2023/os-images/2023.9.20251105.0/kvm/al2023-kvm-2023.9.20251105.0-kernel-6.1-x86_64.xfs.gpt.qcow2
  - how to install by yourself guide: https://cloudspinx.com/how-to-install-amazon-linux-2023-on-kvm-using-qcow2-image/
  - kvm in container: https://github.com/qemus/qemu
