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
# WORDPRESS: SUBDOMAIN NAME

heading "WORDPRESS: SUBDOMAIN NAME"
status_msg "This will be the subdomain used for your Wordpress site url ${C_Yellow}${C_Underline}EXAMPLE${C_Reset}: https://${C_Yellow}subdomain${C_Reset}.${LEMP_SERVER_DOMAIN}${C_Reset}."
status_msg "${C_Yellow}${C_Underline}NOTE${C_Reset}: Do not add a '.' or '.\${TLD}' to the end (.test, .localhost, etc.)"

line_break
# Prompt user for the domain name used in local ssl development
status_msg "${C_Yellow}What subdomain name you want to use? Leave blank to use: \"${C_Underline}${WORDPRESS_DIR}${C_Reset}\":"
line_break
printf "%s" "$(input_cursor)"
read USER_INPUT_WORDPRESS_SUBDOMAIN_NAME

DEFAULT_WORDPRESS_SUBDOMAIN_NAME="${WORDPRESS_DIR}"

if [ -z "$USER_INPUT_WORDPRESS_SUBDOMAIN_NAME" ]; then
	# Default to "$WORDPRESS_DIR" if no input is provided
	line_break
	status_msg "No virtual host subdomain name provided. ${C_Reset}Using '${C_Yellow}${DEFAULT_WORDPRESS_SUBDOMAIN_NAME}${C_Reset}'"
	export WORDPRESS_SUBDOMAIN_NAME="${DEFAULT_WORDPRESS_SUBDOMAIN_NAME}"
else
	export WORDPRESS_SUBDOMAIN_NAME="$USER_INPUT_WORDPRESS_SUBDOMAIN_NAME"
fi

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER

sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-3-environment-wp.sh"
