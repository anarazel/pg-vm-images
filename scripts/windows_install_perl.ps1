$ErrorActionPreference = "Stop"

$perl_version = $Env:TEMP_PERL_VERSION
$perl_version_wo_dots = $perl_version.Replace(".", "")
$filepath = "$Env:TEMP/perl.zip"

echo "downloading perl $perl_vesion"
curl.exe -fsSL -o "$filepath" `
    https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_${perl_version_wo_dots}_64bit/strawberry-perl-${perl_version}-64bit-portable.zip
if (!$?) { throw 'cmdfail' }

echo "installing perl $perl_vesion"

# Exclude the 'c' directory - it contains enough contrib stuff -which we don't
# need - to bloat the image size noticeably
7z.exe x "$filepath" -xr!c -oc:\strawberry\$perl_version
if (!$?) { throw 'cmdfail' }

Remove-Item "$filepath" -Force
