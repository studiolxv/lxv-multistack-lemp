#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# MAKE CONTAINERS DIRECTORY
section_title "LEMP DIRECTORY"

generating_msg "Creating LEMP directory structure..."
line_break
# CREATE STACK DIRECTORY and CONTAINERS DIRECTORY
mkdir -p "${LEMP_CONTAINERS_PATH}"

#####################################################
# MAKE LOGS DIRECTORY
mkdir -p "${LOG_PATH}"

#####################################################
# COPY SCRIPT FILES
mkdir -p "${BACKUPS_SCRIPTS_PATH}" && cp -r "${PROJECT_PATH}/templates/lemp-scripts/"* "${BACKUPS_SCRIPTS_PATH}/"

# EXEC SCRIPT PERMISSIONS
find "${BACKUPS_SCRIPTS_PATH}" -type f -name "*.sh" -exec chmod +x {} +

#####################################################
# COPY DOCKER COMPOSE FILE
LEMP_DOCKER_COMPOSE_YML="${LEMP_PATH}/docker-compose.yml"
cp "${PROJECT_PATH}/templates/lemp-docker-compose.yml" "${LEMP_DOCKER_COMPOSE_YML}"
# Replace variables in the docker-compose.yml file
search_file_replace "${LEMP_PATH}/docker-compose.yml" "<<LEMP_NETWORK_NAME>>" "${LEMP_NETWORK_NAME}"

#####################################################
# EXPORTS
export LEMP_DOCKER_COMPOSE_YML

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-5-directory-public.sh"
