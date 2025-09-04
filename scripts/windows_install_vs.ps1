$ErrorActionPreference = "Stop"

mkdir c:\t
cd c:\t

function InstallVS($Version, $Link)
{
  $download_path = "c:\t\vs_buildtools_${Version}.exe"
  $install_path = "c:\VS_${Version}"

  echo "downloading visual studio ${Version} installer"
  curl.exe -fsSL -o ${download_path} ${Link}
  if (!$?) { throw 'cmdfail' }

  echo "starting visual studio ${Version} installation"
  Start-Process -Wait `
      -FilePath ${download_path} `
      -ArgumentList `
        '--quiet', '--wait', '--norestart', '--nocache', `
        '--installPath', "${install_path}", `
        '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', `
        '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.22621'
  if (!$?) { throw 'cmdfail' }

  # clear pdb files to download them later
  du -shc "${install_path}\VC\Tools\MSVC"
  rm "${install_path}\VC\Tools\MSVC\*\lib\**\**\*pdb"
  du -shc "${install_path}\VC\Tools\MSVC"
}

InstallVS "2019" "https://aka.ms/vs/16/release/vs_buildtools.exe"
InstallVS "2022" "https://aka.ms/vs/17/release/vs_buildtools.exe"

# Set VS-2019 as default
[Environment]::SetEnvironmentVariable('PATH',  'C:\VS_2019\VC\Auxiliary\Build;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')

# clear not required arm files
du -shc "" "C:\Program Files (x86)\Windows Kits"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\ucrt\arm"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\ucrt\arm64"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\um\arm"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\um\arm64"
du -shc "" "C:\Program Files (x86)\Windows Kits"

cd c:\
Remove-Item C:\t -Force -Recurse
Remove-Item -Force -Recurse ${Env:TEMP}\*
Remove-Item -Force -Recurse "${Env:ProgramData}\Package Cache"
