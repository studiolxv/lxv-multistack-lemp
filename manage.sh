#!/bin/sh
export PROJECT_PATH=$(cd -- "$(dirname -- "$(realpath "$0" 2>/dev/null || readlink -f "$0")")" && pwd)
export PROJECT_NAME="$(basename "$PROJECT_PATH")"
export PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
export PROJECT_ENV_FILE="${PROJECT_ROOT}/.env"
. "${PROJECT_ENV_FILE}"
wait
# debug_file_msg "$(current_basename)"

# sh "${SCRIPTS_PATH}/docker/setup-docker.sh"
# wait
# sh "${SCRIPTS_PATH}/traefik/create-certificate-authority.sh"
# wait
# sh "${SCRIPTS_PATH}/traefik/setup-traefik.sh"
# wait
sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
