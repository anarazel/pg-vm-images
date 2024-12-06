# Install packages via vcpkg

param (
  [switch]$GenerateCacheTask = $false
)

# param() should be the first thing in the script file,
# so ErrorActionPreference is defined here
$ErrorActionPreference = "Stop"

Function InstallVcpkgPackages()
{
  param (
    [string]$VCPKG_PATH,
    [string]$VCPKG_CACHE
  )

  # If the VCPKG_PATH or VCPKG_CACHE is not provided, try to get it from the environment
  if (! ($VCPKG_PATH))
  {
    $VCPKG_PATH = ${Env:VCPKG_PATH}
  }
  if (! ($VCPKG_CACHE))
  {
    $VCPKG_CACHE = ${Env:VCPKG_CACHE}
  }

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
}

Function InstallAndPrepareImage()
{
  $VCPKG_PATH = "c:\vcpkg"
  $ARTIFACT_NAME = "pg-deps.7z"
  $ARTIFACT_URL = "https://api.cirrus-ci.com/v1/artifact/build/${ENV:CIRRUS_BUILD_ID}/build-vcpkg-cache/vcpkg_cache_zip/${ARTIFACT_NAME}"

  echo "Downloading ${ARTIFACT_URL}"
  curl.exe -fsSLO ${ARTIFACT_URL}
  if (!$?) { throw 'cmdfail' };

  echo "Extracting the vcpkg zip from prior task"
  7z.exe x ${ARTIFACT_NAME} -o"${VCPKG_PATH}"
  if (!$?) { throw 'cmdfail' };

  ls $VCPKG_PATH

  $VCPKG_PKG_PREFIX = "${VCPKG_PATH}\installed";
  $PATHS =
    "${VCPKG_PKG_PREFIX}\x64-windows-release\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows\debug\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md-release\tools\pkgconf;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-release\tools\krb5\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows\tools\gettext\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\tools\libxml2\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\tools\libxslt\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\tools\zstd\bin;"
  ;

  $PKG_CONFIG_PATHS =
    "${VCPKG_PKG_PREFIX}\x64-windows-release\lib\pkgconfig;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\debug\lib\pkgconfig;" +
    "${VCPKG_PKG_PREFIX}\x64-windows\debug\lib\pkgconfig;"
  ;

  # Export env variables to use them easily in Postgres CI
  [Environment]::SetEnvironmentVariable('PG_DEPS_PATH', ${PATHS}, 'Machine');
  [Environment]::SetEnvironmentVariable('PG_DEPS_PKG_CONFIG', 'pkgconf', 'Machine');
  [Environment]::SetEnvironmentVariable('PG_DEPS_PKG_CONFIG_PATH', ${PKG_CONFIG_PATHS}, 'Machine');
  [Environment]::SetEnvironmentVariable('PG_DEPS_EXTRA_INCLUDE_DIRS', "${VCPKG_PKG_PREFIX}\x64-windows\include", 'Machine');
  [Environment]::SetEnvironmentVariable('PG_DEPS_EXTRA_LIB_DIRS', "${VCPKG_PKG_PREFIX}\x64-windows\debug\lib", 'Machine');
}

Function Main()
{
  if ($GenerateCacheTask)
  {
    InstallVcpkgPackages
  }
  else
  {
    InstallAndPrepareImage
  }
}

Main
