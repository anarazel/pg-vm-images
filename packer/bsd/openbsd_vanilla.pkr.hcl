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
    "S<enter><wait>",
    "cat <<EOF >>install.conf<enter>",
    "System hostname = openbsd71<enter>",
    "Password for root = packer<enter>",
    "Allow root ssh login = yes<enter>",
    "What timezone are you in = Etc/UTC<enter>",
    "Do you expect to run the X Window System = no<enter>",
    "Set name(s) = -man* -game* -x*<enter>",
    "Directory does not contain SHA256.sig. Continue without verification = yes<enter>",
    "EOF<enter>",
    "install -af install.conf && reboot<enter>"
    ]

  boot_wait               = "120s"
  cpus                    = 2
  disk_size               = 25600
  memory                  = 1024
  headless                = true
  iso_checksum            = "sha256:d3a7c5b9bf890bc404304a1c96f9ee72e1d9bbcf9cc849c1133bdb0d67843396"
  iso_urls                = [
    "install71.iso",
    "https://cdn.openbsd.org/pub/OpenBSD/7.1/amd64/install71.iso"
    ]
  shutdown_command        = "shutdown -p now"
  ssh_username            = "root"
  ssh_password            = "packer"
  ssh_port                = 22
  ssh_wait_timeout        = "900s"
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
  name="openbsd-vanilla"
  sources = ["source.qemu.qemu-gce-builder"]

  provisioner "shell" {
    script = "scripts/bsd/openbsd-prep-gce.sh"
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

  # reboot to verify we still boot
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      <<-SCRIPT
        echo will reboot
        shutdown -r now
      SCRIPT
    ]
  }

  # check kernel version etc to see everything went well
  provisioner "shell" {
    inline = ["uname -a"]
  }

  # lock root because we don't want that root is accessible by using
  # username-password, root is still reachable from ssh key
  provisioner "shell" {
    inline = ["/usr/sbin/usermod -f 1 root"]
  }

  provisioner "shell" {
    inline = ["sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config"]
  }

  post-processors {
    post-processor "compress" {
      output = "output/openbsd71.tar.gz"
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
