$ErrorActionPreference = "Stop"

$filepath = "$Env:TEMP/winflexbison.zip"

echo "downloading winflexbison"
curl.exe -fsSL -o "$filepath" `
    https://github.com/lexxmark/winflexbison/releases/download/v2.5.24/win_flex_bison-2.5.24.zip ;
if (!$?) { throw 'cmdfail' }

echo "installing winflexbison"
7z.exe x "$filepath" -oc:\winflexbison
if (!$?) { throw 'cmdfail' }

Rename-Item -Path c:\winflexbison\win_flex.exe c:\winflexbison\flex.exe
Rename-Item -Path c:\winflexbison\win_bison.exe c:\winflexbison\bison.exe

Remove-Item "$filepath" -Force
