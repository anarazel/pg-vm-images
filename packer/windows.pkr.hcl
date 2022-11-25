variable "task_name" { type = string }

variable "build_type" {
  type = string
  default = "googlecompute"
}

variable "docker_repo" {
  type = string
  default = ""
}

variable "docker_server" {
  type = string
  default = ""
}

variable "gcp_password" {
  type = string
  default = ""
}

variable "gcp_project" { 
  type = string
  default = ""
}

variable "image_date" {
  type = string
  default = ""
}

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-ci"
  perl_version = "5.26.3.1"
  python_version = "3.10.6"

  windows_gcp_images = [
    {
      name = "${var.task_name}"
    },
  ]

  only = {
    vm = ["googlecompute.windows-ci-mingw64", "googlecompute.windows-ci-vs-2019"],
    docker = ["docker.windows-ci-vs-2019-docker", "docker.windows-ci-mingw64-docker"],
    vs_2019 = ["googlecompute.windows-ci-vs-2019", "docker.windows-ci-vs-2019-docker"],
    mingw64 = ["googlecompute.windows-ci-mingw64", "docker.windows-ci-mingw64-docker"],
  }
}

source "googlecompute" "windows" {
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

source "docker" "windows" {
  image = "docker.io/cirrusci/windowsservercore:2019-2022.06.23"
  windows_container = true
  commit = true
}

build {
  name = "windows"

  # for using -only '*.${CIRRUS_TASK_NAME}' while building images,
  # so we can easily combine the packer invocations later
  dynamic "source" {
    for_each = local.windows_gcp_images
    labels = ["source.${var.build_type}.windows"]
    iterator = tag

    content {
      name = tag.value.name
    }
  }

  ### base installations
  # googlecompute only
  provisioner "powershell" {
    inline = [
      # disable antivirus
      "Set-MpPreference -DisableRealtimeMonitoring $true -SubmitSamplesConsent NeverSend -MAPSReporting Disable",

      # install choco
      "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))",

      "choco install -y --no-progress 7zip",
      "choco install -y --no-progress git --parameters=\"/GitAndUnixToolsOnPath\"",
    ]
    only = local.only.vm
  }

  provisioner "powershell" {
    inline = [
      # contains useful utilities, including a diff we can use
      "[Environment]::SetEnvironmentVariable('PATH',  'C:\\Program Files\\Git\\usr\\bin;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')",
    ]
  }

  # install windows debugger
  provisioner "powershell" {
    script = "scripts/windows_install_dbg.ps1"
  }

  # install python
  provisioner "powershell" {
    environment_vars = ["TEMP_PYTHON_VERSION=${local.python_version}"]
    script = "scripts/windows_install_python.ps1"
  }

  # install meson and ninja
  provisioner "powershell" {
    inline = ["py -m pip install meson ninja"]
  }

  # install perl
  provisioner "powershell" {
    environment_vars = ["TEMP_PERL_VERSION=${local.perl_version}"]
    script = "scripts/windows_install_perl.ps1"
  }

  # set env vars for perl
  provisioner "powershell" {
    inline = [
      "[Environment]::SetEnvironmentVariable('DEFAULT_PERL_VERSION', '${local.perl_version}', 'Machine')",
      "[Environment]::SetEnvironmentVariable('PATH',  \"C:\\strawberry\\${local.perl_version}\\perl\\bin;\" + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')",
    ]
  }

  # install openssl
  provisioner "powershell" {
    script = "scripts/windows_install_openssl.ps1"
  }
  ### end of base installations

  ### mingw installations
  provisioner "powershell" {
    inline = [
      "[Environment]::SetEnvironmentVariable('MSYSTEM', 'UCRT64', 'Machine')",
      # this could be reduntant
      "$env:MSYSTEM = 'UCRT64'",
    ]
    only = local.only.mingw64
  }

  provisioner "powershell" {
    script = "scripts/windows_install_mingw64.ps1"
    only = local.only.mingw64
  }

  # Change default console code page (0) with Windows code page (65001) to get rid of warnings in postgres tests
  provisioner "powershell" {
    inline = ["chcp 65001"]
    only = local.only.mingw64
  }
  ### end of mingw installations

  ### vs-2019 installations
  provisioner "powershell" {
    script = "scripts/windows_install_winflexbison.ps1"
    only = local.only.vs_2019
  }

  provisioner "powershell" {
    script = "scripts/windows_install_pg_deps.ps1"
    only = local.only.vs_2019
  }

  provisioner "powershell" {
    script = "scripts/windows_install_vs_2019.ps1"
    only = local.only.vs_2019
  }
  ### end of vs-2019 installations

  post-processors {
    post-processor "docker-tag" {
        repository =  "${var.docker_repo}/${var.task_name}"
        tags = ["latest"]
        # packer version is 1.6.6 while generating the vm images, and it complains
        # if local.only.docker is used here
        only = ["docker.windows-ci-vs-2019-docker", "docker.windows-ci-mingw64-docker"]
      }
    post-processor "docker-push" {
      # https://cloud.google.com/container-registry/docs/advanced-authentication#token
      login = true
      login_username = "oauth2accesstoken"
      login_password = "${var.gcp_password}"
      login_server = "${var.docker_server}"
      only = ["docker.windows-ci-vs-2019-docker", "docker.windows-ci-mingw64-docker"]
    }
  }
}
