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

# # Start the WordPress container
# cd "$WORDPRESS_PATH" || exit 1
# docker-compose up -d

status_msg "WordPress container ${WORDPRESS_SUBDOMAIN_NAME} added to ${STACK_NAME}!"

#####################################################
# WP-CLI: INSTALL WORDPRESS: SUCCESS MESSAGE

line_break
heading "SUCCESS"
wordpress_info

# Open the default browser to the WordPress site and phpMyAdmin
open_link "https://$WORDPRESS_SUBDOMAIN"

line_break

# Output success message
