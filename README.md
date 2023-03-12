<p align="center">
  <img src="https://avatars.githubusercontent.com/u/100899821?s=200&v=4"
  width="80" height="80" />
</p>

# <p align="center"> Cloud-infra</p>
## _**Cloud-infra** is open source software for setting up Kubernetes cluster for developers._

[comment]: # (Short text that can be added in future)

<div align="center"> <img src="https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white">

<img src="https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white">
 </div>

## Table of Contents

* [Features](#features)
* [Installation](#installation)
* [Technologies Used](#technologies-used)
* [Requirements](#requirements)
* [Plugins](#plugins)
* [License](#license)

## Features

- Install Kubernetes cluster for learning, testing and developing applications. 

## Installation

### Quickstart

On Linux server execute script:

```shell
cd cloud-infra
./configure.sh
```

It will automatically configure your server for `cloud-infra` project. Otherwise look below what manual changes should be done on your server.

### Manual installation
1. First of all chceck is there any new packages that have just come to the repositories and fetch new versions of packages existing on the machine:
    ```sh
    sudo apt update && apt upgrade --yes
    ```
2. Install required packages:
    ```sh
    sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager git-core libguestfs-tools jq
    ```
3. Add your user to the `libvirt` and `kvm` group:
    ```sh
    sudo usermod -a -G kvm $(whoami)
    sudo usermod -a -G libvirt $(whoami)
    ```
    3.a. Now you can check user permissions by command:
    ```sh
    id
    ```
   >_Remember: If user has `0` it means that user is `root`, numbers `1000+` means that's normal user_

4. Only on ubuntu: Change parameter `security_driver` in `/etc/libvirt/qemu.conf` from `security_driver = "selinux"` to `security_driver = "none"`:
    ```sh
    sudo sed -i -e 's/#security_driver = "selinux"/security_driver = "none"/g' /etc/libvirt/qemu.conf
    ```
5. Start libvirtd and check status:
    ```sh
    sudo systemctl start libvirtd
    sudo systemctl status libvirtd
    ```

6. Download your favorite Linux cloud image e.g. [Ubuntu Cloud Image][UbCi] to `/var/lib/libvirt/images` directory:
    ```sh
    sudo  curl -L https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img --output /var/lib/libvirt/images/focal-server-cloudimg-amd64.img
    ```
    
7.  Install Terraform project on you environment:
    ```sh
    sudo -i
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    apt install terraform
    ```
8.  Clone cloud-infra to your pc:
     ```sh
    git clone https://github.com/go4clouds/cloud-infra
    ```
9.  Copy settings file for Terraform:
     ```sh
    cd ~/git/cloud-infra/libvirt
    cp terraform.tfvars.examples terraform.tfvars
    ```  
10. Copy your `ssh-key` to `terraform.tfvars`:  
    Show your key and copy it
    ```sh
    cat ~/.ssh/id_rsa.pub
    ```
    >If you don't have ssh keys, you can create them using command:
    >```sh
    >ssh-keygen
    >```
    Open `terraform.tfvars` placed in `~/git/cloud-infra/libvirt/`

    ```sh
    vim ~/git/cloud-infra/libvirt/terraform.tfvars
    ```
    and paste your key as shown:

    ```sh
    authorized_keys = [
    "<YOUR_KEY>"
    ]
    ```

11. Start Terraform:
    ```sh
    terraform init
    terraform plan
    terraform apply --auto-approve
    ```
12. After all, you can clean up using:
    ```sh
    terraform destroy --auto-approve
    ```
    
## Technologies used

Cloud-infra uses a number of open source projects to work properly:

- [Terraform][TF] - codifies cloud APIs into declarative configuration files
- [Kernel Virtual Machine][KVM] - is a full virtualization solution for Linux on x86 hardware containing virtualization extensions
- [Libvirt][LV] - is a toolkit to manage virtualization platforms
- [Bridge Utils][BU]- a utility needed to create, manage and setting up networks for a hosted virtual machine
- [Virtual Machine Manager][VMM]-  is a desktop user interface for managing virtual machines through libvirt
- [Git][GIT]- version control system
- [Virtual Machine Manager][LGFS]-  tools for accessing and modifying virtual machine disk images

And of course Cloud-infra is open source with a [repository][repo] on GitHub.

## Requirements

Hardware for properly working Cloud-infra  
Physical server or PC with:

|  | Recommended |
| ------ | ------ |
| CPU | 8x core|
| RAM | 24 GB |
| Disk Space |  256 GB |
| OS | Linux OS |

## Plugins

Plugins for Cloud-infra  

|Plugin  | Readme |
| ------ | ------ |
| dmacvicar | [Readme][dma]|
| hashicorp/null | [Readme][null] |
| hashicorp/template |  [Readme][tmpl] |

## License

**[Apache-2.0 License][License]**

[//]: # (These are reference links used in the body)

   [UbCi]: <https://cloud-images.ubuntu.com/>
   [TF]: <https://www.terraform.io>
   [KVM]: <https://phoenixnap.com/kb/ubuntu-install-kvm>
   [repo]: <https://github.com/go4clouds/cloud-infra>
   [LV]: <https://libvirt.org>
   [BU]: <https://www.linuxfromscratch.org/blfs/view/cvs/basicnet/bridge-utils.html>
   [VMM]: <https://virt-manager.org>
   [GIT]: <https://git-scm.com/about>
   [LGFS]: <https://libguestfs.org>
   [License]: <https://github.com/go4clouds/cloud-infra/blob/main/LICENSE>

   [dma]: <https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs>
   [null]: <https://registry.terraform.io/providers/hashicorp/null/latest/docs>
   [tmpl]: <https://registry.terraform.io/providers/hashicorp/template/latest/docs>
