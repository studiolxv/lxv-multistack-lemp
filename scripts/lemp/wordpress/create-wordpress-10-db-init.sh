#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# MYSQL DATABASE INITIALIZATION

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

#####################################################
# INIT MYSQL DATABASE

# Ensure required variables and secret password file exist
if [ -z "$WORDPRESS_SUBDOMAIN" ]; then
	error_msg "❌ Missing required variable: WORDPRESS_SUBDOMAIN"
	exit 1
fi

if [ -z "$WORDPRESS_DB_NAME" ]; then
	error_msg "❌ Missing required variable: WORDPRESS_DB_NAME"
	exit 1
fi

if [ -z "$WORDPRESS_DB_USER" ]; then
	error_msg "❌ Missing required variable: WORDPRESS_DB_USER"
	exit 1
fi

if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
	error_msg "❌ Missing required variable: WORDPRESS_DB_PASSWORD"
	exit 1
fi

if [ -z "$DB_ROOT_USER_PASSWORD_FILE" ]; then
	error_msg "❌ Missing required variable: DB_ROOT_USER_PASSWORD_FILE"
	exit 1
fi

# LEMP_DB_ROOT_PASSWORD_FILE="$LEMP_PATH/secrets/db_root_user_password.txt"
# Read MySQL root password from secrets file
export MYSQL_ROOT_PASSWORD=$(cat "$DB_ROOT_USER_PASSWORD_FILE")
ROOT_PW="$MYSQL_ROOT_PASSWORD"

# Back to the LEMP stack directory
cd "${LEMP_PATH}"

# Debugging
changed_to_dir_msg "/${LEMP_DIR}"
status_msg "${C_Yellow}$(pwd)"
line_break

heading "CREATE WORDPRESS DATABASE"
body_msg "Check if '$WORDPRESS_DB_NAME' exists if not create it and create user..."
# Check if database exists
DB_EXISTS=$(docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${ROOT_PW}" -s -N -e "SHOW DATABASES LIKE '${WORDPRESS_DB_NAME}';" 2>/dev/null)

if [ -n "$DB_EXISTS" ]; then

	#####################################################
	# DATABASE ALREADY EXISTS
	status_msg "✅ Database ${C_Yellow}'$WORDPRESS_DB_NAME' ${C_Reset}already exists."
	line_break
else
	#####################################################
	# CREATE WORDPRESS DATABASE

	section_title "INITIALIZE WORDPRESS DATABASE"

	generating_msg "Create database '${C_Yellow}$WORDPRESS_DB_NAME${C_Reset}' in ${C_Yellow}${LEMP_CONTAINER_NAME}${C_Reset}'s ${C_Yellow}${DB_HOST_NAME}${C_Reset} container" ${C_BrightWhite}
	generating_msg "Creating user '${C_Yellow}$WORDPRESS_DB_USER${C_Reset}' in database '${C_Yellow}$WORDPRESS_DB_NAME${C_Reset}'" ${C_BrightWhite}
	line_break

	# Create WordPress database and user (idempotent)
	docker exec -i "${DB_HOST_NAME}" sh -lc "mysql -uroot -p\"$ROOT_PW\"" <<SQL >/dev/null 2>&1
CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${WORDPRESS_DB_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DB_PASSWORD}';
ALTER USER '${WORDPRESS_DB_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${WORDPRESS_DB_NAME}\`.* TO '${WORDPRESS_DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

	sleep 4

	section_title "CHECK WP DB PASSWORD"

	docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${ROOT_PW}" -e "SELECT user, host, authentication_string FROM mysql.user WHERE user='${WORDPRESS_DB_USER}';"

	line_break
	status_msg "✅ Database: ${C_Yellow}'$WORDPRESS_DB_NAME'${C_Reset} and user: ${C_Yellow}'$WORDPRESS_DB_USER'${C_Reset} setup complete."
	line_break

fi

# Back to the Project directory
cd "${PROJECT_PATH}"

# Debugging
changed_to_dir_msg "/${PROJECT_NAME}"
status_msg "${C_Yellow}$(pwd)"
line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-11-add-domain-host.sh"
