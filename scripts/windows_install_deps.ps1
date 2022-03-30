$ErrorActionPreference = "Stop"

function DownloadDependency($DependencyName, $SourceUri)
{
    echo "downloading $($DependencyName)"
    curl.exe -sSL -o "c:\$($DependencyName).zip" $SourceUri;
    if (!$?) { throw 'cmdfail' }
}

function InstallDependency($DependencyName)
{
    echo "installing $($DependencyName)"
    7z.exe e "c:\$($DependencyName).zip" -o"c:\$($DependencyName)"
    if (!$?) { throw 'cmdfail' }
    Remove-Item "c:\$($DependencyName).zip" -Force
}


DownloadDependency "icu" "https://github.com/unicode-org/icu/releases/download/release-70-1/icu4c-70_1-Win64-MSVC2019.zip";
InstallDependency "icu";

DownloadDependency "lz4" "https://github.com/lz4/lz4/releases/download/v1.9.3/lz4_win64_v1_9_3.zip";
InstallDependency "lz4";

DownloadDependency "zstd" "https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-v1.5.2-win64.zip";
InstallDependency "zstd";
