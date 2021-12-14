# Using perl 5.26.3.1 for now, as newer versions don't currently work
# correctly for plperl

mkdir c:\t ;
cd c:\t ;

curl.exe -sSL -o perl.zip `
    https://strawberryperl.com/download/5.26.3.1/strawberry-perl-5.26.3.1-64bit-portable.zip ;
7z.exe x .\perl.zip -xr!c -oc:\strawberry\5.26.3.1 ;

cd c:\ ;
Remove-Item C:\t -Force -Recurse
