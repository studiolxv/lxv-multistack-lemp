#!/bin/sh
. "./_env-setup.sh"
# debug_file_msg "$(current_basename)"

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

echo "testing path variable -> ${LEMP_ENV_FILE}"
source ${LEMP_ENV_FILE}
#####################################################
# START DOCKER WORDPRESS

# Change to the new WordPress container directory before executing docker-compose commands
# Ensure the new WordPress container connects to the LEMP MySQL database
line_break
heading "WORDPRESS DOCKER CONTAINER"
status_msg "🚀 ${C_Reset}Starting WordPress container: ${C_Yellow}${WORDPRESS_CONTAINER_NAME}${C_Reset}..."
line_break

# Back to the WordPress container directory
changed_to_dir_msg "${LEMP_DIR}/containers/${WORDPRESS_DIR}"
cd "$WORDPRESS_LEMP_CONTAINER_PATH"


# Start up new Wordpress Container
running_msg "% docker-compose -f \"${WORDPRESS_LEMP_CONTAINER_PATH}/docker-compose.yml\" up -d"

docker-compose -f "${WORDPRESS_DOCKER_COMPOSE_YML}" up -d


# Back to the Project directory
cd "${PROJECT_PATH}"

# Debugging
changed_to_dir_msg "/${PROJECT_NAME}"
status_msg "${C_Yellow}$(pwd)"
line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh ${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-16-update-wordpress.sh
