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
iso_checksum = "sha256:d3a7c5b9bf890bc404304a1c96f9ee72e1d9bbcf9cc849c1133bdb0d67843396"
iso_urls                = [
  "install71.iso",
  "https://cdn.openbsd.org/pub/OpenBSD/7.1/amd64/install71.iso"
]
output_file_name = "output/openbsd71.tar.gz"
version = "7-1"
vanilla_name = [ { name = "openbsd-vanilla" } ]
postgres_name = [ { name = "openbsd-postgres" } ]
