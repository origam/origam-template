$ModelDir = $PSScriptRoot

$ConfigFile = if ($env:ORIGAM_CONFIG_FILE) { $env:ORIGAM_CONFIG_FILE } else { "/.env" }
if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}
Get-Content $ConfigFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $kv = $line -split "=", 2
        if ($kv.Length -eq 2) {
            Set-Item -Path ("Env:" + $kv[0].Trim()) -Value $kv[1].Trim()
        }
    }
}

$ComposerDir = Join-Path $ModelDir "origam-composer"
$ComposerExe = Join-Path $ComposerDir "Origam.Composer.exe"

$ProjectFolder = Join-Path $ModelDir $env:PROJECT_NAME

$ComposerArgs = @(
    "create",
    "--commands-output-format", "cmd",
    "--db-type", $env:DB_TYPE,
    "--db-host", $env:DB_HOST_WINDOWS,
    "--db-port", $env:DB_PORT,
    "--db-name", $env:DB_NAME,
    "--db-username", $env:DB_USERNAME,
    "--db-password", $env:DB_PASSWORD,
    "--p-name", $env:PROJECT_NAME,
    "--p-folder", $ProjectFolder,
    "--p-admin-username", $env:ADMIN_USERNAME,
    "--p-admin-password", $env:ADMIN_PASSWORD,
    "--p-admin-email", $env:ADMIN_EMAIL,
    "--p-docker-image-linux", $env:ORIGAM_SERVER_IMAGE_LINUX,
    "--p-docker-image-win", $env:ORIGAM_SERVER_IMAGE_WINDOWS,
    "--arch-docker-image-linux", $env:ORIGAM_ARCHITECT_IMAGE_LINUX,
    "--arch-docker-image-win", $env:ORIGAM_ARCHITECT_IMAGE_WINDOWS,
    "--arch-port", $env:ARCHITECT_PORT
)
if ($env:GIT_ENABLED -eq "true") {
    $ComposerArgs += "--git-enabled"
    $ComposerArgs += "--git-user", $env:GIT_USER
    $ComposerArgs += "--git-email", $env:GIT_EMAIL
}

& $ComposerExe @ComposerArgs
