#!/bin/bash
# Run by the origam-composer-linux service (docker-compose.yml) when CUSTOM_MODEL_PATH is set.
# On the first start the composer creates the database and the admin user in its own temporary folder from a copy of the model
# in CUSTOM_MODEL_PATH and deploys the active package (ACTIVE_PACKAGE_ID, Widgets by default) in one pass. Only the env file and
# customAssets/ are kept in the project folder. The server and Architect work directly with CUSTOM_MODEL_PATH/model.
set -euo pipefail

custom_dir=/custom-model
bundled_dir=/home/origam/Composer/model-root
project_dir=/model
composer_dir=/tmp/project
composer_log=/tmp/composer.log
root_menu_package_id=b9ab12fe-7f7d-43f7-bedc-93747647d6e4
widgets_package_id=f17329d6-3143-420a-a2e6-30e431eea51d
active_package_id=${ACTIVE_PACKAGE_ID:-}
active_package_id=${active_package_id,,}
package_name="${PROJECT_NAME//[[:space:]]/}"
env_file_name="${package_name}_Environments.env"
env_file="$project_dir/$env_file_name"
custom_model_marker=CUSTOM_MODEL=true
reset_hint="Run 'docker compose down -v' with the same variables set, delete customAssets/ and $env_file_name, then run again."

fail() {
  echo "Custom model: ERROR: $*" >&2
  exit 1
}

find_package_file() {
  grep -lsF "x:id=\"$2\"" "$1"/*/.origamPackage | head -n 1 || true
}

package_folder_name() {
  basename "$(dirname "$(find_package_file "$1" "$2")")"
}

list_packages() {
  for package_file in "$custom_dir"/model/*/.origamPackage; do
    echo "  $(grep -m 1 -o 'x:id="[^"]*"' "$package_file" | cut -d '"' -f 2)  $(basename "$(dirname "$package_file")")"
  done
}

require_active_package() {
  [ -n "$(find_package_file "$custom_dir/model" "$active_package_id")" ] \
    || fail "the model in CUSTOM_MODEL_PATH has no package with the id $active_package_id. Set ACTIVE_PACKAGE_ID to the id of one of these packages:
$(list_packages)"
}

set_active_package() {
  sed -i "s/^OrigamSettings__DefaultSchemaExtensionId=.*/OrigamSettings__DefaultSchemaExtensionId=$active_package_id/" "$env_file"
  echo "Custom model: the active package on the server is $(package_folder_name "$custom_dir/model" "$active_package_id") ($active_package_id)."
}

[ -d "$custom_dir/model" ] \
  || fail "CUSTOM_MODEL_PATH=$CUSTOM_MODEL_PATH must be a folder that contains model/ (for example the model-tests folder of the origam repository)."

if [ -f "$env_file" ]; then
  grep -q "^$custom_model_marker" "$env_file" \
    || fail "this project was not created with CUSTOM_MODEL_PATH, or it was created by an older version of this template. Start it without CUSTOM_MODEL_PATH, or start again from scratch: $reset_hint"
  if [ -z "$active_package_id" ]; then
    active_package_id=$(sed -n 's/^OrigamSettings__DefaultSchemaExtensionId=//p' "$env_file" | tr -d '\r')
  fi
  require_active_package
  set_active_package
  echo "Custom model: the project is already initialized, the server and Architect use the model in $CUSTOM_MODEL_PATH."
  exit 0
fi

active_package_id=${active_package_id:-$widgets_package_id}
require_active_package
[ ! -e "$custom_dir/model/$package_name" ] \
  || fail "the model in CUSTOM_MODEL_PATH already has a package folder model/$package_name. Choose a different PROJECT_NAME."

echo "Custom model: using the model from $CUSTOM_MODEL_PATH"
rm -rf "$bundled_dir/model" "$composer_dir"
cp -RL "$custom_dir/model" "$bundled_dir/model"
rm -f "$bundled_dir/model/index.bin" "$bundled_dir/model/RuntimeModelConfiguration.json"
for folder in l10n customAssets; do
  if [ -d "$custom_dir/$folder" ]; then
    rm -rf "${bundled_dir:?}/$folder"
    cp -RL "$custom_dir/$folder" "$bundled_dir/$folder"
    echo "Custom model: $folder/ taken from the custom model ($(find "$bundled_dir/$folder" -type f | wc -l) files)"
  else
    echo "Custom model: $folder/ not found in the custom model, the bundled one is used"
  fi
done

base_package_version=1.0.0
base_package_references=$active_package_id
root_menu_file=$(find_package_file "$bundled_dir/model" "$root_menu_package_id")
if [ -n "$root_menu_file" ]; then
  base_package_version=$(sed -n 's/.*p:version="\([^"]*\)".*/\1/p' "$root_menu_file" | head -n 1)
  renamed_root_menu_id=$(cat /proc/sys/kernel/random/uuid)
  grep -rlIZ "$root_menu_package_id" "$bundled_dir/model" | xargs -0 sed -i "s/$root_menu_package_id/$renamed_root_menu_id/g"
  base_package_references=$renamed_root_menu_id
  if [ "$active_package_id" != "$root_menu_package_id" ]; then
    base_package_references="$renamed_root_menu_id $active_package_id"
  fi
fi
base_package_reference_lines=""
for reference_id in $base_package_references; do
  base_package_reference_lines+="
    <pr:packageReference
      x:id=\"$(cat /proc/sys/kernel/random/uuid)\"
      pr:referencedPackage=\"$(package_folder_name "$bundled_dir/model" "$reference_id")/.origamPackage#$reference_id\" />"
done
mkdir "$bundled_dir/model/_ComposerBasePackage"
cat > "$bundled_dir/model/_ComposerBasePackage/.origamPackage" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<x:file
  xmlns:x="http://schemas.origam.com/model-persistence/1.0.0"
  xmlns:p="http://schemas.origam.com/Origam.Schema.Package/6.1.0"
  xmlns:pr="http://schemas.origam.com/Origam.Schema.PackageReference/6.0.0">
  <p:package
    x:id="$root_menu_package_id"
    x:isFolder="true"
    p:name="_ComposerBasePackage"
    p:version="$base_package_version">$base_package_reference_lines
  </p:package>
</x:file>
EOF

"$@" | tee "$composer_log" || true

grep -q "All steps completed" "$composer_log" \
  || fail "Composer did not create the project, see its messages above (for example the database already exists). $reset_hint"
[ -f "$composer_dir/$env_file_name" ] || fail "Composer did not write $env_file_name. $reset_hint"

cat "$composer_dir/$env_file_name" > "$env_file"
printf '\n%s\n' "$custom_model_marker" >> "$env_file"
if [ ! -d "$project_dir/customAssets" ]; then
  cp -R "$composer_dir/customAssets" "$project_dir/customAssets"
  chmod -R g+rwX "$project_dir/customAssets"
fi
set_active_package

echo "Custom model: project created, check the Composer messages above for errors. The server and Architect use the model in $CUSTOM_MODEL_PATH directly, keep CUSTOM_MODEL_PATH set on every start."
