$ErrorActionPreference = "Stop"

echo "downloading msys2"

curl.exe -sSL "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe" -o msys2.exe
if (!$?) { throw 'cmdfail' };

echo "starting msys2 installation"
.\msys2.exe -y -oC:\ ;
if (!$?) { throw 'cmdfail' };
Remove-Item msys2.exe ;

echo "setting up msys2 for the first time"
function msys() { C:\msys64\usr\bin\bash.exe @('-lc') + @Args; if (!$?) { throw 'cmdfail' };} ;
# When msys is used for the first time, it performs setup tasks. Doing other work in the same invocation does not reliably work.
msys ' ' ;
msys 'pacman --noconfirm -Syuu' ;
msys 'pacman --noconfirm -Scc' ;

echo 'installing packages' ;
msys 'pacman -S --needed --noconfirm git bison flex make diffutils \
    ucrt64/mingw-w64-ucrt-x86_64-{ccache,gcc,icu,libxml2,libxslt,lz4,perl,pkg-config,zlib}' ;
msys 'pacman -Scc --noconfirm'

# Install perl modules to enable tap tests
msys 'where perl'
msys '(echo; echo o conf recommends_policy 0; echo notest install IPC::Run) | cpan'
