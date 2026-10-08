#!/bin/bash
# Run by the origam-composer-linux service (docker-compose.yml) when CUSTOM_MODEL_PATH is set.
# Creates the new project from the model in CUSTOM_MODEL_PATH instead of the model bundled in the composer image.
# The server and Architect then work directly with CUSTOM_MODEL_PATH/model, with Root Menu as the active package.
set -euo pipefail

custom_dir=/custom-model
bundled_dir=/home/origam/Composer/model-root
project_dir=/model
root_menu_package_id=b9ab12fe-7f7d-43f7-bedc-93747647d6e4
package_name="${PROJECT_NAME//[[:space:]]/}"
package_file="$project_dir/model/$package_name/.origamPackage"
env_file="$project_dir/${package_name}_Environments.env"
reset_hint="Run 'docker compose down -v' with the same variables set, delete model/, l10n/, customAssets/, origam-project.json and ${package_name}_Environments.env, then run again."

fail() {
  echo "Custom model: ERROR: $*" >&2
  exit 1
}

[ -d "$custom_dir/model" ] \
  || fail "CUSTOM_MODEL_PATH=$CUSTOM_MODEL_PATH must be a folder that contains model/ (for example the model-tests folder of the origam repository)."

if [ -n "$(ls -A "$project_dir/model" 2>/dev/null)" ]; then
  if [ ! -f "$package_file" ]; then
    fail "model/ is not empty but model/$package_name is missing, so an earlier initialization did not finish (or used another PROJECT_NAME). $reset_hint"
  fi
  [ -f "$env_file" ] || fail "${package_name}_Environments.env is missing. $reset_hint"
  active_package_id=$(sed -n 's/^OrigamSettings__DefaultSchemaExtensionId=//p' "$env_file" | tr -d '\r')
  [ "$active_package_id" = "$root_menu_package_id" ] \
    || fail "this project was not created with CUSTOM_MODEL_PATH (its active package is $active_package_id). Start it without CUSTOM_MODEL_PATH."
  grep -q "x:id=\"$root_menu_package_id\"" "$custom_dir"/model/*/.origamPackage \
    || fail "CUSTOM_MODEL_PATH=$CUSTOM_MODEL_PATH has no Root Menu package. Set it to the model folder this project was created with."
  echo "Custom model: the project is already initialized, the server and Architect use the model in $CUSTOM_MODEL_PATH."
  exec "$@"
fi

grep -q "x:id=\"$root_menu_package_id\"" "$custom_dir"/model/*/.origamPackage \
  || fail "the model in CUSTOM_MODEL_PATH does not contain the Root Menu package ($root_menu_package_id)."
[ ! -e "$custom_dir/model/$package_name" ] \
  || fail "the model in CUSTOM_MODEL_PATH already has a package folder model/$package_name. Choose a different PROJECT_NAME."

echo "Custom model: using the model from $CUSTOM_MODEL_PATH"
rm -rf "$bundled_dir/model"
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

"$@"

[ -f "$package_file" ] \
  || fail "Composer did not create the project, see its messages above (for example the database already exists). $reset_hint"

[ -f "$env_file" ] || fail "Composer did not write ${package_name}_Environments.env. $reset_hint"
sed -i "s/^OrigamSettings__DefaultSchemaExtensionId=.*/OrigamSettings__DefaultSchemaExtensionId=$root_menu_package_id/" "$env_file"

echo "Custom model: project created, check the Composer messages above for errors. The server and Architect use the model in $CUSTOM_MODEL_PATH directly with Root Menu as the active package, keep CUSTOM_MODEL_PATH set on every start."
