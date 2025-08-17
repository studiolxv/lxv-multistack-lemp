#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# MYSQL DATABASE INITIALIZATION

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

if [ -z "$WORDPRESS_DB_USER_PASSWORD" ]; then
	error_msg "❌ Missing required variable: WORDPRESS_DB_USER_PASSWORD"
	exit 1
fi

if [ -z "$DB_ROOT_USER_PASSWORD_FILE" ]; then
	error_msg "❌ Missing required variable: DB_ROOT_USER_PASSWORD_FILE"
	exit 1
fi

# LEMP_DB_ROOT_PASSWORD_FILE="$LEMP_PATH/secrets/db_root_user_password.txt"
# Read MySQL root password from secrets file
export MYSQL_ROOT_PASSWORD=$(cat "$DB_ROOT_USER_PASSWORD_FILE")

# Back to the LEMP stack directory
cd "${LEMP_PATH}"

# Debugging
changed_to_dir_msg "/${LEMP_DIR}"
status_msg "${C_Yellow}$(pwd)"
line_break

# Check if database exists
DB_EXISTS=$(docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -s -N -e "SHOW DATABASES LIKE '$WORDPRESS_DB_NAME';" 2>/dev/null)

if [[ -n "$DB_EXISTS" ]]; then
	#####################################################
	# DATABASE ALREADY EXISTS

	heading "WORDPRESS DATABASE"
	status_msg "✅ Database ${C_Yellow}'$WORDPRESS_DB_NAME' ${C_Reset}already exists."
	line_break
else
	#####################################################
	# CREATE WORDPRESS DATABASE

	heading "CREATING WORDPRESS DATABASE"
	generating_msg "Creating database in the LEMP container: ${C_Yellow}${LEMP_CONTAINER_NAME}${C_Reset}'s ${C_Yellow}${DB_HOST_NAME}${C_Reset} container"
	line_break
	generating_msg "Creating database: ${C_Yellow}'$WORDPRESS_DB_NAME'${C_Reset} and user: ${C_Yellow}'$WORDPRESS_DB_USER'"
	line_break

	# Detect MySQL Version inside the Docker Container
	MYSQL_VERSION=$(docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -s -N -e "SELECT VERSION();" 2>/dev/null | cut -d'.' -f1)

	if [[ "$MYSQL_VERSION" -ge 8 ]]; then
		status_msg "🔍 Detected MySQL $MYSQL_VERSION — Using caching_sha2_password..."
		AUTH_PLUGIN="caching_sha2_password"
	else
		status_msg "🔍 Detected MySQL $MYSQL_VERSION — Using mysql_native_password..."
		AUTH_PLUGIN="mysql_native_password"
	fi

# Set the password for the new user
	docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -s -N 2>/dev/null <<EOF >/dev/null
CREATE DATABASE IF NOT EXISTS ${WORDPRESS_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${WORDPRESS_DB_USER}'@'%' IDENTIFIED WITH ${AUTH_PLUGIN} BY '${WP_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${WORDPRESS_DB_NAME}.* TO '${WORDPRESS_DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

	sleep 2

	status_msg " Checking WP DB PASSWORD: ${C_Yellow}'$WORDPRESS_DB_NAME'${C_Reset} and user: ${C_Yellow}'$WORDPRESS_DB_USER'${C_Reset} setup complete."
	line_break

	docker exec -i "${DB_HOST_NAME}" mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT user, host, authentication_string FROM mysql.user WHERE user='${WORDPRESS_DB_USER}';"

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
