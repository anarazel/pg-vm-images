$ErrorActionPreference = "Stop"

$perl_version = $args[0]
$filepath = "$Env:TEMP/perl.zip"

echo "downloading perl $perl_vesion"
curl.exe -sSL -o "$filepath" `
    https://strawberryperl.com/download/$perl_version/strawberry-perl-$perl_version-64bit-portable.zip
if (!$?) { throw 'cmdfail' }

echo "installing perl $perl_vesion"

# Exclude the 'c' directory - it contains enough contrib stuff -which we don't
# need - to bloat the image size noticeably
7z.exe x "$filepath" -xr!c -oc:\strawberry\$perl_version
if (!$?) { throw 'cmdfail' }

Remove-Item "$filepath" -Force
