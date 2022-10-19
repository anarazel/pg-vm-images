variable "image_date" { type = string }
variable "gcp_project" { type = string }
variable "task_name" { type = string }

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-ci"

  windows_gcp_images = [
    {
      name = "${var.task_name}"
    },
  ]
}

source "googlecompute" "windows-vm" {
  disk_size               = "50"
  disk_type               = "pd-ssd"
  project_id              = var.gcp_project
  source_image_family     = "windows-2022"
  image_name              = "${local.name}-${var.task_name}-${var.image_date}"
  image_family            = "${local.name}-${var.task_name}"
  zone                    = "us-west1-a"
  machine_type            = "n2-standard-4"
  instance_name           = "build-${var.task_name}-${var.image_date}"
  communicator            = "winrm"
  winrm_username          = "packer_user"
  winrm_insecure          = true
  winrm_use_ssl           = true
  winrm_timeout           = "10m"
  metadata = {
    windows-startup-script-cmd = "winrm quickconfig -quiet & net user /add packer_user & net localgroup administrators packer_user /add & winrm set winrm/config/service/auth @{Basic=\"true\"}"
  }
}

build {
  name = "windows"

  # for using -only '*.${CIRRUS_TASK_NAME}' while building images,
  # so we can easily combine the packer invocations later
  dynamic "source" {
    for_each = local.windows_gcp_images
    labels = ["source.googlecompute.windows-vm"]
    iterator = tag

    content {
      name = tag.value.name
    }
  }

  ### base installations
  # preparation installations
  provisioner "powershell" {
    inline = [
      ### couple of optimizations?
      # disable antivirus
      "Set-MpPreference -DisableRealtimeMonitoring $true -SubmitSamplesConsent NeverSend -MAPSReporting Disable",
      ###

      # install choco
      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",

      "choco install -y git",
      # contains useful utilities, including a diff we can use
      "[Environment]::SetEnvironmentVariable('PATH',  'C:\\Program Files\\Git\\usr\\bin;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')",
    ]
  }

  # install 7z
  provisioner "powershell" {
    script = "scripts/windows_install_7z.ps1"
  }

  # install windows debugger
  provisioner "powershell" {
    script = "scripts/windows_install_dbg.ps1"
  }

  # install python
  provisioner "powershell" {
    environment_vars = ["TEMP_PYTHON_VERSION=3.10.6"]
    script = "scripts/windows_install_python.ps1"
  }

  # install meson and ninja
  provisioner "powershell" {
    inline = ["py -m pip install meson ninja"]
  }

  # install perl
  provisioner "powershell" {
    environment_vars = ["TEMP_PERL_VERSION=5.26.3.1"]
    script = "scripts/windows_install_perl.ps1"
  }

  # install openssl
  provisioner "powershell" {
    script = "scripts/windows_install_openssl.ps1"
  }
  ### end of base installations

  ### mingw installations
  provisioner "powershell" {
    environment_vars = ["MSYSTEM=UCRT64"]
    script = "scripts/windows_install_mingw64.ps1"
    only = ["googlecompute.windows-mingw"]
  }

  # Change default console code page (0) with Windows code page (65001) to get rid of warnings in postgres tests
  provisioner "powershell" {
    inline = ["chcp 65001"]
    only = ["googlecompute.windows-mingw"]
  }
  ### end of mingw installations

  ### vs-2019 installations
  provisioner "powershell" {
    script = "scripts/windows_install_winflexbison.ps1"
    only = ["googlecompute.windows-vs-2019"]
  }

  provisioner "powershell" {
    script = "scripts/windows_install_pg_deps.ps1"
    only = ["googlecompute.windows-vs-2019"]
  }

  provisioner "powershell" {
    script = "scripts/windows_install_vs_2019.ps1"
    only = ["googlecompute.windows-vs-2019"]
  }
  ### end of vs-2019 installations
}
