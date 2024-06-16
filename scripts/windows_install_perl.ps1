$ErrorActionPreference = "Stop"

$perl_version = $Env:TEMP_PERL_VERSION
$filepath = "$Env:TEMP/perl.zip"

echo "downloading perl $perl_vesion"
curl.exe -fsSL -o "$filepath" `
  https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_53822_64bit/strawberry-perl-5.38.2.2-64bit-portable.zip
if (!$?) { throw 'cmdfail' }

echo "installing perl $perl_vesion"

7z.exe x "$filepath" -oc:\strawberry\$perl_version
if (!$?) { throw 'cmdfail' }

Remove-Item "$filepath" -Force
