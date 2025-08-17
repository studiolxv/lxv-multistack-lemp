#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"
#####################################################
# WORDPRESS: SUBDOMAIN NAME

heading "WORDPRESS: CONTAINER NAME & SUBDOMAIN"

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

export WORDPRESS_SUBDOMAIN_NAME_DEFAULT="$(shuf -n1 /usr/share/dict/words | tr '[:upper:]' '[:lower:]')-$(shuf -n1 /usr/share/dict/words | tr '[:upper:]' '[:lower:]')"

example_msg "EXAMPLE"
example_msg
example_msg "This example is using a ${C_Cyan}random word${C_Reset} generator to create a unique Wordpress subdomain name."
example_msg
example_msg "Random word: ${C_Cyan}${C_Underline}${WORDPRESS_SUBDOMAIN_NAME_DEFAULT}${C_Reset}"
example_msg
example_msg "This will be the subdomain used for your Wordpress site url (e.g.  https://${C_Cyan}${C_Underline}${WORDPRESS_SUBDOMAIN_NAME_DEFAULT}${C_Reset}.${LEMP_SERVER_DOMAIN}${C_Reset})."
example_msg
warning_msg "NOTE: Do not add a '.' or '.\${TLD}' to the end (.test, .localhost, etc.)"
warning_msg "leave blank to use the random word: ${C_Cyan}${C_Underline}${WORDPRESS_SUBDOMAIN_NAME_DEFAULT}${C_Reset}"
line_break

section_title "ENTER NAME" ${C_Magenta}
# Prompt user for the domain name used in local ssl development
option_question "What subdomain name you want to use?"
printf "%s" "$(input_cursor)"
read USER_INPUT_WORDPRESS_SUBDOMAIN_NAME


if [ -z "$USER_INPUT_WORDPRESS_SUBDOMAIN_NAME" ]; then
	# Default to "$WORDPRESS_DIR" if no input is provided
	line_break
	input_cursor "No virtual host subdomain name provided. ${C_Reset}Using '${C_Magenta}${WORDPRESS_SUBDOMAIN_NAME_DEFAULT}${C_Reset}'"
	export WORDPRESS_SUBDOMAIN_NAME="${WORDPRESS_SUBDOMAIN_NAME_DEFAULT}"
else
	export WORDPRESS_SUBDOMAIN_NAME="$USER_INPUT_WORDPRESS_SUBDOMAIN_NAME"
fi

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER

sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-3-environment-wp.sh"
