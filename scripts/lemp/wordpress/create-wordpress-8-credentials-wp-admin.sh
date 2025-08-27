#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

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
example_msg "${C_Yellow}${C_Underline}NOTE${C_Reset}: A common method of brute force hacking is to use a \"dictionary\" of common username and password combinations. For this reason, it is often recommended to avoid common usernames such as \"admin\". WordPress usernames must be <=60 chars and contain only letters, numbers, _, ., @, or -"
line_break
option_question "Enter a WordPress admin username, or leave blank to auto-generate a secure username:"
printf "%s " "$(input_cursor)"
read USER_INPUT_WORDPRESS_ADMIN_USER

RAW_ADMIN_USER="${USER_INPUT_WORDPRESS_ADMIN_USER}"
if [ -z "$RAW_ADMIN_USER" ]; then
    input_cursor "No wp-admin admin username provided. Generating a secure wp-admin username (random 32 chars)"
    RAW_ADMIN_USER="$(openssl rand -hex 16)"
fi

# Sanitize: allow only WordPress-valid chars and trim to 60 chars
SAFE_ADMIN_USER=$(printf '%s' "$RAW_ADMIN_USER" | tr -cd '[:alnum:]_.@-' | cut -c1-60)

if [ -z "$SAFE_ADMIN_USER" ]; then
    SAFE_ADMIN_USER="admin$(date +%s)"
    warning_msg "Provided username invalid/empty. Using fallback username: ${SAFE_ADMIN_USER}"
fi

# If sanitization changed the username, warn
if [ "$SAFE_ADMIN_USER" != "$RAW_ADMIN_USER" ]; then
    warning_msg "Admin username sanitized to '${SAFE_ADMIN_USER}' (max 60 chars; allowed charset)."
fi

WORDPRESS_ADMIN_USER="$SAFE_ADMIN_USER"
line_break
input_cursor "${C_Reset}WORDPRESS_ADMIN_USER: '${C_Magenta}${WORDPRESS_ADMIN_USER}${C_Reset}'"
line_break

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

# Clamp password length to 255 to satisfy WordPress schema (user_pass varchar(255))
PASS_LEN=$(printf '%s' "$WORDPRESS_ADMIN_USER_PASSWORD" | wc -c); PASS_LEN=$((PASS_LEN-1))
if [ "$PASS_LEN" -gt 255 ]; then
    WORDPRESS_ADMIN_USER_PASSWORD=$(printf '%s' "$WORDPRESS_ADMIN_USER_PASSWORD" | cut -c1-255)
    warning_msg "Admin password exceeded 255 characters and was truncated to fit WordPress limits."
	line_break
	input_cursor "${C_Yellow}NEW ${C_Reset}admin user password:'${C_Magenta}${WORDPRESS_ADMIN_USER_PASSWORD}${C_Reset}'" ${C_Magenta}
	line_break
fi

#####################################################
# EXPORTS
export WORDPRESS_ADMIN_USER
export WORDPRESS_ADMIN_USER_EMAIL
export WORDPRESS_ADMIN_USER_PASSWORD

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-9-secrets.sh"
