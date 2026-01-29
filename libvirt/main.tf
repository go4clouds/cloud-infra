terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

resource "libvirt_volume" "cloud_image" {
  name   = var.image_name
  source = var.image_path
}

resource "libvirt_network" "cloud_network" {
  name   = var.network_name
  mode   = var.network_mode
  domain = var.dns_domain

  dns {
    enabled = true
  }

  addresses = [var.network_cidr]
}
