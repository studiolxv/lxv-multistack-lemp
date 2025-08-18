#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# WP-ADMIN: WORDPRESS

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
# WORDPRESS: ADMIN USER EMAIL
line_break
heading "WORDPRESS: ADMIN USER EMAIL"
# Admin User Email

# Set default wp-admin admin user email
DEFAULT_WORDPRESS_ADMIN_USER_EMAIL="${ADMIN_EMAIL}"
example_msg "${C_Yellow}${C_Underline}NOTE${C_Reset}: Leave blank to use \"${C_Yellow}${DEFAULT_WORDPRESS_ADMIN_USER_EMAIL}${C_Reset}\" (This email is pulled from \$ADMIN_EMAIL in your /env.sh file):"
line_break

option_question "Enter your working email for the wp-admin admin user:"
printf "%s " "$(input_cursor)"
read USER_INPUT_WORDPRESS_ADMIN_EMAIL
if [ -z "$USER_INPUT_WORDPRESS_ADMIN_EMAIL" ]; then

	input_cursor "No wp-admin admin email provided. ${C_Reset}Using default: '${C_Yellow}${DEFAULT_WORDPRESS_ADMIN_USER_EMAIL}${C_Reset}'"

	# WP-ADMIN: WORDPRESS: ADMIN USER EMAIL
	WORDPRESS_ADMIN_USER_EMAIL="${DEFAULT_WORDPRESS_ADMIN_USER_EMAIL}"

else
	WORDPRESS_ADMIN_USER_EMAIL="${USER_INPUT_WORDPRESS_ADMIN_EMAIL}"
fi

#####################################################
# WORDPRESS: ADMIN USER NAME
line_break
heading "WORDPRESS: ADMIN USER NAME"
example_msg "${C_Yellow}${C_Underline}NOTE${C_Reset}: A common method of brute force hacking is to use a \"dictionary\" of common username and password combinations. For this reason, it is often recommended to avoid common usernames such as \"admin\"."
line_break
option_question "Enter a WordPress admin username, or leave blank to auto-generate a secure username:"
printf "%s " "$(input_cursor)"
read USER_INPUT_WORDPRESS_ADMIN_USER

if [ -z "$USER_INPUT_WORDPRESS_ADMIN_USER" ]; then

	input_cursor "No wp-admin admin username provided. Generating a secure wp-admin username (72 alphanumeric characters)"

	# Set default wp-admin admin username
	DEFAULT_WORDPRESS_ADMIN_USER="$(openssl rand -hex 36 | cut -c1-72)"

	WORDPRESS_ADMIN_USER="$DEFAULT_WORDPRESS_ADMIN_USER"

else
	WORDPRESS_ADMIN_USER="$USER_INPUT_WORDPRESS_ADMIN_USER"
fi

#####################################################
# WORDPRESS: ADMIN USER PASSWORD

# Generate password for Wordpress Admin WORDPRESS_ADMIN_USER_PASSWORD
# If WordPress eventually switches to using the built in PHP password_hash mechanism,
# then the length limit on the password will be 72 characters. Or rather,
# the password_hash function truncates passwords to that length
line_break
heading "WORDPRESS: ADMIN USER PASSWORD"
option_question "Enter a WordPress wp-admin password, or leave blank to auto-generate a secure password:"
printf "%s " "$(input_cursor)"
read USER_INPUT_WORDPRESS_ADMIN_PASSWORD

if [ -z "$USER_INPUT_WORDPRESS_ADMIN_PASSWORD" ]; then

	input_cursor "No wp-admin admin user password provided. ${C_Reset}Generating a secure wp-admin password (72 random base64 characters)"

	# Set default wp-admin admin user password
	DEFAULT_WORDPRESS_ADMIN_USER_PASSWORD="$(openssl rand -base64 36 | cut -c1-72)"

	# WP-CLI: WORDPRESS: ADMIN USER PASSWORD
	WORDPRESS_ADMIN_USER_PASSWORD="$DEFAULT_WORDPRESS_ADMIN_USER_PASSWORD"
else
	WORDPRESS_ADMIN_USER_PASSWORD="$USER_INPUT_WORDPRESS_ADMIN_PASSWORD"
fi

#####################################################
# EXPORTS
export WORDPRESS_ADMIN_USER_EMAIL
export WORDPRESS_ADMIN_USER
export WORDPRESS_ADMIN_USER_PASSWORD

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-9-secrets.sh"
