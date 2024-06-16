$ErrorActionPreference = "Stop"

$perl_version = $Env:TEMP_PERL_VERSION
$filepath = "$Env:TEMP/perl.zip"

echo "downloading perl $perl_vesion"
curl.exe -fsSL -o "$filepath" `
    https://strawberryperl.com/download/$perl_version/strawberry-perl-$perl_version-64bit-portable.zip
if (!$?) { throw 'cmdfail' }

echo "installing perl $perl_vesion"

7z.exe x "$filepath" -oc:\strawberry\$perl_version
if (!$?) { throw 'cmdfail' }

Remove-Item "$filepath" -Force
