$ErrorActionPreference = "Stop"

$GITHUB_TOKEN = $Env:GITHUB_TOKEN
if (-not $GITHUB_TOKEN) {
    throw "GITHUB_TOKEN cannot be read, exiting"
}

$PG_DEPS_DIR = "C:\PG_WINPGBUILD_DEPS"
$BASE_API_URL = "https://api.github.com/repos/dpage/winpgbuild/actions"
$WORKFLOW = "bundle-deps"

function DownloadDependencies()
{
    # Get the latest successful run ID
    $runApiUrl = "${BASE_API_URL}/workflows/${WORKFLOW}.yml/runs?status=completed&conclusion=success&per_page=1"
    $runResponse = curl.exe -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" $runApiUrl
    if (!$?) { throw 'cmdfail' }

    $runJson = $runResponse | ConvertFrom-Json
    if (-not $runJson.workflow_runs -or $runJson.workflow_runs.Count -eq 0) {
        throw "There is no successful run for $WORKFLOW workflow"
    }
    $RUN_ID = $runJson.workflow_runs[0].id
    echo "Run_ID: $RUN_ID"

    # Get the artifact ID
    $artifactApiUrl = "${BASE_API_URL}/runs/$RUN_ID/artifacts"
    $artifactResponse = curl.exe -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" $artifactApiUrl
    if (!$?) { throw 'cmdfail' }

    $artifactJson = $artifactResponse | ConvertFrom-Json
    $ARTIFACT_ID = ($artifactJson.artifacts | Where-Object { $_.name -match "win64$" } | Select-Object -First 1).id
    if (-not $ARTIFACT_ID) {
        throw "Artifact is not found in run $RUN_ID for workflow '$WORKFLOW'"
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
    if (!$?) {
        throw "Extraction failed: 7z.exe exited with code $LASTEXITCODE"
    }

    Remove-Item "$WORKFLOW.zip" -Force
    dir $PG_DEPS_DIR
}

DownloadDependencies
InstallDependencies
