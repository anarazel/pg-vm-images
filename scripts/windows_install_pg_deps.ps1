$ErrorActionPreference = "Stop"

function DownloadAndInstallDependency($DependencyName, $SourceUri)
{
    echo "downloading $($DependencyName)"
    curl.exe -fsSL -o "c:\$($DependencyName).zip" $SourceUri;
    if (!$?) { throw 'cmdfail' }

    echo "installing $($DependencyName)"
    7z.exe x "c:\$($DependencyName).zip" -o"c:\$($DependencyName)"
    if (!$?) { throw 'cmdfail' }
    Remove-Item "c:\$($DependencyName).zip" -Force
}

DownloadAndInstallDependency "icu" "https://github.com/unicode-org/icu/releases/download/release-77-1/icu4c-77_1-Win64-MSVC2022.zip";
DownloadAndInstallDependency "lz4" "https://github.com/lz4/lz4/releases/download/v1.9.3/lz4_win64_v1_9_3.zip";
DownloadAndInstallDependency "zlib" "http://gnuwin32.sourceforge.net/downlinks/zlib-lib-zip.php";
DownloadAndInstallDependency "zstd" "https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-v1.5.2-win64.zip";

[Environment]::SetEnvironmentVariable('PATH',  'C:\winflexbison;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
[Environment]::SetEnvironmentVariable('PATH',  'C:\icu;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
[Environment]::SetEnvironmentVariable('PATH',  'C:\lz4;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
[Environment]::SetEnvironmentVariable('PATH',  'C:\zlib;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
[Environment]::SetEnvironmentVariable('PATH',  'C:\zstd\zstd-v1.5.2-win64;' + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
