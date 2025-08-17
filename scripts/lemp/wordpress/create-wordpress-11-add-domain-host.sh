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
# WORDPRESS: ADD DOMAIN TO HOSTS FILE

if [ -z "$LEMP_SERVER_DOMAIN" ]; then
	error_msg "${C_Red}\$LEMP_SERVER_DOMAIN is not set!"
fi

if [ -z "$LEMP_SERVER_DOMAIN_TLD" ]; then
	error_msg "${C_Red}\$LEMP_SERVER_DOMAIN_TLD is not set!"
fi

if [ -z "$WORDPRESS_SUBDOMAIN" ]; then
	error_msg "${C_Red}\$WORDPRESS_SUBDOMAIN is not set!"
fi

if [ -z "$OS_NAME" || -z "$WORDPRESS_SUBDOMAIN" || -z "$HOSTS_FILE_LOOPBACK_IP" || -z "$LEMP_SERVER_DOMAIN" || -z "$LEMP_SERVER_DOMAIN_TLD" || -z "$HOSTS_FILE" ]; then
	line_break
fi

append_to_hosts_file "$WORDPRESS_SUBDOMAIN"
wait

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-12-env-file.sh"
