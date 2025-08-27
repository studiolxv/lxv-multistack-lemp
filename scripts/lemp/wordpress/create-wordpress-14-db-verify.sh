#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# INITIALIZE WORDPRESS DATABASE
# Creates the WordPress database and user if they do not exist
line_break
heading "INITIALIZE WORDPRESS DATABASE"

#####################################################
# SOURCE LEMP STACK .ENV
if [ -z "${STACK_NAME}" ]; then
	warning_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	# Select a LEMP stack using the new function, defines ${STACK_NAME}
	select_lemp_stack
else
	debug_success_msg "${C_Yellow}\$STACK_NAME${C_Reset} is defined as '${C_Yellow}${STACK_NAME}${C_Reset}'. Proceeding..."
fi

source_lemp_stack_env ${STACK_NAME}
line_break

# Required variables check
if [ -z "$WORDPRESS_SUBDOMAIN" ]; then
	error_msg "WORDPRESS_SUBDOMAIN is not set. Please set it in your environment."
	exit 1
fi

if [ -z "$WORDPRESS_DB_NAME" ]; then
	error_msg "WORDPRESS_DB_NAME is not set. Please set it in your environment."
	exit 1
fi

if [ -z "$WORDPRESS_DB_USER" ]; then
	error_msg "WORDPRESS_DB_USER is not set. Please set it in your environment."
	exit 1
fi

if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
	error_msg "WORDPRESS_DB_PASSWORD is not set. Please set it in your environment."
	exit 1
fi

if [ -z "$DB_ROOT_USER_PASSWORD_FILE" ]; then
	error_msg "DB_ROOT_USER_PASSWORD_FILE is not set. Please set it in your environment."
	exit 1
fi

export MYSQL_ROOT_PASSWORD=$(cat "$DB_ROOT_USER_PASSWORD_FILE")
ROOT_PW="$MYSQL_ROOT_PASSWORD"

status_msg "🔍 ${C_Reset}Checking WP DB PASSWORD for user '${WORDPRESS_DB_USER}'..."

line_break

# Back to LEMP Directory
changed_to_dir_msg "${LEMP_DIR}"
cd "${LEMP_PATH}" || {
	line_break
	error_msg "Could not change directory to LEMP_PATH (${LEMP_PATH}). Exiting..."
	exit 1
}

# Run a MySQL query inside the LEMP database container
DB_EXISTS=$(docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${ROOT_PW}" -s -N -e "SHOW DATABASES LIKE '${WORDPRESS_DB_NAME}';" 2>/dev/null)

# Check if the database exists
if [ -n "$DB_EXISTS" ]; then
	success_msg "Database ${C_Yellow}'${WORDPRESS_DB_NAME}'${C_Reset} exists in the LEMP ${C_Yellow}'${DB_HOST_NAME}'${C_Reset} container."
else
	error_msg "Database '${WORDPRESS_DB_NAME}' not found in LEMP ${DB_HOST_NAME}. Exiting..."
	exit 1
fi

# Back to the Project directory
cd "${PROJECT_PATH}"

# Debugging
changed_to_dir_msg "/${PROJECT_NAME}"
status_msg "${C_Yellow}$(pwd)"
line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-15-start-docker.sh"
