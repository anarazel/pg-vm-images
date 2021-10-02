variable "image_date" { type = string }

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-aio"

  freebsd_gcp_images = [
    {
      name = "freebsd-13-0"
      zone = "us-west1-a"
      machine = "e2-highcpu-4"
    },
  ]
}

source "googlecompute" "freebsd-13-0-vanilla" {
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  project_id              = "pg-vm-images-aio"
  source_image_family     = "freebsd-13-0"
  source_image_project_id = ["freebsd-org-cloud-dev"]
  ssh_pty                 = "true"
  ssh_username            = "pg-vm-images-aio"
}


build {
  name="freebsd"

  # See linux case for explanation, mostly copied for symmetry
  dynamic "source" {
    for_each = local.freebsd_gcp_images
    labels = ["source.googlecompute.freebsd-13-0-vanilla"]
    iterator = tag

    content {
      # can't reference local. / var. here - we could just fix that by including
      # it in the name above, but it seems nicer to have shorter task names anyway
      name = tag.value.name
      image_name = "${local.name}-${tag.value.name}-${var.image_date}"
      image_family = "${local.name}-${tag.value.name}"

      zone = tag.value.zone
      machine_type = tag.value.machine
      instance_name = "build-${local.name}-${tag.value.name}"
    }
  }

  provisioner "shell" {
    inline = [
      <<-SCRIPT
        sudo cat /boot/loader.conf || true
        sudo freebsd-update fetch install
        sudo pkg remove -y google-cloud-sdk firstboot-freebsd-update firstboot-pkgs
        sudo pkg update
        sudo pkg upgrade -y
        sudo pkg install -y readline flex bison gmake perl5 p5-IPC-Run ccache git-tiny bash meson ninja python3 pkgconf
        sudo pkg clean -y
        sudo rm -fr /usr/ports /usr/src /usr/lib/debug
        sudo cat /etc/rc.conf
        # the firstboot stuff delays boot and sometimes fails - we rebuild images anyway
        sudo sed -i -e 's/firstboot_pkgs_enable=YES/firstboot_pkgs_enable=NO/' /etc/rc.conf
        sudo sed -i -e 's/firstboot_freebsd_update_enable=YES/firstboot_freebsd_update_enable=NO/' /etc/rc.conf
        # try to make debugging easier
        echo rc_debug=YES | sudo tee -a /etc/rc.conf
        echo rc_startmsgs=YES | sudo tee -a /etc/rc.conf
        sudo cat /etc/rc.conf
        sudo cat /boot/loader.conf || true
        # this seems to just be in the wrong place
        sudo sed -i -e 's/kern.timecounter.hardware=ACPI-safe//' /boot/loader.conf
        # XXX: Try to ensure the new instance doesn't use old network etc configuration
        cat /usr/local/etc/instance_configs.cfg || true
        sudo rm -f /usr/local/etc/instance_configs.cfg /var/run/resolvconf/interfaces/vtnet0 \
	  /var/db/dhclient.leases.vtnet0 /etc/hostid /etc/ssh/*key*
        cat /etc/hosts
        sudo sed -i -e '/[gG]oogle/d' /etc/hosts
        cat /etc/hosts
        echo sendmail_enable=NO |sudo tee -a /etc/rc.conf
        echo sendmail_submit_enable=NO |sudo tee -a /etc/rc.conf
        sudo cat /etc/rc.conf
        # disable growfs, so we can create space for new partitions
        sudo sed -i -e 's/growfs_enable=YES/growfs_enable=NO/' /etc/rc.conf
        # the loader.conf parts from: https://lists.freebsd.org/pipermail/freebsd-cloud/2017-January/000080.html
        echo 'kern.timecounter.invariant_tsc=1' | sudo tee -a /boot/loader.conf
        echo 'kern.timecounter.smp_tsc=1' | sudo tee -a /boot/loader.conf
        echo 'kern.timecounter.smp_tsc_adjust=1' | sudo tee -a /boot/loader.conf
      SCRIPT
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    inline = [
      <<-SCRIPT
        sudo mount -u -f -r /
        sudo fsck_ffs -E /
        sudo mount -u -f -w /
        sudo shutdown -h now
      SCRIPT
    ]
  }
}