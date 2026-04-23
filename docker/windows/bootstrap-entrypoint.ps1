#!/usr/bin/env pwsh
param(
    [string]$EntryPointDir = 'C:\home\origam',
    [switch]$CopyTemplate
)

$ErrorActionPreference = 'Stop'

if ($env:ORIGAM_PROJECT_BOOTSTRAP -eq 'true') {
    if (-not $env:PROJECT_NAME) {
        Write-Error 'PROJECT_NAME is required when ORIGAM_PROJECT_BOOTSTRAP=true'
        exit 1
    }

    $envFile = "C:\model-src\$($env:PROJECT_NAME)_Environments.env"

    Write-Host "Waiting for $($env:PROJECT_NAME) to be generated..."
    while (-not (Test-Path $envFile)) { Start-Sleep -Seconds 1 }

    Write-Host 'Linking project data...'
    $dataPath = 'C:\home\origam\projectData'
    New-Item -ItemType Directory -Path $dataPath -Force | Out-Null

    function New-Link {
        param([string]$Path, [string]$Target)
        if (Test-Path $Path) { Remove-Item -Recurse -Force $Path }
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
    }

    New-Link -Path "$dataPath\model" -Target 'C:\model-src\model'
    if (Test-Path 'C:\model-src\customAssets') {
        New-Link -Path "$dataPath\customAssets" -Target 'C:\model-src\customAssets'
    }

    Get-Content $envFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#')) {
            $kv = $line -split '=', 2
            if ($kv.Length -eq 2) {
                [Environment]::SetEnvironmentVariable($kv[0].Trim(), $kv[1].Trim(), 'Process')
            }
        }
    }

    [Environment]::SetEnvironmentVariable('CustomAssetsConfig__PathToCustomAssetsFolder', "$dataPath\customAssets", 'Process')
}

if ($CopyTemplate) {
    Write-Host 'Copying template file...'
    Copy-Item "$EntryPointDir\_OrigamSettings.template" 'C:\home\origam\_OrigamSettings.template' -Force
}

Set-Location $EntryPointDir
if (Test-Path '.\EntryPoint.ps1') {
    Write-Host 'Starting EntryPoint.ps1...'
    & .\EntryPoint.ps1
} else {
    Write-Error "Could not find base EntryPoint.ps1 (checked $EntryPointDir\EntryPoint.ps1)"
    exit 127
}
