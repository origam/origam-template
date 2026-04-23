#!/bin/bash

set -e

if [ "${ORIGAM_PROJECT_BOOTSTRAP}" = "true" ]; then
  if [ -z "${PROJECT_NAME}" ]; then
    echo "PROJECT_NAME is required when ORIGAM_PROJECT_BOOTSTRAP=true"
    exit 1
  fi

  env_file="/model-src/${PROJECT_NAME}_Environments.env"

  echo "Waiting for ${PROJECT_NAME} to be generated..."
  while [ ! -f "$env_file" ]; do sleep 1; done

  echo "Linking project data..."
  mkdir -p /home/origam/projectData
  ln -sfn /model-src/model /home/origam/projectData/model
  ln -sfn /model-src/customAssets /home/origam/projectData/customAssets

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|\#*) continue ;; esac
    key=${line%%=*}
    value=${line#*=}
    export "$key=$value"
  done < "$env_file"
fi

if [ -x ./entrypoint.sh ]; then
  echo "1"
  exec ./entrypoint.sh
else
  echo "Could not find base entrypoint.sh (checked ./entrypoint.sh)"
  exit 127
fi
