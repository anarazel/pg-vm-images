variable "image_date" { type = string }
variable "gcp_project" { type = string }
variable "image_name" { type = string }

locals {
  image_identity = "${var.image_name}-${var.image_date}"

  debian_gcp_images = [
    {
      task_name = "bullseye"
      zone = "us-west1-a"
      machine = "c2-standard-4"
    },
    {
      task_name = "sid"
      zone = "us-west1-a"
      machine = "c2-standard-4"
    },
    {
      task_name = "sid-newkernel"
      zone = "us-west2-a"
      machine = "c2-standard-8"
    },
    {
      task_name = "sid-newkernel-uring"
      zone = "us-west2-a"
      machine = "c2-standard-8"
    },
  ]
}

source "googlecompute" "bullseye-vanilla" {
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  project_id              = var.gcp_project
  image_name              = "${local.image_identity}"
  instance_name           = "build-${local.image_identity}"
  source_image_family     = "debian-11"
  source_image_project_id = ["debian-cloud"]
  ssh_pty                 = "true"
  ssh_username            = "packer"
  # Debian sid doesn't accept the packer default of rsa anymore.
  temporary_key_pair_type = "ed25519"
}

build {
  name="linux"

  # Generate debian gcp images. Unfortunately variable expansion inside source
  # and build blocks doesn't yet work well on packer 1.7.7. Hence this.

  dynamic "source" {
    for_each = local.debian_gcp_images
    labels = ["source.googlecompute.bullseye-vanilla"]
    iterator = tag

    content {
      # can't reference local. / var. here?!?
      name = tag.value.task_name

      zone = tag.value.zone
      machine_type = tag.value.machine
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
        export DEBIAN_FRONTEND=noninteractive
        rm -f /etc/apt/sources.list.d/google-cloud.list /etc/apt/sources.list.d/gce_sdk.list
        apt-get update

        # remove, instead of purge, grub-cloud-amd64, we want to keep its version of
        # /etc/default/grub
        apt-get remove -y grub-cloud-amd64

        # mark as installed, to prevent them from getting auto-removed
        DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y grub-efi-amd64-bin grub2-common

        # Remove unnecessary packages, to reduce image size
        apt-get purge -y \
          man-db unattended-upgrades gnupg shim-unsigned publicsuffix mokutil grub-efi-amd64-signed \
          \
          grub-efi-amd64-bin+ grub2-common+
        # For unknown reasons occasionally the source image doesn't contain google-cloud-sdk, making the uninstallation fail
        apt-get purge -y google-cloud-sdk || true
        apt-get autoremove -y

        cat /etc/default/grub
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        tee /etc/apt/sources.list <<-EOF
          deb http://deb.debian.org/debian bullseye main
          deb-src http://deb.debian.org/debian bullseye main
          deb http://security.debian.org/debian-security bullseye-security main
          deb-src http://security.debian.org/debian-security bullseye-security main
          deb http://deb.debian.org/debian bullseye-updates main
          deb-src http://deb.debian.org/debian bullseye-updates main
        EOF

        apt-get update -y
      SCRIPT
    ]
    only = ["googlecompute.bullseye"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        tee /etc/apt/sources.list <<-EOF
            deb http://deb.debian.org/debian unstable main
            deb-src http://deb.debian.org/debian unstable main
        EOF

        apt-get update -y
      SCRIPT
    ]
    only = ["googlecompute.sid", "googlecompute.sid-newkernel", "googlecompute.sid-newkernel-uring"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends -y

        # prevent some to-be-installed services from automatically starting
        mkdir -p /etc/systemd/system/
        ln -sf /dev/null /etc/systemd/system/slapd.service
        ln -sf /dev/null /etc/systemd/system/krb5-kdc.service
        ln -sf /dev/null /etc/systemd/system/krb5-admin.service
        # nvmf-autoconnect doesn't work on our own kernel, and isn't needed
        ln -sf /dev/null /etc/systemd/system/nvmf-autoconnect.service
      SCRIPT
    ]
  }

  # reboot so old kernel etc can be removed
  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
    inline = [
      <<-SCRIPT
        echo will reboot
        shutdown -r now
        sleep 360 # so that the shutdown shows effect before next command
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    pause_before = "20s"
    inline = [
      <<-SCRIPT
        export DEBIAN_FRONTEND=noninteractive

        apt-get purge $(dpkg -l|awk '{print $2}'|grep -E 'linux-image-[0-9]' |grep -v `uname -r`) -y

        # compress modules with zstd, that saves more that it costs
        apt-get install -y zstd
        sed -i 's/COMPRESS=gzip/COMPRESS=zstd/' /etc/initramfs-tools/initramfs.conf

        # don't include stuff we don't need in initramfs
        sed -i 's/MODULES=most/MODULES=dep/' /etc/initramfs-tools/initramfs.conf
        update-initramfs -u -k all
      SCRIPT
    ]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    script = "scripts/linux_debian_install_deps.sh"
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        git clone --single-branch --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git /usr/src/linux
      SCRIPT
    ]
    only = ["googlecompute.sid-newkernel"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        head=$(git ls-remote --exit-code --heads --sort=-version:refname \
          https://git.kernel.dk/linux-block 'refs/heads/for-*/io_uring' | \
                head -n 1|cut -f 2|sed -e 's/^refs\/heads\///')
        origin=$(echo $head|sed -e 's/\//-/')
        git clone -o $origin --single-branch --depth 1 \
          https://git.kernel.dk/linux-block -b $head /usr/src/linux
      SCRIPT
    ]
    only = ["googlecompute.sid-newkernel-uring"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        DEBIAN_FRONTEND=noninteractive apt-get install -y \
          time libelf-dev bc htop libdw-dev libdwarf-dev libunwind-dev libslang2-dev libzstd-dev \
          binutils-dev  libnuma-dev libcap-dev libiberty-dev libbabeltrace-dev systemtap-sdt-dev \
	  libpfm4-dev libtraceevent-dev python3-dev

        cd /usr/src/linux
        echo linux git revision from $(git remote) is: $(git rev-list HEAD)
        make x86_64_defconfig
        make kvm_guest.config
        ./scripts/config -e LOCALVERSION_AUTO
        ./scripts/config --set-str LOCALVERSION -$(git remote)

        # disable drivers we don't need
        ./scripts/config -d WLAN -d WIRELESS -d ATA -d PCCARD -d CONNECTOR -d USB_NET_DRIVERS -d SOUND -d DRM -d TIGON3 -d REALTEK_PHY -d NET_VENDOR_REALTEK -d NET_VENDOR_INTEL

        # enable virtualization related stuff
        ./scripts/config -e KVM_CLOCK -e CRYPTO_DEV_VIRTIO -e VIRTIO_FS -e I2C_VIRTIO -e VIRTIO_BALLOON -e VIRTIO_FS -e VIRTIO_IOMMU -e GVE -e HW_RANDOM_VIRTIO  -e PVPANIC

        # cirrus queries memory usage via cgroups, enable others for good measure
        ./scripts/config -e MEMCG -e CGROUP_PIDS -e BLK_CGROUP -e USER_NS

        # enable some drivers that are likely missing
        ./scripts/config -e CRYPTO_AES_NI_INTEL -e CRYPTO_CRC32C_INTEL -e CRYPTO_CRC32_PCLMUL

        # options to prevent systemd from complaining
        ./scripts/config -e BPF_SYSCALL -e BPF_JIT -e CGROUP_BPF

        # compress kernel
        ./scripts/config -e KERNEL_ZSTD

        # containers
        ./scripts/config -e OVERLAY_FS -e TUN -e BRIDGE -e VETH
        ./scripts/config -e NF_TABLES -e NFT_COMPAT -e NF_TABLES_IPV4 -e NF_TABLES_IPV6 -e NF_TABLES_BRIDGE -e NFT_CT -e NFT_REJECT -e NF_TABLES_NETDEV -e NF_TABLES_INET
        ./scripts/config -e NF_CONNTRACK_LABELS -e NETFILTER_ADVANCED -e NETFILTER_XT_MATCH_COMMENT -e NF_CONNTRACK_LABELS -e NETFILTER_ADVANCED -e NETFILTER_XT_MATCH_COMMENT -e NF_CONNTRACK_MARK -e NFT_NAT -e NFT_REJECT_NETDEV -e NFT_MAS

        # enable facilities that could be useful
        ./scripts/config -e DM_CRYPT -e DM_FLAKEY -e IKCONFIG_PROC

        make mod2yesconfig

        time make -j16 -s all
        make -j16 -s modules_install
        make -j16 -s install


        cd tools/perf
        # LIBBPF causes build failure due to signature change of BFD's init_disassemble_info
	# dependencies for java integration would be large, and aren't needed
        make install prefix=/usr/local/ NO_LIBBPF=1 NO_JVMTI=1

        # build liburing
        DEBIAN_FRONTEND=noninteractive apt-get purge -y -q 'liburing*'
        cd /usr/src/
        git clone --single-branch --depth 1 https://github.com/axboe/liburing.git
        cd liburing/
        echo liburing git revision is: $(git rev-list HEAD)
        ./configure --prefix=/usr/local/
        make -j8 -s install
        ldconfig
      SCRIPT
    ]
    only = ["googlecompute.sid-newkernel", "googlecompute.sid-newkernel-uring"]
  }

  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    inline = [
      <<-SCRIPT
        DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
        apt-get clean && rm -rf /var/lib/apt/lists/*
        fstrim -v -a
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

  # reboot to verify we still boot
  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
    inline = [
      <<-SCRIPT
        echo will reboot
        shutdown -r now
        sleep 360 # so that the shutdown shows effect before next command
      SCRIPT
    ]
    only = ["googlecompute.sid-newkernel", "googlecompute.sid-newkernel-uring"]
  }

  # check kernel version etc to see everything went well
  provisioner "shell" {
    execute_command = "sudo env {{ .Vars }} {{ .Path }}"
    pause_before = "20s"
    inline = [
      <<-SCRIPT
        uname -a
      SCRIPT
    ]
    only = ["googlecompute.sid-newkernel", "googlecompute.sid-newkernel-uring"]
  }
}
