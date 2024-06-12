# Install packages via vcpkg
$ErrorActionPreference = "Stop"

cd ${Env:VCPKG_PATH}
.\bootstrap-vcpkg.bat -disableMetrics
.\vcpkg.exe install --debug --binarysource=files,${Env:VCPKG_CACHE},readwrite --triplet=x64-windows `
  "gettext[tools]" `
  krb5 `
  icu `
  "libxml2[tools,iconv,icu]" `
  libxslt `
  lz4 `
  openssl `
  pkgconf `
  readline-win32 `
  tcl `
  zlib `
  zstd
if (!$?) { throw 'cmdfail' };
