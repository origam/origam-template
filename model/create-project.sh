set -e

MODEL_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_FILE="${ORIGAM_CONFIG_FILE:-/.env}"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Config file not found: $CONFIG_FILE" >&2
  exit 1
fi
set -a
. "$CONFIG_FILE"
set +a

COMPOSER_DLL="$MODEL_DIR/origam-composer/Origam.Composer.dll"

PROJECT_FOLDER="$MODEL_DIR/$PROJECT_NAME"

GIT_ARGS=()
if [ "${GIT_ENABLED:-false}" = "true" ]; then
  GIT_ARGS+=(--git-enabled --git-user "$GIT_USER" --git-email "$GIT_EMAIL")
fi

dotnet "$COMPOSER_DLL" create \
  --commands-output-format cmd \
  --db-type "$DB_TYPE" \
  --db-host "$DB_HOST_LINUX" \
  --db-port "$DB_PORT" \
  --db-name "$DB_NAME" \
  --db-username "$DB_USERNAME" \
  --db-password "$DB_PASSWORD" \
  --p-name "$PROJECT_NAME" \
  --p-folder "$PROJECT_FOLDER" \
  --p-admin-username "$ADMIN_USERNAME" \
  --p-admin-password "$ADMIN_PASSWORD" \
  --p-admin-email "$ADMIN_EMAIL" \
  --p-docker-image-linux "$ORIGAM_SERVER_IMAGE_LINUX" \
  --p-docker-image-win "$ORIGAM_SERVER_IMAGE_WINDOWS" \
  --arch-docker-image-linux "$ORIGAM_ARCHITECT_IMAGE_LINUX" \
  --arch-docker-image-win "$ORIGAM_ARCHITECT_IMAGE_WINDOWS" \
  --arch-port "$ARCHITECT_PORT" \
  "${GIT_ARGS[@]}"
