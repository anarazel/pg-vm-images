name = "netbsd"
boot_command = [
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
iso_checksum = "sha256:5f1bca14c4090122f31713dd86a926f63109dd6fb3c05f9b9b150a78acc8bc7e"
iso_urls = [
  "NetBSD-9.2-amd64.iso",
  "https://cdn.netbsd.org/pub/NetBSD/NetBSD-9.2/images/NetBSD-9.2-amd64.iso"
]
output_file_name = "output/netbsd92.tar.gz"
version = "9-2"
vanilla_name = [ { name = "netbsd-vanilla" } ]
postgres_name = [ { name = "netbsd-postgres" } ]
