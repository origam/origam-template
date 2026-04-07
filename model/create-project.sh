#!/bin/bash

# Resolve the directory where this script is located
MODEL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Path to the composer binary (subfolder next to this script)
COMPOSER_DLL="$MODEL_DIR/origam-composer/Origam.Composer.dll"

# Output project will be created inside the model folder
PROJECT_FOLDER="$MODEL_DIR/MyOrigamApp"

dotnet "$COMPOSER_DLL" create \
  --commands-output-format cmd \
  --db-type mssql \
  --db-host host.docker.internal \
  --db-port 1433 \
  --db-name MyOrigamApp \
  --db-username sa \
  --db-password "yourStrong(!)Password" \
  --p-name MyOrigamApp \
  --p-folder "$PROJECT_FOLDER" \
  --p-admin-username admin \
  --p-admin-password 5axg1zr8 \
  --p-admin-email "loker2356@outlook.com" \
  --p-docker-image-linux "origam/server:2025.11.alpha.4051.linux" \
  --p-docker-image-win "origam/server:2025.11.alpha.4051.win" \
  --arch-docker-image-linux "origam/architect:2025.11.alpha.4051.linux" \
  --arch-docker-image-win "origam/architect:2025.11.alpha.4051.win" \
  --arch-port 8081 \
