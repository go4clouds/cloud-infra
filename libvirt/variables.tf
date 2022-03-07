variable "libvirt_uri" {
  description = "libvirt connection URI"
  default     = "qemu:///system"
}

variable "pool" {
  description = "Pool to be used to store all the volumes"
  default     = "default"
}

variable "image_name" {
  description = "Image name in libvirt"
  default     = "cloud-image"
}

variable "image_path" {
  description = "Path or URL to the image"
  default     = "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
}

variable "network_name" {
  description = "Network name in libvirt"
  default     = "cloud-network"
}

variable "network_mode" {
  description = "Network mode in libvirt (nat / none / route / bridge)"
  default     = "nat"
}

variable "dns_domain" {
  description = "DNS domain name"
  default     = "cloud.local"
}

variable "stack_name" {
  description = "Identifier to make all your resources unique and avoid clashes with other users of this terraform project"
  default     = ""
}

variable "network_cidr" {
  description = "Network CIDR"
  default     = "10.16.0.0/24"
}

variable "locale" {
  description = "System locales to set on all the nodes"
  default     = "en_US.UTF-8"
}

variable "timezone" {
  description = "Timezone to set on all the nodes"
  default     = "Etc/UTC"
}

variable "authorized_keys" {
  description = "SSH keys to inject into all the nodes"
  type        = list(string)
  default     = []
}

variable "repositories" {
  description = "Zypper repositories to add"
  type        = map(string)
  default     = {
    Kernel_stable_Backport = "https://download.opensuse.org/repositories/Kernel:/stable:/Backport/standard/"
  }
}

variable "packages" {
  description = "List of addditional packagess to install"
  type        = list(string)
  default     = [
    "jq",
    "socat",
    "strace",
    "tmux"
  ]
}

variable "enable_k8s_containerd" {
  description = "Enable Kubernetes with containerd CRI"
  type        = bool
  default     = true
}

variable "username" {
  description = "Default user in VMs"
  default     = "opensuse"
}

variable "control_planes" {
  description = "Number of CP VMs to create"
  default     = 1
}

variable "control_plane_memory" {
  description = "The amount of RAM (MB) for a CP node"
  default     = 2048
}

variable "control_plane_vcpu" {
  description = "The amount of virtual CPUs for a CP node"
  default     = 2
}

variable "control_plane_disk_size" {
  description = "Disk size (in bytes)"
  default     = "25769803776"
}

variable "workers" {
  description = "Number of worker VMs to create"
  default     = 1
}

variable "worker_memory" {
  description = "The amount of RAM (MB) for a worker node"
  default     = 2048
}

variable "worker_vcpu" {
  description = "The amount of virtual CPUs for a worker node"
  default     = 1
}

variable "worker_disk_size" {
  description = "Disk size (in bytes)"
  default     = "25769803776"
}