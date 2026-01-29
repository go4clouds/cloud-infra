#!/bin/bash

if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

# Check for os distro
OS_ID="$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release)"

# Chceck is there any new packages
if [ $OS_ID = "fedora" ] ; then
    dnf update --assumeyes && dnf upgrade --assumeyes
else
    apt update && apt upgrade --yes
fi
echo "Upgrade complete"

# Install required packages
if [ $OS_ID = "fedora" ] ; then
    dnf install --assumeyes qemu-kvm bridge-utils virt-manager git-core libguestfs-tools jq dnsmasq libvirt virt-install @virtualization
else
    apt install --yes qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager git-core libguestfs-tools jq software-properties-common dnsmasq genisoimage
fi
echo "Install complete"

# Add your user to the libvirt and kvm group
usermod -a -G kvm $(whoami)
usermod -a -G libvirt $(whoami)
echo "Added your user to the libvirt and kvm group"

# Check user permissions

# Set security_driver = "none"
LIBVIRT_SEC_DRIVER="$(grep "security_driver = \"none\"" /etc/libvirt/qemu.conf)"
LIBVIRT_SEC_DRIVER=${LIBVIRT_SEC_DRIVER// /}
if [[ "$LIBVIRT_SEC_DRIVER" != 'security_driver="none"' ]] ; then
    sed -i -e 's/#security_driver = "selinux"/security_driver = "none"/g' /etc/libvirt/qemu.conf
    echo "security_driver set to none"
else
    echo "security_driver is already set to none"
fi

rsync -av files/default.xml /etc/libvirt/storage/
STORAGE_AUTO="/etc/libvirt/storage/autostart/default.xml"
if [ ! -L $STORAGE_AUTO ]; then
  mkdir -p /etc/libvirt/storage/autostart
  ln -s /etc/libvirt/storage/default.xml /etc/libvirt/storage/autostart/default.xml
fi

virsh pool-create --build /etc/libvirt/storage/default.xml

# Start libvirtd
systemctl start libvirtd
if [[ $(pidof libvirtd) ]]; then
        echo "Libvirt is running"
else
        echo "Libvirt error"
        exit 1
fi

# Add right socket to libvirtd.conf (Fedora only)
if [ $OS_ID = "fedora" ] ; then
    LIB_CONF_FILE="/etc/libvirt/libvirtd.conf"
    if ! grep -q 'listen_socket = "/var/run/libvirt/libvirt-sock"' "$LIB_CONF_FILE" ; then
        echo 'listen_socket = "/var/run/libvirt/libvirt-sock"' >> $LIB_CONF_FILE
    fi
fi

# Download Linux cloud image
IMG_PATH="/var/lib/libvirt/images"
IMG_NAME="focal-server-cloudimg-amd64.img"
if [ ! -d "$IMG_PATH" ]; then
	mkdir -p "$IMG_PATH"
	echo "Folder has been created: $IMG_PATH"
	echo "Downloading..."
fi

if [ ! -f "${IMG_PATH}/${IMG_NAME}" ]; then
  wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img -O "${IMG_PATH}/${IMG_NAME}"
fi

# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
if [ $OS_ID = "fedora" ] ; then
    wget -O- https://rpm.releases.hashicorp.com/fedora/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
    dnf install terraform
else
    apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    apt install terraform
fi
if command -v terraform &> /dev/null; then
    echo "Terraform installation complete"
else
    echo "Terraform installation error"
    exit 1 
fi

# Clone cloud-infra
# git clone https://github.com/go4clouds/cloud-infra

# Copy settings file for Terraform
TF_SET_FILE="./libvirt/terraform.tfvars"
if [ -f $TF_SET_FILE ]; then
    echo "Terraform settings file already exist"
else
    cp ./libvirt/terraform.tfvars.demo $TF_SET_FILE
    if [ -f $TF_SET_FILE ]; then
        echo "Terraform settings file copied"
    else 
        echo "Terraform settings file copy error"
        exit 1
    fi
fi

# Copy your ssh-key
if [ -f "/root/.ssh/id_rsa.pub" ]; then
    SSH_PUB_KEY="$(cat ~/.ssh/id_rsa.pub)"
    sed -i -e 's|authorized_keys\s=\s\[\".*\"\]\s\#ssh_ends|authorized_keys = [\"'"${SSH_PUB_KEY}"'\"] \#ssh_ends|g' $TF_SET_FILE
      echo "Adding your actual ssh key to terraform.tfvars settings file"
else
    echo "No public ssh key to copy, you can generate it by 'ssh-keygen' "
fi

echo
echo "Installation is complete!!!"
echo "Go to ~/cloud-infra/libvirt and start terraform"
echo "terraform init"
echo "terraform plan"
echo "terraform apply"

exit 0
