variable "image_date" { type = string }
variable "gcp_project" { type = string }
variable "image_name" { type = string }

# If bucket variable is not created, packer complains about that
variable "bucket" { type = string }

variable "prefix" {
  type = string
  default = ""
}

source "googlecompute" "netbsd-vanilla" {
  disk_size               = "25"
  disk_type               = "pd-ssd"
  preemptible             = "true"
  project_id              = var.gcp_project
  source_image_family     = "pg-ci-netbsd-9-2-vanilla"
  source_image_project_id = ["${var.gcp_project}"]
  image_family            = "pg-ci-${var.image_name}"
  image_name              = "${var.prefix}pg-ci-${var.image_name}-${var.image_date}"
  zone                    = "us-west1-a"
  machine_type            = "e2-highcpu-4"
  ssh_username            = "root"
  ssh_timeout             = "300s"
}

build {
  name="netbsd-postgres"
  sources = ["source.googlecompute.netbsd-vanilla"]

  provisioner "shell" {
    script = "scripts/bsd/netbsd-prep-postgres.sh"
  }

  # clear ssh keys
  provisioner "shell" {
    inline = ["rm -rf /home/* && rm -rf /root/.ssh/"]
  } 
}
