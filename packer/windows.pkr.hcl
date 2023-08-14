variable "image_name" { type = string }
variable "image_date" { type = string }

variable "build_type" {
  type = string
  default = "googlecompute"
}

# Packer doesn't capture errors correctly when default execute command is used.
# See $ErrorActionPreference = 'Stop' in the new execute_command.
# So, use new execute_command to handle VM errors correctly
variable "execute_command" {
  type = string
  default = "powershell -executionpolicy bypass \"& { if (Test-Path variable:global:ProgressPreference){$ProgressPreference='SilentlyContinue'}; $ErrorActionPreference = 'Stop' ;. {{.Vars}}; &'{{.Path}}'; exit $LastExitCode }\""
}

variable "gcp_project" {
  type = string
  default = ""
}

locals {
  image_identity = "${var.image_name}-${var.image_date}"

  perl_version = "5.26.3.1"
  python_version = "3.10.6"

  windows_gcp_images = [
    {
      task_name = "windows-ci"
    },
  ]
}

source "googlecompute" "windows" {
  disk_size               = "50"
  disk_type               = "pd-ssd"
  project_id              = var.gcp_project
  source_image_family     = "windows-2022"
  image_name              = local.image_identity
  zone                    = "us-west1-a"
  machine_type            = "c2-standard-4"
  instance_name           = "build-${local.image_identity}"
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

build {
  name = "windows"

  # for using -only '*.${IMAGE_NAME}' while building images,
  # so we can easily combine the packer invocations later
  dynamic "source" {
    for_each = local.windows_gcp_images
    labels = ["source.${var.build_type}.windows"]
    iterator = tag

    content {
      name = tag.value.task_name
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
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_mingw64.ps1"
  }

  # Change default console code page (0) with Windows code page (65001) to get rid of warnings in postgres tests
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "chcp 65001"
    ]
  }

  # MSYS2 might spawn processes that will stay around in the background forever.
  # They need to be killed. See: https://www.msys2.org/docs/ci/
  provisioner "powershell" {
    execute_command = var.execute_command
    inline = [
      "$ErrorActionPreference = 'Stop'",
      "taskkill /F /FI \"MODULES eq msys-2.0.dll\""
    ]
  }
  ### end of mingw installations

  ### vs-2019 installations
  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_winflexbison.ps1"
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_pg_deps.ps1"
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_vs_2019.ps1"
  }
  ### end of vs-2019 installations
}
