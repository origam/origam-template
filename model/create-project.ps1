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

# Grant CREATE on public schema (required for PostgreSQL 15+)
if ($env:DB_TYPE -eq "postgres") {
    $dbHost = $env:DB_HOST_WINDOWS
    if (-not $dbHost) { $dbHost = $env:DB_HOST_LINUX }
    try {
        Add-Type -Path (Join-Path $ModelDir "origam-composer\Npgsql.dll")
        $connStr = "Host=$dbHost;Port=$($env:DB_PORT);Username=$($env:DB_USERNAME);Password=$($env:DB_PASSWORD);Database=template1"
        $conn = New-Object Npgsql.NpgsqlConnection($connStr)
        $conn.Open()
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "GRANT ALL ON SCHEMA public TO PUBLIC"
        $cmd.ExecuteNonQuery() | Out-Null
        $conn.Close()
        Write-Host "Granted CREATE on public schema (template1) for PostgreSQL 15+ compatibility."
    } catch {
        Write-Warning "Could not apply GRANT on template1: $_. Ensure the postgres user has CREATE rights on schema public."
    }
}

$ComposerDir = Join-Path $ModelDir "origam-composer"
$ComposerExe = Join-Path $ComposerDir "Origam.Composer.exe"

# Use a local temp folder for Composer output (avoids volume mount write issues)
$TempProjectFolder = "C:\temp\$($env:PROJECT_NAME)"
$FinalProjectFolder = Join-Path $ModelDir $env:PROJECT_NAME

# Clean up any previous temp folder
if (Test-Path $TempProjectFolder) {
    Remove-Item -Recurse -Force $TempProjectFolder
}

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
    "--p-folder", $TempProjectFolder,
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

if ($LASTEXITCODE -ne 0) {
    Write-Error "Composer failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

# Copy results from temp to the volume mount
Write-Host "Copying project files to volume mount..."
if (Test-Path $TempProjectFolder) {
    if (Test-Path $FinalProjectFolder) {
        Remove-Item -Recurse -Force $FinalProjectFolder
    }
    Copy-Item -Path $TempProjectFolder -Destination $FinalProjectFolder -Recurse -Force
    Write-Host "Project files copied to $FinalProjectFolder"
} else {
    Write-Warning "Temp project folder not found: $TempProjectFolder"
}
