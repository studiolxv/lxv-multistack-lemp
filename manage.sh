#!/bin/sh
#####################################################
# SET DEBUG MODE
export debug_multistack=false
export debug_file_sourcing=false

# Get the current directory
export PROJECT_PATH=$(cd -- "$(dirname -- "$(realpath "$0" 2>/dev/null || readlink -f "$0")")" && pwd)

# Initialize the LEMP management system environment variables and functions
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

make_scripts_executable

# sh "${SCRIPTS_PATH}/docker/setup-docker.sh"
# wait
# sh "${SCRIPTS_PATH}/traefik/create-certificate-authority.sh"
# wait
# sh "${SCRIPTS_PATH}/traefik/setup-traefik.sh"
# wait
sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
