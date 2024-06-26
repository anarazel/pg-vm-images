# Install packages via vcpkg
$ErrorActionPreference = "Stop"

cd ${VCPKG_PATH}
.\bootstrap-vcpkg.bat -disableMetrics

# Build krb5 in optimized mode, it outputs too much information in debug builds
.\vcpkg.exe install --clean-after-build --binarysource=files,${VCPKG_CACHE},readwrite --triplet=x64-windows `
  krb5:x64-windows-release
if (!$?) { throw 'cmdfail' };

.\vcpkg.exe install --debug --clean-after-build --binarysource=files,${VCPKG_CACHE},readwrite --triplet=x64-windows `
  gettext[tools]:x64-windows `
  icu:x64-windows-static-md `
  libxml2[tools,iconv,icu]:x64-windows-static-md `
  libxslt:x64-windows-static-md `
  lz4:x64-windows-static-md `
  openssl:x64-windows-static-md `
  pkgconf:x64-windows-static-md-release `
  readline-win32:x64-windows `
  zlib:x64-windows-static-md `
  zstd:x64-windows-static-md
if (!$?) { throw 'cmdfail' };

.\vcpkg.exe export --raw --output=pg-deps --x-all-installed
if (!$?) { throw 'cmdfail' };

7z.exe a -r pg-deps.7z .\pg-deps\*
if (!$?) { throw 'cmdfail' };

mv pg-deps.7z ..
