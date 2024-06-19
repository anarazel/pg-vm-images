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

  $VCPKG_FLAGS = "--debug --binarysource=files,${VCPKG_CACHE},readwrite --triplet=x64-windows"

  if (! ($GenerateCacheTask))
  {
    $VCPKG_FLAGS += " --clean-after-build"
  }

  cd ${VCPKG_PATH}
  .\bootstrap-vcpkg.bat -disableMetrics
  .\vcpkg.exe install @("${VCPKG_FLAGS}".Split(" ")) `
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
}

Function InstallAndPrepareImage()
{
  $VCPKG_PATH = "c:\vcpkg"
  $VCPKG_CACHE_PATH = "${VCPKG_PATH}\binary_cache\"
  $CIRRUS_BUILD_ID = ${Env:CIRRUS_BUILD_ID}

  vcvarsall.bat x64
  git clone --depth 1 https://github.com/Microsoft/vcpkg.git "${VCPKG_PATH}"
  cd "${VCPKG_PATH}"

  mkdir -p binary_cache, downloads
  $ARTIFACT_NAME = "vcpkg_cache.zip"
  $ARTIFACT_URL = "https://api.cirrus-ci.com/v1/artifact/build/${CIRRUS_BUILD_ID}/build-vcpkg-cache/vcpkg_cache_zip/${ARTIFACT_NAME}"

  echo "Downloading  ${ARTIFACT_URL}"
  curl.exe -fsSLO ${ARTIFACT_URL}
  if (!$?) { throw 'cmdfail' };

  echo "Extracting the cache"
  7z.exe x ${ARTIFACT_NAME} -o"${VCPKG_CACHE_PATH}"
  if (!$?) { throw 'cmdfail' };

  echo "Installing packages via vcpkg"
  InstallVcpkgPackages $VCPKG_PATH $VCPKG_CACHE_PATH

  dir
  (du -sh *) -or $true
  (find . -name '*.exe' -or -name '*.pc') -or $true

  $VCPKG_PKG_PREFIX = "${VCPKG_PATH}\installed\x64-windows"

  $PKG_PATHS = "${VCPKG_PKG_PREFIX}\debug\lib;" +
    "${VCPKG_PKG_PREFIX}\debug\bin;" +
    "${VCPKG_PKG_PREFIX}\tools\pkgconf;" +

  [Environment]::SetEnvironmentVariable('PATH', ${PKG_PATHS} + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
  [Environment]::SetEnvironmentVariable('PKG_CONFIG', 'pkgconf', 'Machine')
  [Environment]::SetEnvironmentVariable('PKG_CONFIG_PATH', "${VCPKG_PATH}\installed\x64-windows\debug\lib\pkgconfig", 'Machine')
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
