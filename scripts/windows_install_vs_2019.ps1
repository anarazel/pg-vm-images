$ErrorActionPreference = "Stop"

mkdir c:\t
cd c:\t

echo "downloading visual studio installer"
curl.exe -fsSL -o c:\t\vs_buildtools.exe https://aka.ms/vs/16/release/vs_buildtools.exe
if (!$?) { throw 'cmdfail' }

echo "starting visual studio installation"
Start-Process -Wait `
    -FilePath c:\t\vs_buildtools.exe `
    -ArgumentList `
      '--quiet', '--wait', '--norestart', '--nocache', `
      '--installPath', 'c:\BuildTools', `
      '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64', `
      '--add', 'Microsoft.VisualStudio.Component.Windows10SDK.20348'
if (!$?) { throw 'cmdfail' }

[Environment]::SetEnvironmentVariable('PATH',  'C:\BuildTools\VC\Auxiliary\Build;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')

# clear pdb files to download them later
du -shc "C:\BuildTools\VC\Tools\MSVC"
rm "C:\BuildTools\VC\Tools\MSVC\*\lib\**\**\*pdb"
du -shc "C:\BuildTools\VC\Tools\MSVC"

# clear not required arm files
du -shc "" "C:\Program Files (x86)\Windows Kits"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\ucrt\arm"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\ucrt\arm64"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\um\arm"
rm -r "C:\Program Files (x86)\Windows Kits\10\Lib\*\um\arm64"
du -shc "" "C:\Program Files (x86)\Windows Kits"
