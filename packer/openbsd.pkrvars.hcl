name = "openbsd"
boot_command = [
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
iso_checksum = "sha256:0369ef40a3329efcb978c578c7fdc7bda71e502aecec930a74b44160928c91d3"
iso_urls                = [
  "install72.iso",
  "https://cdn.openbsd.org/pub/OpenBSD/7.2/amd64/install72.iso"
]
output_file_name = "output/openbsd72.tar.gz"
version = "7-2"
vanilla_name = [ { name = "openbsd-vanilla" } ]
postgres_name = [ { name = "openbsd-postgres" } ]
