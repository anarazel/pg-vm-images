variable "task_name" { type = string }
variable "image_date" { type = string }

variable "build_type" {
  type = string
  default = "googlecompute"
}

variable "docker_repo" {
  type = string
  default = ""
}

# Execute command for VM instances, containers will overwrite this because
# docker builder uses docker exec to run commands and that is hardcoded.
# It doesn't capture errors correctly when VM's execute command is used.
# So, containers have another execute_command.
variable "execute_command" {
  type = string
  default = "powershell -executionpolicy bypass \"& { if (Test-Path variable:global:ProgressPreference){$ProgressPreference='SilentlyContinue'}; $ErrorActionPreference = 'Stop' ;. {{.Vars}}; &'{{.Path}}'; exit $LastExitCode }\""
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

variable "prefix" {
  type = string
  default = ""
}

locals {
  name = "${var.prefix}pg-ci"
  image_identity = "${local.name}-${var.task_name}-${var.image_date}"

  perl_version = "5.26.3.1"
  python_version = "3.10.6"

  windows_gcp_images = [
    {
      name = "${var.task_name}"
    },
  ]

  only = {
    vm = ["googlecompute.windows-ci-mingw64", "googlecompute.windows-ci-vs-2019"],
    docker = ["docker.windows_ci_vs_2019", "docker.windows_ci_mingw64"],
    vs_2019 = ["googlecompute.windows-ci-vs-2019", "docker.windows_ci_vs_2019"],
    mingw64 = ["googlecompute.windows-ci-mingw64", "docker.windows_ci_mingw64"],
  }
}

source "googlecompute" "windows" {
  disk_size               = "50"
  disk_type               = "pd-ssd"
  project_id              = var.gcp_project
  source_image_family     = "windows-2022"
  image_name              = local.image_identity
  zone                    = "us-west1-a"
  machine_type            = "n2-standard-4"
  instance_name           = "build-${var.task_name}-${var.image_date}"
  communicator            = "winrm"
  winrm_username          = "packer_user"
  winrm_insecure          = true
  winrm_use_ssl           = true
  winrm_timeout           = "10m"
  state_timeout           = "10m"
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
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
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
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      # contains useful utilities, including a diff we can use
      "[Environment]::SetEnvironmentVariable('PATH',  'C:\\Program Files\\Git\\usr\\bin;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')",

      # set IMAGE_IDENTITY to distinguish images on CI runs
      "[Environment]::SetEnvironmentVariable('IMAGE_IDENTITY', '${local.image_identity}', 'Machine')",
    ]
  }

  # install windows debugger
  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_dbg.ps1"
  }

  # install python
  provisioner "powershell" {
    execute_command = var.execute_command
    environment_vars = ["TEMP_PYTHON_VERSION=${local.python_version}"]
    script = "scripts/windows_install_python.ps1"
  }

  # install meson and ninja
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "py -m pip install meson ninja"
    ]
  }

  # install perl
  provisioner "powershell" {
    execute_command = var.execute_command
    environment_vars = ["TEMP_PERL_VERSION=${local.perl_version}"]
    script = "scripts/windows_install_perl.ps1"
  }

  # set env vars for perl
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "[Environment]::SetEnvironmentVariable('DEFAULT_PERL_VERSION', '${local.perl_version}', 'Machine')",
      "[Environment]::SetEnvironmentVariable('PATH',  \"C:\\strawberry\\${local.perl_version}\\perl\\bin;\" + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')",
    ]
  }

  # install openssl
  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_openssl.ps1"
  }
  ### end of base installations

  ### mingw installations
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "[Environment]::SetEnvironmentVariable('MSYSTEM', 'UCRT64', 'Machine')",
      # this could be reduntant
      "$env:MSYSTEM = 'UCRT64'",
    ]
    only = local.only.mingw64
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_mingw64.ps1"
    only = local.only.mingw64
  }

  # Change default console code page (0) with Windows code page (65001) to get rid of warnings in postgres tests
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "chcp 65001"
    ]
    only = local.only.mingw64
  }

  # MSYS2 might spawn processes that will stay around in the background forever.
  # They need to be killed. See: https://www.msys2.org/docs/ci/
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "taskkill /F /FI \"MODULES eq msys-2.0.dll\""
    ]
    only = local.only.mingw64
  }
  ### end of mingw installations

  ### vs-2019 installations
  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_winflexbison.ps1"
    only = local.only.vs_2019
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_pg_deps.ps1"
    only = local.only.vs_2019
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_vs_2019.ps1"
    only = local.only.vs_2019
  }
  ### end of vs-2019 installations

  post-processors {
    post-processor "docker-tag" {
        repository =  "${var.docker_repo}/${var.task_name}"
        # tag image with both latest and image-date to distinguish images on CI runs
        tags = ["${var.image_date}", "latest"]
        # packer version is 1.6.6 while generating the vm images, and it complains
        # if local.only.docker is used here
        only = ["docker.windows_ci_vs_2019", "docker.windows_ci_mingw64"]
      }
    post-processor "docker-push" {
      # https://cloud.google.com/container-registry/docs/advanced-authentication#token
      login = true
      login_username = "oauth2accesstoken"
      login_password = "${var.gcp_password}"
      login_server = "${var.docker_server}"
      only = ["docker.windows_ci_vs_2019", "docker.windows_ci_mingw64"]
    }
  }
}
