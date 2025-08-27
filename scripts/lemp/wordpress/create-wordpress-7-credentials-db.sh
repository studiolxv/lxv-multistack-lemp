#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
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

#####################################################
# WORDPRESS: DATABASE NAME

heading "WORDPRESS: DATABASE NAME"
option_question "Enter WordPress database name. Leave blank to use: \"${C_Underline}${WORDPRESS_SUBDOMAIN_NAME}${C_Reset}${C_Yellow}\":"

printf "%s " "$(input_cursor)"
read USER_INPUT_DB_NAME

if [ -z "$USER_INPUT_DB_NAME" ]; then

	DEFAULT_WORDPRESS_DB_NAME="${WORDPRESS_SUBDOMAIN_NAME}"

	input_cursor "No Wordpress Database Name provided. ${C_Reset}Using ${C_Yellow}\"${DEFAULT_WORDPRESS_DB_NAME}\""

	#####################################################
	# WORDPRESS: DATABASE DATABASE NAME

	WORDPRESS_DB_NAME="$DEFAULT_WORDPRESS_DB_NAME"
else
	WORDPRESS_DB_NAME="$USER_INPUT_DB_NAME"
fi
line_break
input_cursor "WORDPRESS_DB_NAME${C_Reset}: '${C_Magenta}$WORDPRESS_DB_NAME${C_Reset}'"
line_break
#####################################################
# WORDPRESS: DATABASE TABLE PREFIX

DEFAULT_WORDPRESS_TABLE_PREFIX="wp_"

heading "WORDPRESS: DATABASE TABLE PREFIX"
option_question "Enter WordPress database table prefix name. Leave blank to use: \"${C_Underline}${DEFAULT_WORDPRESS_TABLE_PREFIX}${C_Reset}${C_Yellow}\":"

printf "%s " "$(input_cursor)"
read USER_INPUT_WORDPRESS_TABLE_PREFIX

# If $USER_INPUT_DB_NAME is empty
if [ -z "$USER_INPUT_WORDPRESS_TABLE_PREFIX" ]; then
	input_cursor "No Wordpress Database Table Prefix provided. ${C_Reset}Using ${C_Yellow}\"${DEFAULT_WORDPRESS_TABLE_PREFIX}\""

	WORDPRESS_TABLE_PREFIX="$DEFAULT_WORDPRESS_TABLE_PREFIX"
else
	WORDPRESS_TABLE_PREFIX="$USER_INPUT_WORDPRESS_TABLE_PREFIX"
fi
line_break
input_cursor "WORDPRESS_TABLE_PREFIX${C_Reset}: '${C_Magenta}${WORDPRESS_TABLE_PREFIX}${C_Reset}'"
line_break
#####################################################
# WORDPRESS: DATABASE USER NAME

heading "WORDPRESS: DATABASE USER NAME"
option_question "Enter a WordPress database username, or leave blank to auto-generate a secure username:"
printf "%s " "$(input_cursor)"
read USER_INPUT_DB_USER

# If $USER_INPUT_DB_USER is empty
if [ -z "$USER_INPUT_DB_USER" ]; then

	# (Makes 32 alphanumeric characters)
	DEFAULT_WORDPRESS_DB_USER="$(openssl rand -hex 16)"

	input_cursor "No Wordpress Database Username password provided. ${C_Reset}Generating a secure wp db username (32 alphanumeric characters)"

	WORDPRESS_DB_USER="${WORDPRESS_DB_NAME}_${DEFAULT_WORDPRESS_DB_USER}"
else
	WORDPRESS_DB_USER="$USER_INPUT_DB_USER"
fi

# Define max length
MAX_LENGTH_WORDPRESS_DB_USER=32

# Check length using `wc -c` (subtract 1 for trailing newline)
USER_LENGTH=$(printf "%s" "$WORDPRESS_DB_USER" | wc -c)
USER_LENGTH=$((USER_LENGTH - 1))

# Trim username if it exceeds max length
if [ "$USER_LENGTH" -gt "$MAX_LENGTH_WORDPRESS_DB_USER" ]; then
	WORDPRESS_DB_USER=$(printf "%s" "$WORDPRESS_DB_USER" | cut -c1-"$MAX_LENGTH_WORDPRESS_DB_USER")
	input_cursor "Username was too long! Trimmed to 32 characters"
fi

line_break
input_cursor "WORDPRESS_DB_PASSWORD${C_Reset}: Will be saved to '${C_Magenta}${WORDPRESS_DIR}/secrets/wp_db_user.txt${C_Reset}'"
line_break
WORDPRESS_DB_USER="${WORDPRESS_DB_USER}"

#####################################################
# WORDPRESS: DATABASE USER PASSWORD

heading "WORDPRESS: DATABASE USER PASSWORD"
# Prompt User for WP Database Password

option_question "Enter a WordPress database password for your wp db user, or leave blank to auto-generate a secure password:"
printf "%s " "$(input_cursor)"
read USER_INPUT_DB_PASSWORD

if [ -z "$USER_INPUT_DB_PASSWORD" ]; then

	# 64 alphanumeric characters)
	DEFAULT_WORDPRESS_DB_PASSWORD="$(openssl rand -hex 16)"

	input_cursor "No Wordpress Database password provided. ${C_Reset}Generating a secure wp database password (64 alphanumeric characters)"

	WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_NAME}_${DEFAULT_WORDPRESS_DB_PASSWORD}"
else
	WORDPRESS_DB_PASSWORD="${USER_INPUT_DB_PASSWORD}"
fi

# Define max length
MAX_LENGTH_WORDPRESS_DB_PASSWORD=32

# Check length using `wc -c` (subtract 1 for trailing newline)
PASS_LENGTH=$(printf "%s" "$WORDPRESS_DB_PASSWORD" | wc -c)
PASS_LENGTH=$((PASS_LENGTH - 1))

# Trim password if it exceeds max length
if [ "$PASS_LENGTH" -gt "$MAX_LENGTH_WORDPRESS_DB_PASSWORD" ]; then
	WORDPRESS_DB_PASSWORD=$(printf "%s" "$WORDPRESS_DB_PASSWORD" | cut -c1-"$MAX_LENGTH_WORDPRESS_DB_PASSWORD")
	input_cursor "Password was too long! Trimmed to 32 characters"
fi

line_break
input_cursor "WORDPRESS_DB_PASSWORD${C_Reset}: Will be saved to '${C_Magenta}${WORDPRESS_DIR}/secrets/wp_db_user_password.txt${C_Reset}'"

WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD}"

#####################################################
# EXPORTS

export WORDPRESS_DB_NAME
export WORDPRESS_DB_USER
export WORDPRESS_DB_PASSWORD
export WORDPRESS_TABLE_PREFIX

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER

sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-8-credentials-wp-admin.sh"
