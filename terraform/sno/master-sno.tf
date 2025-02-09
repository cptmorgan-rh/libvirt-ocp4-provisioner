# variables that can be overriden
variable "hostname" { default = "master-sno" }
variable "memory" { default = 32 }
variable "cpu" { default = 4 }
variable "coreos_iso_path" { default = "" }
variable "vm_volume_size" { default = 40 }
variable "vm_net_ip" { default = "192.168.100.7" }
variable "libvirt_network" { default = "ocp" }
variable "libvirt_pool" { default = "default" }

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os_image" {
  name = "${var.hostname}-os_image"
  size = var.vm_volume_size*1073741824
  pool = var.libvirt_pool
  format = "qcow2"
}

# Create the machine
resource "libvirt_domain" "master" {
  name = "${var.hostname}"
  memory = var.memory*1024
  vcpu = var.cpu

  cpu {
    mode = "host-passthrough"
  }

  disk {
       volume_id = libvirt_volume.os_image.id
  }

  disk {
       file = "${var.coreos_iso_path}"
  }

  network_interface {
       network_name = var.libvirt_network
       addresses = [ "${var.vm_net_ip}" ] 
  }

  boot_device {
    dev = [ "hd", "cdrom" ]
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }

}

terraform {
 required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.11"
    }
  }
}

output "macs" {
  value = "${flatten(libvirt_domain.master.*.network_interface.0.mac)}"
}
