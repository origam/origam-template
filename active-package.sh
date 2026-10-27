#!/bin/bash
# Run by the origam-server-linux service (docker-compose.yml) instead of the entrypoint of the server image.
# Without CUSTOM_MODEL_PATH the server works with the package that is built on top of the active package from
# <PROJECT_NAME>_Environments.env: the one package that references it, directly or through other packages, and that
# no other such package references. A package created with New Package in Architect gets there once it references
# the <PROJECT_NAME> package or the package created before it. The env file is not changed. With CUSTOM_MODEL_PATH
# the active package is chosen by ACTIVE_PACKAGE_ID (custom-model.sh).
set -e

. /home/origam/server_bin/bootstrap.sh

if [ "${ORIGAM_PROJECT_BOOTSTRAP}" = "true" ] && [ "${CUSTOM_MODEL}" != "true" ]; then
  base_package_id=$(printf '%s' "$OrigamSettings__DefaultSchemaExtensionId" | tr -d '\r' | tr '[:upper:]' '[:lower:]')
  declare -A package_names package_references
  for package_file in /model-src/model/*/.origamPackage; do
    package_id=$(grep -m 1 -o 'x:id="[^"]*"' "$package_file" | cut -d '"' -f 2 | tr '[:upper:]' '[:lower:]')
    [ -n "$package_id" ] || continue
    package_names[$package_id]=$(basename "$(dirname "$package_file")")
    package_references[$package_id]=$(grep -o 'referencedPackage="[^"]*"' "$package_file" \
      | sed 's/.*#//; s/"$//' | tr '[:upper:]' '[:lower:]' | tr '\n' ' ')
  done

  declare -A visited_packages
  includes_base_package() {
    local reference_id
    for reference_id in ${package_references[$1]}; do
      if [ "$reference_id" = "$base_package_id" ]; then
        return 0
      fi
      if [ -z "${visited_packages[$reference_id]}" ]; then
        visited_packages[$reference_id]=1
        if includes_base_package "$reference_id"; then
          return 0
        fi
      fi
    done
    return 1
  }

  built_on_base=()
  for package_id in "${!package_names[@]}"; do
    visited_packages=()
    if includes_base_package "$package_id"; then
      built_on_base+=("$package_id")
    fi
  done
  top_packages=()
  for package_id in "${built_on_base[@]}"; do
    referenced=false
    for other_id in "${built_on_base[@]}"; do
      case " ${package_references[$other_id]} " in *" $package_id "*) referenced=true ;; esac
    done
    if [ "$referenced" = false ]; then
      top_packages+=("$package_id")
    fi
  done

  base_package_name=${package_names[$base_package_id]:-$base_package_id}
  if [ ${#top_packages[@]} -eq 1 ]; then
    export OrigamSettings__DefaultSchemaExtensionId=${top_packages[0]}
    echo "Active package: ${package_names[${top_packages[0]}]} (${top_packages[0]}), built on $base_package_name."
  elif [ ${#top_packages[@]} -gt 1 ]; then
    top_package_names=$(for package_id in "${top_packages[@]}"; do echo "${package_names[$package_id]}"; done | sort | paste -sd ',' | sed 's/,/, /g')
    echo "Active package: $base_package_name. Several packages are built on it and none of them references the others: $top_package_names. Make one of them reference the others to use it." >&2
  else
    echo "Active package: $base_package_name."
  fi
fi

export ORIGAM_PROJECT_BOOTSTRAP=false
cd /home/origam/server_bin
exec ./entrypoint.sh
