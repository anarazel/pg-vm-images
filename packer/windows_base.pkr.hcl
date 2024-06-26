variable "image_name"   { type = string }
variable "image_date"   { type = string }
variable "gcp_project"  {type = string}

# Packer doesn't capture errors correctly when default execute command is used.
# See $ErrorActionPreference = 'Stop' in the new execute_command.
# So, use new execute_command to handle VM errors correctly
variable "execute_command" {
  type = string
  default = "powershell -executionpolicy bypass \"& { if (Test-Path variable:global:ProgressPreference){$ProgressPreference='SilentlyContinue'}; $ErrorActionPreference = 'Stop' ;. {{.Vars}}; &'{{.Path}}'; exit $LastExitCode }\""
}

locals {
  image_identity = "${var.image_name}-${var.image_date}"
}

source "googlecompute" "windows-base" {
  disk_size               = "50"
  disk_type               = "pd-ssd"
  project_id              = var.gcp_project
  source_image_family     = "windows-2022"
  image_name              = local.image_identity
  zone                    = "us-west1-a"
  machine_type            = "t2d-standard-4"
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
  sources = ["googlecompute.windows-base"]

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

      # set BASE_IMAGE_IDENTITY to distinguish images on CI runs
      "[Environment]::SetEnvironmentVariable('BASE_IMAGE_IDENTITY', '${local.image_identity}', 'Machine')",
    ]
  }

  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_install_vs_2019.ps1"
  }

  # clean unnecessary files
  provisioner "powershell" {
    execute_command = var.execute_command
    script = "scripts/windows_clean_unnecessary_files.ps1"
  }
}
