variable "bucket" { type = string }
variable "gcp_project" { type = string }
variable "image_date" { type = string }
variable "image_name" { type = string }

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-ci"
}

source "qemu" "qemu-gce-builder" {

  boot_command            = [
    # Installation messages in English
    "<enter><wait5s>",
    # Keyboard type: unchanged
    "<enter><wait5s>",
    # Install NetBSD to hard disk
    "<enter><wait5s>",
    # Continue: Yes
    "<down><enter><wait5s>",
    # Available disk: Select default
    "<enter><wait5s>",
    # Guid Partition Table (GPT)
    "<enter><wait5s>",
    # This is the correct geometry
    "<enter><wait5s>",
    # Use default partition sizes
    "<down><enter><wait5s>",
    # Partition sizes ok
    "<enter><wait5s>",
    # Continue: Yes
    "<down><enter><wait5s>",
    # Use serial port com0 and continue
    "b<enter><wait5s>x<enter><wait5s>",
    # Installation without X11
    "<down><enter><wait5s>",
    # Install from CD-ROM / DVD / install image media
    "<enter><wait300s>",
    # Continue
    "<enter><wait5s>",
    # Enable sshd
    "g<enter><wait5s>",
    # Change root password
    "d<enter><wait5s><enter><wait5s>",
    # Set root password
    "packer<enter><wait5s>",
    # Set root password again
    "packer<enter><wait5s>",
    # Set root password again
    "packer<enter><wait5s>",
    # Finished configuring
    "x<enter><wait5s>",
    # Continue
    "<enter><wait5s>",
    # Reboot the computer
    "d<enter><wait180s>",
    # Login as a root
    "root<enter><wait5s>packer<enter><wait5s>",
    # Allow root username/password login
    "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config<enter><wait5s>",
    # Enable ipv4 network(ipv6 has problems with QEMU)
    "echo '/sbin/dhcpcd -4' > /etc/rc.local<enter><wait5s>",
    "reboot<enter>"
  ]

  boot_wait               = "120s"
  cpus                    = 2
  disk_size               = 25600
  memory                  = 1024
  headless                = true
  iso_checksum            = "sha256:5f1bca14c4090122f31713dd86a926f63109dd6fb3c05f9b9b150a78acc8bc7e"
  iso_urls                = [
    "NetBSD-9.2-amd64.iso",
    "https://cdn.netbsd.org/pub/NetBSD/NetBSD-9.2/images/NetBSD-9.2-amd64.iso"
    ]
  shutdown_command        = "/sbin/shutdown -p now"
  ssh_username            = "root"
  ssh_password            = "packer"
  ssh_port                = 22
  ssh_wait_timeout        = "600s"
  format                  = "raw"
  vm_name                 = "disk.raw"
  output_directory        = "output"
  # force graphical output to recorded via qemu's curses display, which
  # qemu-wrap-curses allows to use even from packer
  qemu_binary		  = "./qemu-wrap-curses"
  qemuargs                = [
    ["-display", "curses"],
    ["-serial", "vc"],
    ["-vga", "cirrus"],
  ]
}

build {
  name="netbsd-vanilla"
  sources = ["source.qemu.qemu-gce-builder"]

  provisioner "shell" {
    script = "scripts/bsd/netbsd-prep-gce.sh"
  }

  provisioner "file" {
    source = "files/bsd/rc.local.sh"
    destination = "/etc/rc.local"
  }

  provisioner "file" {
    source = "files/bsd/rc.shutdown.sh"
    destination = "/etc/rc.shutdown"
  }

  provisioner "shell" {
    inline = ["chmod 744 /etc/rc.local && chmod 744 /etc/rc.shutdown"]
  }

  post-processors {
    post-processor "compress" {
      output = "output/netbsd92.tar.gz"
    }

    post-processor "googlecompute-import" {
      gcs_object_name   = "packer-${var.image_name}-${var.image_date}.tar.gz"
      bucket            = "${var.bucket}"
      image_family      = "${local.name}-${var.image_name}"
      image_name        = "${local.name}-${var.image_name}-${var.image_date}"
      project_id        = "${var.gcp_project}"
    }
  }
}
