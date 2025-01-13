variable "image_date" { type = string }
variable "gcp_project" { type = string }
variable "image_name" { type = string }

packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

locals {
  image_identity = "${var.image_name}-${var.image_date}"

  freebsd_gcp_images = [
    {
      task_name = "freebsd-13"
      zone = "us-west1-a"
    },
  ]
}

source "googlecompute" "freebsd-vanilla" {
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  project_id              = var.gcp_project
  image_name              = "${local.image_identity}"
  instance_name           = "build-${local.image_identity}"
  source_image_family     = "freebsd-13-3"
  source_image_project_id = ["freebsd-org-cloud-dev"]
  machine_type            = "t2d-standard-2"
  ssh_pty                 = "true"
  ssh_username            = "packer"
}


build {
  name="freebsd"

  # See linux case for explanation, mostly copied for symmetry
  dynamic "source" {
    for_each = local.freebsd_gcp_images
    labels = ["source.googlecompute.freebsd-vanilla"]
    iterator = tag

    content {
      # can't reference local. / var. here - we could just fix that by including
      # it in the name above, but it seems nicer to have shorter task names anyway
      name = tag.value.task_name

      zone = tag.value.zone
    }
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        cat /boot/loader.conf || true
        PAGER=cat freebsd-update fetch install
        pkg remove -y google-cloud-sdk firstboot-freebsd-update firstboot-pkgs
        pkg update
        pkg upgrade -y

        pkg install -y -g 'py*-google-compute-engine'

        # remove superfluous packages
        pkg autoremove -y

        pkg install -y -g \
          bash \
          git-tiny \
          gmake \
          meson \
          ninja \
          perl5 \
          pkgconf \
          \
          bison \
          ccache4 \
          flex \
          gettext \
          \
          p5-IPC-Run \
          \
          liblz4 \
          libbacktrace \
          libxml2 \
          libxslt \
          python3 \
          'py*-pip' \
          readline \
          tcl86 \
          zstd \
          \
          krb5 \
          openldap25-client \
          openldap25-server

        # === begin temporary workaround for broken p5-IO-Tty 1.20 ===
        # https://github.com/cpan-authors/IO-Tty/issues/38
        # https://www.postgresql.org/message-id/flat/757523.1705091568%40sss.pgh.pa.us
        if pkg info p5-IO-Tty | grep -E '^Version *: *1.20$' ; then
          GOOD_PKG="p5-IO-Tty-1.17.pkg"
          pkg remove -y p5-IO-Tty
          curl -O "https://pkg.freebsd.org/freebsd:13:x86:64/release_2/All/$GOOD_PKG"
          pkg install -y $GOOD_PKG
          rm $GOOD_PKG
          pkg install -y p5-IPC-Run
        fi
        # === end temporary workaround for broken p5-IO-Tty ===

        # remove temporary files
        pkg clean -ay
        rm -fr /usr/ports /usr/src /usr/tests /usr/lib/debug
        rm -fr /var/db/freebsd-update /var/db/pkg/repo-*
        find / -name '*.pkgsave' -type f|xargs rm -v

        # remove parts of required packages that we don't need and that are reasonably large
        rm -rf /usr/share/doc/ /usr/local/share/doc/ /usr/local/include/boost/
        rm /usr/local/lib/*boost*.a /usr/local/lib/python*/config-*/*.a /usr/local/lib/libsource-highlight.a

        cat /etc/rc.conf

        # the firstboot stuff delays boot and sometimes fails - we rebuild images anyway
        sed -i -e 's/firstboot_pkgs_enable=YES/firstboot_pkgs_enable=NO/' /etc/rc.conf
        sed -i -e 's/firstboot_freebsd_update_enable=YES/firstboot_freebsd_update_enable=NO/' /etc/rc.conf

        # try to make debugging easier
        echo rc_debug=YES | tee -a /etc/rc.conf
        echo rc_startmsgs=YES | tee -a /etc/rc.conf
        cat /etc/rc.conf
        cat /boot/loader.conf || true

        # this seems to just be in the wrong place
        sed -i -e 's/kern.timecounter.hardware=ACPI-safe//' /boot/loader.conf

        # XXX: Try to ensure the new instance doesn't use old network etc configuration
        cat /usr/local/etc/instance_configs.cfg || true
        rm -f /usr/local/etc/instance_configs.cfg /var/run/resolvconf/interfaces/vtnet0 \
          /var/db/dhclient.leases.vtnet0 /etc/hostid /etc/ssh/*key*
        cat /etc/hosts
        sed -i -e '/[gG]oogle/d' /etc/hosts
        cat /etc/hosts
        echo sendmail_enable=NO |tee -a /etc/rc.conf
        echo sendmail_submit_enable=NO |tee -a /etc/rc.conf
        cat /etc/rc.conf

        # disable growfs, so we can create space for new partitions
        sed -i -e 's/growfs_enable=YES/growfs_enable=NO/' /etc/rc.conf

        # the loader.conf parts from: https://lists.freebsd.org/pipermail/freebsd-cloud/2017-January/000080.html
        echo 'kern.timecounter.invariant_tsc=1' | tee -a /boot/loader.conf
        echo 'kern.timecounter.smp_tsc=1' | tee -a /boot/loader.conf
        echo 'kern.timecounter.smp_tsc_adjust=1' | tee -a /boot/loader.conf

        # Freebsd 13.2 causes problems with tcl if the timezone is not explicitly configured
        # https://postgr.es/m/20230731191510.pebqeiuo2sbmlcfh%40awork3.anarazel.de
        tzsetup UTC
      SCRIPT
    ]
  }

  # set IMAGE_IDENTITY to distinguish images on CI runs
  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      "mkdir -p /etc/environment.d",
      "echo \"IMAGE_IDENTITY=${local.image_identity}\" | tee /etc/environment.d/image_identity.conf",
    ]
  }

  provisioner "shell" {
    expect_disconnect = true
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        mount -u -f -r /
        # starting in freebsd 13.1 -E alone would ask a lot of questions
        fsck_ffs -p -E /
        mount -u -f -w /
        shutdown -h now
      SCRIPT
    ]
  }
}
