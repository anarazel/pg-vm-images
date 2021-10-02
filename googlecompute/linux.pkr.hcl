variable "image_date" { type = string }

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-aio"

  debian_gcp_images = [
    {
      name = "bullseye"
      zone = "us-west1-a"
      machine = "e2-highcpu-4"
    },
    {
      name = "sid"
      zone = "us-west1-a"
      machine = "e2-highcpu-4"
    },
    {
      name = "sid-newkernel"
      zone = "us-west2-a"
      machine = "c2-standard-8"
    },
    {
      name = "sid-newkernel-uring"
      zone = "us-west2-a"
      machine = "c2-standard-8"
    },
  ]
}

source "googlecompute" "bullseye-vanilla" {
  project_id              = "pg-vm-images-aio"
  source_image_family     = "debian-11"
  source_image_project_id = ["debian-cloud"]
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  ssh_pty                 = "true"
  ssh_username            = "packer"
}

build {
  name="linux"

  # Generate debian gcp images. Unfortunately variable expansion inside source
  # and build blocks doesn't work well yet on packer 1.7.7. Hence this.

  dynamic "source" {
    for_each = local.debian_gcp_images
    labels = ["source.googlecompute.bullseye-vanilla"]
    iterator = tag

    content {
      # can't reference local. / var. here?!?
      name = tag.value.name
      image_name = "${local.name}-${tag.value.name}-${var.image_date}"
      image_family = "${local.name}-${tag.value.name}"

      zone = tag.value.zone
      machine_type = tag.value.machine
      instance_name = "build-${local.name}-${tag.value.name}"
    }
  }

  provisioner "shell-local" {
    inline = [
      "echo ${source.name} and ${source.type}",
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        rm -f /etc/apt/sources.list.d/google-cloud.list /etc/apt/sources.list.d/gce_sdk.list
        DEBIAN_FRONTEND=noninteractive apt-get purge man-db google-cloud-sdk \
          unattended-upgrades gnupg shim-unsigned publicsuffix mokutil -y
        DEBIAN_FRONTEND=noninteractive apt-get install -y grub-efi-amd64-bin grub2-common
        DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        echo 'deb http://deb.debian.org/debian unstable main' > /etc/apt/sources.list
        echo 'deb-src http://deb.debian.org/debian unstable main' >> /etc/apt/sources.list
        apt-get update -y
        SCRIPT
    ]
    only = ["sid", "sid-newkernel", "sid-newkernel-uring"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        echo 'deb http://deb.debian.org/debian bullseye main' > /etc/apt/sources.list
        echo 'deb-src http://deb.debian.org/debian bullseye main' >> /etc/apt/sources.list
        apt-get update -y
      SCRIPT
    ]
    only = ["bullseye"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends -y
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
    inline = [
      <<-SCRIPT
        echo will reboot
        shutdown -r now
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    pause_before = "10s"
    inline = [
      <<-SCRIPT
        DEBIAN_FRONTEND=noninteractive apt-get purge $(dpkg -l|grep linux-image|grep 4.19 |awk '{print $2}') -y
        sed -i 's/MODULES=most/MODULES=dep/' /etc/initramfs-tools/initramfs.conf
        update-initramfs -u -k all

        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
          git build-essential gcc g++ libreadline-dev flex bison make perl libipc-run-perl \
          libio-pty-perl clang llvm-dev libperl-dev libpython3-dev tcl-dev libldap2-dev \
          libicu-dev docbook-xml docbook-xsl fop libxml2-utils xsltproc krb5-admin-server \
          krb5-kdc krb5-user slapd ldap-utils libssl-dev pkg-config locales-all liburing-dev \
          python3-distutils ccache gdb meson
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        git clone --single-branch --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git /usr/src/linux
      SCRIPT
    ]
    only = ["sid-newkernel"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        head=$(git ls-remote --exit-code --heads --sort=-version:refname \
          git://git.kernel.dk/linux-block 'refs/heads/for-*/io_uring' | \
                head -n 1|cut -f 2|sed -e 's/^refs\\/heads\\///')
        origin=$(echo $head|sed -e 's/\\//-/')
        git clone -o $origin --single-branch --depth 1 \
          git://git.kernel.dk/linux-block -b $head /usr/src/linux
      SCRIPT
    ]
    only = ["sid-newkernel-uring"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
	  time libelf-dev bc htop libdw-dev libdwarf-dev libunwind-dev libslang2-dev libzstd-dev \
	  binutils-dev  libnuma-dev libcap-dev libiberty-dev libbabeltrace-dev systemtap-sdt-dev

        cd /usr/src/linux
        echo linux git revision from $(git remote) is: $(git rev-list HEAD)
        make x86_64_defconfig
        make kvm_guest.config
        ./scripts/config -e CONFIG_KVM_CLOCK
        ./scripts/config -e CONFIG_LOCALVERSION_AUTO
        ./scripts/config --set-str CONFIG_LOCALVERSION -$(git remote)
        # cirrus queries memory usage that way
        ./scripts/config -e MEMCG
        # for good measure
        ./scripts/config -e CGROUP_PID -e BLK_CGROUP
        make mod2yesconfig
        time make -j16 -s all
        make -j16 -s modules_install
        make -j16 -s install
        cd tools/perf
        make install prefix=/usr/local/

        # build liburing
        DEBIAN_FRONTEND=noninteractive apt-get purge -y -q liburing1
        cd /usr/src/
        git clone --single-branch --depth 1 https://github.com/axboe/liburing.git
        cd liburing/
        echo liburing git revision is: $(git rev-list HEAD)
        ./configure --prefix=/usr/local/
        make -j8 -s install
        ldconfig
        SCRIPT
    ]
    only = ["sid-newkernel", "sid-newkernel-uring"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
      DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
      apt-get clean
      rm -f /var/lib/apt/lists/deb.debian.org_*
      fstrim -v -a
      SCRIPT
    ]
  }
}
