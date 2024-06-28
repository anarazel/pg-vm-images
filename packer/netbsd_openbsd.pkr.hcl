variable "boot_command" { type = list(string) }
variable "bucket" { type = string }
variable "gcp_project" { type = string }
variable "image_date" { type = string }
variable "image_name" { type = string }
variable "iso_checksum" { type = string }
variable "iso_urls" { type = list(string) }
variable "name" { type = string }
variable "output_file_name" { type = string }
variable "postgres_name" { type = list(map(string)) }
variable "vanilla_name" { type = list(map(string)) }
variable "prefix" {type = string }

locals {
  image_identity = "${var.image_name}-${var.image_date}"
}

source "qemu" "qemu-gce-builder" {
  boot_command            = "${var.boot_command}"
  boot_wait               = "120s"
  cpus                    = 2
  disk_size               = 25600
  memory                  = 1024
  headless                = true
  iso_checksum            = "${var.iso_checksum}"
  iso_urls                = "${var.iso_urls}"
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
  name = "vanilla"

  # for using -only '*.${CIRRUS_TASK_NAME}' while building images,
  # so we can easily combine the packer invocations later
  dynamic "source" {
    for_each = var.vanilla_name
    labels = ["source.qemu.qemu-gce-builder"]
    iterator = tag

    content {
      name = tag.value.name
    }
  }

  provisioner "shell" {
    script = "scripts/bsd/netbsd-prep-gce.sh"
    only = ["qemu.netbsd-vanilla"]
  }
  provisioner "shell" {
    script = "scripts/bsd/openbsd-prep-gce.sh"
    only = ["qemu.openbsd-vanilla"]
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

  # set IMAGE_IDENTITY to distinguish images on CI runs
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/environment.d",
      "echo \"IMAGE_IDENTITY=${local.image_identity}\" | tee /etc/environment.d/image_identity.conf",
    ]
  }

  # reboot to verify we still boot
  provisioner "shell" {
    expect_disconnect = true
    inline = [
      <<-SCRIPT
        echo will reboot
        /sbin/shutdown -r now
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
    inline = ["/usr/sbin/usermod -C yes root"]
    only = ["qemu.netbsd-vanilla"]
  }

  # lock root, same as netbsd
  provisioner "shell" {
    inline = ["/usr/sbin/usermod -f 1 root"]
    only = ["qemu.openbsd-vanilla"]
  }

  provisioner "shell" {
    inline = ["/usr/bin/sed -i 's/PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config"]
  }

  post-processors {
    post-processor "compress" {
      output = "${var.output_file_name}"
    }

    post-processor "googlecompute-import" {
      gcs_object_name   = "packer-${local.image_identity}.tar.gz"
      bucket            = "${var.bucket}"
      image_name        = local.image_identity
      project_id        = "${var.gcp_project}"
    }
  }
}

source "googlecompute" "postgres" {
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  project_id              = "${var.gcp_project}"
  source_image_family     = "${var.prefix}-${var.name}-vanilla"
  source_image_project_id = ["${var.gcp_project}"]
  image_name              = local.image_identity
  instance_name           = "build-${local.image_identity}"
  zone                    = "us-west1-a"
  machine_type            = "t2d-standard-2"
  ssh_username            = "root"
  temporary_key_pair_type = "ed25519"
  ssh_timeout             = "300s"
}

build {
  name = "postgres"

  # for using -only '*.${CIRRUS_TASK_NAME}' while building images,
  # so we can easily combine the packer invocations later
  dynamic "source" {
    for_each = var.postgres_name
    labels = ["source.googlecompute.postgres"]
    iterator = tag

    content {
      name = tag.value.name
    }
  }

  provisioner "shell" {
    script = "scripts/bsd/netbsd-prep-postgres.sh"
    only = ["googlecompute.netbsd-postgres"]
  }
  provisioner "shell" {
    script = "scripts/bsd/openbsd-prep-postgres.sh"
    only = ["googlecompute.openbsd-postgres"]
  }

  # set IMAGE_IDENTITY to distinguish images on CI runs
  provisioner "shell" {
    inline = [
      "mkdir -p /etc/environment.d",
      "echo \"IMAGE_IDENTITY=${local.image_identity}\" | tee /etc/environment.d/image_identity.conf",
    ]
  }

  # clear users and ssh keys
  provisioner "shell" {
    script = "scripts/bsd/clear_users_and_ssh_keys.sh"
  }
}
