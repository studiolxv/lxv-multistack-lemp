#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# SOURCE LEMP STACK .ENV

if [[ -z "${STACK_NAME}" ]]; then
	warning_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	# Select a LEMP stack using the new function, defines ${STACK_NAME}
	select_lemp_stack
else
	debug_success_msg "${C_Yellow}\$STACK_NAME${C_Reset} is defined as '${C_Yellow}${STACK_NAME}${C_Reset}'. Proceeding..."
fi

source_lemp_stack_env ${STACK_NAME}

#####################################################
# NEW DIRECTORIES

# Create WordPress container directory
mkdir -p "${WORDPRESS_PATH}"
chmod -R 755 "${WORDPRESS_PATH}"

mkdir -p "${WORDPRESS_PUBLIC_PATH}"
chmod -R 755 "${WORDPRESS_PUBLIC_PATH}"

mkdir -p "${WORDPRESS_SECRETS_PATH}"
chmod -R 755 "${WORDPRESS_SECRETS_PATH}"

#####################################################
# COPY WORDPRESS DOCKER FILE TEMPLATE
# Builds wordpress-latest with SoapClient
cp "${PROJECT_PATH}/templates/wordpress-Dockerfile" "$WORDPRESS_PATH/Dockerfile"

# Replace variables in the Dockerfile
REPLACE_WP_IMAGE="${DEFAULT_WP_IMAGE:-wordpress:latest}"
search_file_replace "$WORDPRESS_PATH/Dockerfile" "<<REPLACE_WP_IMAGE>>" "${REPLACE_WP_IMAGE}"

export WORDPRESS_IMAGE="${REPLACE_WP_IMAGE}"

#####################################################
# COPY WORDPRESS DOCKER-COMPOSE TEMPLATE

# Copy docker-compose.yml from template
cp "${PROJECT_PATH}/templates/wordpress-docker-compose.yml" "${WORDPRESS_DOCKER_COMPOSE_YML}"
wait
# Replace variables in the docker-compose.yml file
search_file_replace "${WORDPRESS_DOCKER_COMPOSE_YML}" "<<REPLACE_LEMP_NETWORK_NAME>>" "${LEMP_NETWORK_NAME}"

line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-5-container-directory-nginx.sh"
