$ErrorActionPreference = "Stop"

$GITHUB_TOKEN = $Env:GITHUB_TOKEN
if (-not $GITHUB_TOKEN) {
    echo "GITHUB_TOKEN can't be read, exiting"
    exit 1
}

$PG_DEPS_DIR = "C:\PG_DEPS"
$BASE_API_URL = "https://api.github.com/repos/dpage/winpgbuild/actions"
$WORKFLOW = "bundle-deps"

function DownloadDependencies()
{
    # Get the latest successful run ID
    $runApiUrl = "${BASE_API_URL}/workflows/${WORKFLOW}.yml/runs?status=completed&conclusion=success&per_page=1"
    $runResponse = curl.exe -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" $runApiUrl
    if (!$?) { throw 'cmdfail' }

    $RUN_ID = ($runResponse | ConvertFrom-Json).workflow_runs[0].id
    if (-not $RUN_ID) {
        echo "There is no successful run for $WORKFLOW workflow"
        exit 1
    } else {
        echo "Run_ID: $RUN_ID"
    }

    # Get the artifact ID
    $artifactApiUrl = "${BASE_API_URL}/runs/$RUN_ID/artifacts"
    $artifactResponse = curl.exe -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" $artifactApiUrl
    if (!$?) { throw 'cmdfail' }

    $artifactJson = $artifactResponse | ConvertFrom-Json
    $ARTIFACT_ID = ($artifactJson.artifacts | Where-Object { $_.name -match "win64$" }).id
    if (-not $ARTIFACT_ID) {
        echo "Artifact is not found in run $RUN_ID for workflow '$WORKFLOW'"
        exit 1
    } else {
        echo "Artifact_ID: $ARTIFACT_ID"
    }

    # Download the artifact ZIP
    $downloadUrl = "${BASE_API_URL}/artifacts/$ARTIFACT_ID/zip"
    curl.exe -L -H "Authorization: token $GITHUB_TOKEN" -o "$WORKFLOW.zip" $downloadUrl
    if (!$?) { throw 'cmdfail' }

    echo "$WORKFLOW.zip is downloaded"
}

function InstallDependencies()
{
    echo "Installing dependencies to $PG_DEPS_DIR"

    7z.exe x "$WORKFLOW.zip" -o"$PG_DEPS_DIR"
    [Environment]::SetEnvironmentVariable('PATH',  "${PG_DEPS_DIR};" + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
    [Environment]::SetEnvironmentVariable('PATH',  "${PG_DEPS_DIR}\bin;" + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')
    [Environment]::SetEnvironmentVariable('PATH',  "${PG_DEPS_DIR}\bin64;" + [Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Machine')

    dir $PG_DEPS_DIR
}

DownloadDependencies
InstallDependencies
