#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# SOURCE LEMP STACK .ENV
if [[ -z "${STACK_NAME}" ]]; then
	status_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	# Select a LEMP stack using the new function, defines ${STACK_NAME}
	select_lemp_stack
else
	success_msg "${C_Yellow}\$STACK_NAME${C_Reset} is defined as '${C_Yellow}${STACK_NAME}${C_Reset}'. Proceeding..."
fi

source_lemp_stack_env ${STACK_NAME}

#####################################################
# VERIFY WORDPRESS DATABASE
# Verify if WordPress is able to connect to the database

heading "VERIFY WORDPRESS DATABASE"
status_msg "🔍 ${C_Reset}Checking connection to newly created WordPress database ${C_Yellow}'$WORDPRESS_DB_NAME'${C_Reset}..."
line_break

# Wait for services to initialize
sleep 5

# Back to LEMP Directory
changed_to_dir_msg "${LEMP_DIR}"
cd "${LEMP_PATH}" || {
	line_break
	error_msg "Could not change directory to LEMP_PATH (${LEMP_PATH}). Exiting..."
	exit 1
}

# Run a MySQL query inside the LEMP database container
DB_EXISTS=$(docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SHOW DATABASES LIKE '${WORDPRESS_DB_NAME}';" 2>/dev/null)

# Check if the database exists
if [[ "$DB_EXISTS" == *"${WORDPRESS_DB_NAME}"* ]]; then
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
