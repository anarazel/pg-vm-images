# Install openssl
#
# This is one of the windows binaries referenced by the openssl wiki. See
# https://www.openssl.org/community/binaries.html and
# https://wiki.openssl.org/index.php/Binaries
#
# It might be nicer to switch to the openssl built as part of curl-for-win,
# but recent releases only build openssl 3, and that still seems troublesome
# on Windows.

mkdir c:\t ;
cd c:\t ;

curl.exe -o openssl-setup.exe -sSL https://slproweb.com/download/Win64OpenSSL-1_1_1m.exe ;
echo 'starting openssl installation' ;
Start-Process -Wait -FilePath ".\openssl-setup.exe" `
  -ArgumentList '/DIR=c:\openssl\1.1.1m\ /VERYSILENT /SP- /SUPPRESSMSGBOXES' ;

cd c:\ ;
Remove-Item C:\t -Force -Recurse
