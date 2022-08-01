variable "image_date" { type = string }
variable "gcp_project" { type = string }
variable "image_name" { type = string }

# If bucket variable is not created, packer complains about that
variable "bucket" { type = string }

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-ci"
  version = "7-1"
}

source "googlecompute" "openbsd-vanilla" {
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  project_id              = var.gcp_project
  source_image_family     = "${local.name}-openbsd-${local.version}-vanilla"
  source_image_project_id = ["${var.gcp_project}"]
  image_family            = "${local.name}-${var.image_name}"
  image_name              = "${local.name}-${var.image_name}-${var.image_date}"
  instance_name           = "build-${var.image_name}-${var.image_date}"
  zone                    = "us-west1-a"
  machine_type            = "e2-highcpu-4"
  ssh_username            = "root"
  # OpenBSD doesn't accept the packer default of rsa anymore.
  temporary_key_pair_type = "ed25519"
  ssh_timeout             = "300s"
}

build {
  name = "openbsd-postgres"
  sources = ["source.googlecompute.openbsd-vanilla"]

  provisioner "shell" {
    script = "scripts/bsd/openbsd-prep-postgres.sh"
  }

  # clear users and ssh keys
  provisioner "shell" {
    script = "scripts/bsd/clear_users_and_ssh_keys.sh"
  }
}
