#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"
heading "NEW WORDPRESS CONTAINER"

#####################################################
# CREATE NEW WORDPRESS CONTAINER
# Get the first argument (stack name)
export STACK_NAME="$1"

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

if [[ -z "${LEMP_SERVER_DOMAIN}" ]]; then
	error_msg "${C_Yellow}\$LEMP_SERVER_DOMAIN${C_Reset} is not defined. Please set it before running the script."
	exit 1
else
	success_msg "${C_Yellow}\$LEMP_SERVER_DOMAIN${C_Reset} is defined as '${C_Yellow}${LEMP_SERVER_DOMAIN}${C_Reset}'. Proceeding..."
fi

# Ensure the LEMP stack exists
STACK_PATH="${STACKS_PATH}/${STACK_NAME}"
if [ ! -d "$STACK_PATH" ]; then
	log_error "LEMP stack ${C_Yellow}'$STACK_NAME'${C_Reset} does not exist!"
	exit 1
else
	success_msg "${C_Yellow}\$STACK_PATH${C_Reset} is defined as '${C_Yellow}${STACK_PATH}${C_Reset}'. Proceeding..."
fi

line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-2-name-and-domain.sh"
