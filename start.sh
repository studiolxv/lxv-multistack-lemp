#!/bin/sh
# Initialize the LEMP management system environment variables and functions
export PROJECT_PATH=$(cd -- "$(dirname -- "$(realpath "$0" 2>/dev/null || readlink -f "$0")")" && pwd)
export PROJECT_NAME="$(basename "$PROJECT_PATH")"
export PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
export PROJECT_ENV_FILE="${PROJECT_ROOT}/.env"
. ./_env-setup.sh
# debug_file_msg "$(current_basename)"

if ! docker_ready; then
    if [ ! is_docker_desktop_app_open ] || [ "${opt_open_docker_on_start}" = true ]; then
        sh "${SCRIPTS_PATH}/docker/start-docker.sh"
    fi
fi

if wait_for_docker_daemon_ready; then
    if [ ! -n "${MKCERT_CA_INSTALLED}" ] && [ ! "${MKCERT_CA_INSTALLED}" = true ]; then
        sh "${SCRIPTS_PATH}/traefik/mkcert-certificate-authority.sh"
    fi
    if [ ! -n "${TRAEFIK_SETUP}" ] && [ ! "${TRAEFIK_SETUP}" = true ]; then
        sh "${SCRIPTS_PATH}/traefik/setup-traefik.sh"
    fi
    if ! is_docker_compose_running "${TRAEFIK_DOCKER_YML_FILE}"; then
        sh "${SCRIPTS_PATH}/traefik/deploy-traefik.sh"
    fi
fi

wait
sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
