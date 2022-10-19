# taken from https://gist.github.com/dansmith65/7dd950f183af5f5deaf9650f2ad3226c
$ErrorActionPreference = "Stop"

$filepath = "$Env:TEMP/7zip-setup.exe"

$url = 'https://7-zip.org/' + (Invoke-WebRequest -UseBasicParsing -Uri 'https://7-zip.org/' | Select-Object -ExpandProperty Links | Where-Object {($_.outerHTML -match 'Download')-and ($_.href -like "a/*") -and ($_.href -like "*-x64.exe")} | Select-Object -First 1 | Select-Object -ExpandProperty href)

echo "downloading 7zip"
curl.exe -o "$filepath" -sSL "$url"
if (!$?) { throw 'cmdfail' }

echo "Installing 7zip"
Start-Process -Wait -FilePath "$filepath" -Args "/S"
if (!$?) { throw 'cmdfail' }

[Environment]::SetEnvironmentVariable('PATH',  'C:\Program Files\7-Zip;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')

Remove-Item "$filepath" -Force
