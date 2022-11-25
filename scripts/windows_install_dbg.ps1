# Install commandline debugger and log all crashes to c:\cirrus\crashlog.txt
#
# Done manually as doing this via chocolatey / the installer directly, ends up
# with a lot of unnecessary chaff, making the layer unnecessarily large.

$ErrorActionPreference = "Stop"

mkdir c:\t
cd c:\t


echo "configuring windows error reporting"

# prevent windows error handling dialog from causing hangs
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' `
  -Name 'DontShowUI' -Value 1 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' `
  -Name 'Disabled' -Value 1 -PropertyType DWord

# Will hopefully not be triggered because of the JIT debugger configured below, but
# just to be sure...
New-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting' `
  -Name 'LocalDumps'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps' `
  -Name 'DumpFolder' -Value "C:\cirrus\crashdumps" -PropertyType ExpandString
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps' `
  -Name 'DumpCount' -Value 5 -PropertyType DWord
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps' `
  -Name 'Dumptype' -Value 1 -PropertyType DWord


echo "downloading windows sdk (for debugger)"
curl.exe -sSL -o 'windsdksetup.exe' `
  https://download.microsoft.com/download/9/7/9/97982c1d-d687-41be-9dd3-6d01e52ceb68/windowssdk/winsdksetup.exe
if (!$?) { throw 'cmdfail' }

echo "starting windows sdk installation (for debugger)"
Start-Process -Wait -FilePath ".\windsdksetup.exe" `
  -ArgumentList '/Features OptionId.WindowsDesktopDebuggers /layout c:\t\sdk /quiet /norestart /log c:\t\sdk.log'
if (!$?) { throw 'cmdfail' }


# Install x64 debugger
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


# Install x86 debugger
Start-Process -Wait -FilePath msiexec.exe `
  -ArgumentList '/a "C:\t\sdk\Installers\X86 Debuggers And Tools-x86_en-us.msi" /qb /log install2.log'
if (!$?) { throw 'cmdfail' }

# For some reason the msi install ends up with a copy of the msi in c:/, remove
Remove-Item "c:\X86 Debuggers And Tools-x86_en-us.msi"

C:\Windows` Kits\10\Debuggers\x86\cdb.exe -version
if (!$?) { throw 'cmdfail' }

Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug' `
  -Name 'Debugger' `
  -Value '"C:\Windows Kits\10\Debuggers\x86\cdb.exe" -p %ld -e %ld -g -kqm -c ".lines -e; .symfix+ ; aS /c proc !adplusext.adpprocname ; .block {.logopen /t c:/cirrus/crashlog-${proc}.txt}; lsa $ip; ~*kP ; !peb; .logclose ; q "'
Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug' -Name Debugger
New-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug' `
  -Name 'Auto' -Value 1 -PropertyType DWord

[Environment]::SetEnvironmentVariable('PATH',  'C:\Windows Kits\10\Debuggers\x64;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')


cd c:\
Remove-Item C:\t -Force -Recurse


# Remove unnecessary things to keep image size in check - the pdb files are
# the biggest chunk. It's better to download those symbols than for the image
# to start up slowly
du -shc "c:/Windows Kits/10/Debuggers/"
rm "c:/Windows Kits/10/Debuggers/*/*.doc"
rm "c:/Windows Kits/10/Debuggers/*/*.chm"
rm "c:/Windows Kits/10/Debuggers/*/sym/*pdb"
du -shc "c:/Windows Kits/10/Debuggers/"


# to make it easier to spot if there's additional bogus leftovers
dir c:\
