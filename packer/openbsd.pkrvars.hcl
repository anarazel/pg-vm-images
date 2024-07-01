name = "openbsd"
boot_command = [
  "S<enter><wait>",
  "cat <<EOF >>install.conf<enter>",
  "System hostname = openbsd73<enter>",
  "Password for root = packer<enter>",
  "Allow root ssh login = yes<enter>",
  "What timezone are you in = Etc/UTC<enter>",
  "Do you expect to run the X Window System = no<enter>",
  "Set name(s) = -man* -game* -x*<enter>",
  "Directory does not contain SHA256.sig. Continue without verification = yes<enter>",
  "EOF<enter>",
  "install -af install.conf && reboot<enter>"
]
iso_checksum = "sha256:034435c6e27405d5a7fafb058162943c194eb793dafdc412c08d49bb56b3892a"
iso_urls                = [
  "install75.iso",
  "https://cdn.openbsd.org/pub/OpenBSD/7.5/amd64/install75.iso"
]
output_file_name = "output/openbsd7-5.tar.gz"
vanilla_name = [ { name = "openbsd-vanilla" } ]
postgres_name = [ { name = "openbsd-postgres" } ]
