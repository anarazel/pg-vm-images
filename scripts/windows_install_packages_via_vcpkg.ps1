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
  # Build krb5 only in release, the debug variant has a lot of debug output,
  # causing test failures.
  #
  # Build many libraries in static mode, dynamic linking slows the tests down.
  #
  # Build readline dynamically, at least for distribution doing otherwise
  # might be problematic?
  #
  # ICU: ?
  # TCL: ?
  .\vcpkg.exe install @("${VCPKG_FLAGS}".Split(" ")) `
    gettext[tools]:x64-windows-static-md `
    krb5:x64-windows-rel `
    icu:x64-windows-static-md `
    libxml2[tools,iconv,icu]:x64-windows-static-md `
    libxslt:x64-windows-static-md `
    lz4:x64-windows-static-md `
    openssl:x64-windows-static-md `
    pkgconf:x64-windows-static-md-release `
    readline-win32:x64-windows `
    tcl `
    zlib:x64-windows-static-md `
    zstd:x64-windows-static-md
  if (!$?) { throw 'cmdfail' };

  .\vcpkg.exe export --raw --output=pg-deps --x-all-installed
  if (!$?) { throw 'cmdfail' };

  7z.exe a -r pg-deps.7z pg-deps
  if (!$?) { throw 'cmdfail' };

  mv pg-deps.7z ..
  ls -l ..
}

Function InstallAndPrepareImage()
{
  #$CIRRUS_BUILD_ID = ${Env:CIRRUS_BUILD_ID}

  $VCPKG_PATH = "c:\vcpkg";
  $ARTIFACT_NAME = "pg-deps.7z";
  #$REPO_NAME = $ENV:CIRRUS_REPO_FULL_NAME;
  #$BRANCH_NAME = $ENV:CIRRUS_BRANCH;
  # It's tempting to use the URL below, to allow skipping the task to build vcpkg,
  # but unfortunately a skipped task "hides" prior results, making it useless.
  #$ARTIFACT_URL = "https://api.cirrus-ci.com/v1/artifact/github/${ENV:CIRRUS_REPO_FULL_NAME}/build-vcpkg-cache/vcpkg_cache_zip/${ARTIFACT_NAME}?branch=${ENV:CIRRUS_BRANCH}";
  $ARTIFACT_URL = "https://api.cirrus-ci.com/v1/artifact/build/${ENV:CIRRUS_BUILD_ID}/build-vcpkg-cache/vcpkg_cache_zip/${ARTIFACT_NAME}"

  echo "Downloading  ${ARTIFACT_URL}"
  curl.exe -fsSLO ${ARTIFACT_URL}
  if (!$?) { throw 'cmdfail' };

  echo "Extracting the cache"
  7z.exe x ${ARTIFACT_NAME} -o"$VCPKG_PATH"
  if (!$?) { throw 'cmdfail' };

  ls $VCPKG_PATH
  # there got to be a better way to avoid this top-level dir
  mv C:\vcpkg\pg-deps\* C:\vcpkg\
  rmdir C:\vcpkg\pg-deps
  ls $VCPKG_PATH


  $VCPKG_PKG_PREFIX = "${VCPKG_PATH}\installed";
  $ADD_TO_PATH =
    "${VCPKG_PKG_PREFIX}\x64-windows-release\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows\debug\bin" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md-release\tools\pkgconf;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\tools\gettext\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\tools\libxml2\bin;" +
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\tools\libxslt\bin;"
  ;

  $PKG_CONFIG_PATHS =
    "${VCPKG_PKG_PREFIX}\x64-windows-release\lib\pkgconfig;"
    "${VCPKG_PKG_PREFIX}\x64-windows-static-md\debug\lib\pkgconfig;" +
    "${VCPKG_PKG_PREFIX}\x64-windows\debug\lib\pkgconfig;"
  ;


  $p=[Environment]::GetEnvironmentVariable('PATH', 'Machine');
  echo "old env: $p";

  [Environment]::SetEnvironmentVariable('PATH', ${ADD_TO_PATH} + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine');
  [Environment]::SetEnvironmentVariable('PKG_CONFIG', 'pkgconf', 'Machine');
  [Environment]::SetEnvironmentVariable('PKG_CONFIG_PATH', $PKG_CONFIG_PATHS, 'Machine');

  $p=[Environment]::GetEnvironmentVariable('PATH', 'Machine');
  echo "new env: $p";
}

Function InstallAndPrepareImageOld()
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
    "${VCPKG_PKG_PREFIX}\tools\pkgconf;";

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
