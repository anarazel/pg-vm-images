mkdir c:\t ;
cd c:\t ;

curl.exe -o openssl-setup.exe -sSL https://slproweb.com/download/Win64OpenSSL-1_1_1m.exe ;
echo 'starting openssl installation' ;
Start-Process -Wait -FilePath ".\openssl-setup.exe" `
  -ArgumentList '/DIR=c:\openssl\1.1.1m\ /VERYSILENT /SP- /SUPPRESSMSGBOXES' ;

cd c:\ ;
Remove-Item C:\t -Force -Recurse
