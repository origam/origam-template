# Resolve the directory where this script is located
$ModelDir = $PSScriptRoot

# Path to the composer binary (subfolder next to this script)
$ComposerDir = Join-Path $ModelDir "origam-composer"
$ComposerExe = Join-Path $ComposerDir "Origam.Composer.exe"

# Output project will be created inside the model folder
$ProjectFolder = Join-Path $ModelDir "MyOrigamApp"

& $ComposerExe create `
  --commands-output-format cmd `
  --db-type mssql `
  --db-host localhost `
  --db-port 1433 `
  --db-name MyOrigamApp `
  --db-username sa `
  --db-password "yourStrong(!)Password" `
  --p-name MyOrigamApp `
  --p-folder "$ProjectFolder" `
  --p-admin-username admin `
  --p-admin-password 5axg1zr8 `
  --p-admin-email "loker2356@outlook.com" `
  --p-docker-image-linux "origam/server:2025.11.alpha.4051.linux" `
  --p-docker-image-win "origam/server:2025.11.alpha.4051.win" `
  --arch-docker-image-linux "origam/architect:2025.11.alpha.4051.linux" `
  --arch-docker-image-win "origam/architect:2025.11.alpha.4051.win" `
  --arch-port 8081 `
  --git-enabled
