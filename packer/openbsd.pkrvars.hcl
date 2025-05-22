name = "openbsd"
boot_command = [
  "S<enter><wait>",
  "cat <<EOF >>install.conf<enter>",
  "System hostname = openbsd77<enter>",
  "Password for root = packer<enter>",
  "Allow root ssh login = yes<enter>",
  "What timezone are you in = Etc/UTC<enter>",
  "Do you expect to run the X Window System = no<enter>",
  "Set name(s) = -man* -game* -x*<enter>",
  "Directory does not contain SHA256.sig. Continue without verification = yes<enter>",
  "EOF<enter>",
  "install -af install.conf && reboot<enter>"
]
iso_checksum = "sha256:da0106e39463f015524dca806f407c37a9bdd17e6dfffe533b06a2dd2edd8a27"
iso_urls                = [
  "install77.iso",
  "https://cdn.openbsd.org/pub/OpenBSD/7.7/amd64/install77.iso"
]
output_file_name = "output/openbsd7-7.tar.gz"
vanilla_name = [ { name = "openbsd-vanilla" } ]
postgres_name = [ { name = "openbsd-postgres" } ]
