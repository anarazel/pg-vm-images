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
iso_checksum = "sha256:fdf1210ffe87213eeca5f1d317e8b19364cbae83545cdfc7845098a53fc79a60"
iso_urls                = [
  "install73.iso",
  "https://cdn.openbsd.org/pub/OpenBSD/7.3/amd64/install73.iso"
]
output_file_name = "output/openbsd73.tar.gz"
vanilla_name = [ { name = "openbsd-vanilla" } ]
postgres_name = [ { name = "openbsd-postgres" } ]
