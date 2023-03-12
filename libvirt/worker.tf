resource "libvirt_volume" "worker" {
  name           = "worker-volume${count.index + 1}"
  base_volume_id = libvirt_volume.cloud_image.id
  size           = var.worker_disk_size
  count          = var.workers
}

data "template_file" "worker_repositories" {
  template = file("cloud-init/repository.tpl")
  count    = length(var.repositories)

  vars = {
    repository_url = element(values(var.repositories), count.index)
    repository_name = element(keys(var.repositories), count.index)
  }
}

data "template_file" "worker_commands" {
  template = file("cloud-init/commands.tpl")
  count    = length(var.packages)

  vars = {
    packages = join(", ", var.packages)
  }
}

data "template_file" "worker_cloud_init" {
  template = file("cloud-init/common.tpl")
  count    = var.workers

  vars = {
    hostname        = "worker${count.index + 1}"
    locale          = var.locale
    timezone        = var.timezone
    authorized_keys = join("\n", formatlist("      - %s", var.authorized_keys))
    packages        = join("\n", formatlist("  - %s", var.packages))
    repositories    = join("\n", data.template_file.worker_repositories.*.rendered)
    commands        = join("\n", data.template_file.worker_commands.*.rendered)
  }
}

resource "libvirt_cloudinit_disk" "worker" {
  count     = var.workers
  name      = "worker-cloudinit-disk-${count.index + 1}"
  pool      = var.pool
  user_data = data.template_file.worker_cloud_init[count.index].rendered
}

resource "libvirt_domain" "worker" {
  count      = var.workers
  name       = "worker${count.index+1}"
  memory     = var.worker_memory
  vcpu       = var.worker_vcpu
  cloudinit  = element(libvirt_cloudinit_disk.worker.*.id, count.index)

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.worker.*.id, count.index)
  }

  network_interface {
    network_name   = var.network_name
    hostname       = "worker${count.index + 1}"
    wait_for_lease = true
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

resource "null_resource" "worker_wait_cloudinit" {
  depends_on = [libvirt_domain.worker]
  count      = var.workers

  connection {
    host = element(
      libvirt_domain.worker.*.network_interface.0.addresses.0,
      count.index
    )
    user = var.username
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait > /dev/null",
    ]
  }
}

resource "null_resource" "worker_provision" {
  depends_on = [null_resource.worker_wait_cloudinit]
  count      = var.workers

  connection {
    host = element(
      libvirt_domain.worker.*.network_interface.0.addresses.0,
      count.index
    )
    user = var.username
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    script = "provision-os-node.sh"
  }
}

data "template_file" "worker_containerd_conf" {
  template = file("configs/config.toml.tpl")

  vars = {
    registry_mirror = var.registry_mirror
  }
}

resource "null_resource" "worker_provision_k8s_containerd" {
  depends_on = [null_resource.worker_provision]
  count      = var.kubernetes_enable ? var.workers : 0

  connection {
    host = element(
      libvirt_domain.worker.*.network_interface.0.addresses.0,
      count.index
    )
    user = var.username
    type = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    content     = data.template_file.worker_containerd_conf.rendered
    destination = "/tmp/config.toml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /etc/containerd",
      "sudo mv /tmp/config.toml /etc/containerd",
      "sudo chown root:root /etc/containerd/config.toml",
    ]
  }

  provisioner "file" {
    source      = "provision-k8s-node.sh"
    destination = "/tmp/provision-k8s-node.sh"
  }

  provisioner "remote-exec" {
  inline = [
    "chmod +x /tmp/provision-k8s-node.sh",
    "/tmp/provision-k8s-node.sh ${var.containerd_version} ${var.kubernetes_version} ${libvirt_domain.control_plane.0.network_interface.0.addresses.0}",
    ]
  }
}

resource "null_resource" "worker_reboot" {
  depends_on = [null_resource.worker_provision_k8s_containerd]
  count      = var.kubernetes_enable ? var.workers : 0

  provisioner "local-exec" {
    environment = {
      user = var.username
      host = element(
        libvirt_domain.worker.*.network_interface.0.addresses.0,
        count.index
      )
    }

    command = <<EOT
export sshopts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -oConnectionAttempts=60"
if ssh $sshopts $user@$host '[ -f /var/run/reboot-required ]'; then
    ssh $sshopts $user@$host sudo reboot || :
    export delay=5
    # wait for node reboot completed
    while ! ssh $sshopts $user@$host '[ -f /var/run/reboot-required ]'; do
        sleep $delay
        delay=$((delay+1))
        [ $delay -gt 60 ] && exit 1
        ssh $sshopts $user@$host '[ -f /var/run/reboot-required ]'
    done
fi
EOT
  }
}
