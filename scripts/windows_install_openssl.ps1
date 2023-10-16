# Install openssl
#
# This is one of the windows binaries referenced by the openssl wiki. See
# https://www.openssl.org/community/binaries.html and
# https://wiki.openssl.org/index.php/Binaries
#
# It might be nicer to switch to the openssl built as part of curl-for-win,
# but recent releases only build openssl 3, and that still seems troublesome
# on Windows.

$ErrorActionPreference = "Stop"

$filepath = "$Env:TEMP/openssl-setup.exe"

echo "downloading openssl"
curl.exe -o "$filepath" -fsSL https://slproweb.com/download/Win64OpenSSL-1_1_1w.exe
if (!$?) { throw 'cmdfail' }

echo "installing openssl"
Start-Process -Wait -FilePath "$filepath" `
  -ArgumentList '/DIR=c:\openssl\1.1\ /VERYSILENT /SP- /SUPPRESSMSGBOXES'
if (!$?) { throw 'cmdfail' }

Remove-Item "$filepath" -Force
