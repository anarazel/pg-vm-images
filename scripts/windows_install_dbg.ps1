# Install commandline debugger and log all crashes to c:\cirrus\crashlog.txt
#
# Done manually as doing this via chocolatey / the installer directly, ends up
# with a lot of unnecessary chaff, making the layer unnecessarily large.

$ErrorActionPreference = "Stop"

mkdir c:\t
cd c:\t

echo "downloading windows sdk (for debugger)"
curl.exe -sSL -o 'windsdksetup.exe' `
  https://download.microsoft.com/download/9/7/9/97982c1d-d687-41be-9dd3-6d01e52ceb68/windowssdk/winsdksetup.exe
if (!$?) { throw 'cmdfail' }

echo "starting windows sdk installation (for debugger)"
Start-Process -Wait -FilePath ".\windsdksetup.exe" `
  -ArgumentList '/Features OptionId.WindowsDesktopDebuggers /layout c:\t\sdk /quiet /norestart /log c:\t\sdk.log'
if (!$?) { throw 'cmdfail' }

Start-Process -Wait -FilePath msiexec.exe `
  -ArgumentList '/a "C:\t\sdk\Installers\X64 Debuggers And Tools-x64_en-us.msi" /qb /log install2.log'
if (!$?) { throw 'cmdfail' }

# For some reason the msi install ends up with a copy of the msi in c:/, remove
Remove-Item "c:\X64 Debuggers And Tools-x64_en-us.msi"

C:\Windows` Kits\10\Debuggers\x64\cdb.exe -version
if (!$?) { throw 'cmdfail' }

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug' `
  -Name 'Debugger' `
  -Value '"C:\Windows Kits\10\Debuggers\x64\cdb.exe" -p %ld -e %ld -g -kqm -c ".lines -e; .symfix+ ; aS /c proc !adplusext.adpprocname ; .block {.logopen /t c:/cirrus/crashlog-${proc}.txt}; lsa $ip; ~*kP ; !peb; .logclose ; q "'
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug' -Name Debugger

New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug' `
  -Name 'Auto' -Value 1 -PropertyType DWord

cd c:\
Remove-Item C:\t -Force -Recurse

# to make it easier to spot if there's additional bogus leftovers
dir c:\
