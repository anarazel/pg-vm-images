mkdir c:\t ;
cd c:\t ;

curl.exe -sSL -o winflexbison.zip `
    https://github.com/lexxmark/winflexbison/releases/download/v2.5.24/win_flex_bison-2.5.24.zip ;

echo 'installing winflexbison' ;
7z.exe x .\winflexbison.zip -oc:\winflexbison ;
Rename-Item -Path c:\winflexbison\win_flex.exe c:\winflexbison\flex.exe ;
Rename-Item -Path c:\winflexbison\win_bison.exe c:\winflexbison\bison.exe ;

cd c:\ ;
Remove-Item C:\t -Force -Recurse
