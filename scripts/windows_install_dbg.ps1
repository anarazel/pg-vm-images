# Install commandline debugger and log all crashes to c:\cirrus\crashlog.txt
#
# Done manually as doing this via chocolatey / the installer directly, ends up
# with a lot of unnecessary chaff, making the layer unnecessarily large.
mkdir c:\t ;
cd c:\t ;

curl.exe -sSL -o 'windsdksetup.exe' https://download.microsoft.com/download/9/7/9/97982c1d-d687-41be-9dd3-6d01e52ceb68/windowssdk/winsdksetup.exe ;
echo 'starting windows sdk installation (for debugger)' ;
Start-Process -Wait -FilePath ".\windsdksetup.exe" `
  -ArgumentList '/Features OptionId.WindowsDesktopDebuggers /layout c:\t\sdk /quiet /norestart /log c:\t\sdk.log' `
  ;

Start-Process -Wait -FilePath msiexec.exe `
  -ArgumentList '/a "C:\t\sdk\Installers\X64 Debuggers And Tools-x64_en-us.msi" /qb /log install2.log' `
;
C:\Windows` Kits\10\Debuggers\x64\cdb.exe -version ;

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug' -Name 'Debugger' -Value '"C:\Windows Kits\10\Debuggers\x64\cdb.exe" -p %ld -e %ld -g -kqm -c ".lines -e; .symfix+ ;.logappend c:\cirrus\crashlog.txt ; !peb; ~*kP ; .logclose ; q "' ;
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug' -Name 'Auto' -Value 1 -PropertyType DWord ;
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug' -Name Debugger ;

cd c:\ ;
Remove-Item C:\t -Force -Recurse
