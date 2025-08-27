#!/bin/sh
#####################################################
# SOURCING .ENV FILE

source_lemp_stack_env() {
	local stack_name="${1:-$STACK_NAME}"
	local stack_env="${STACKS_PATH}/${stack_name}/.env"
	if [ -f "${stack_env}" ]; then
		. "${stack_env}"
		debug_success_msg "${C_Yellow}${stack_name}/.env${C_Reset} sourced successfully. Proceeding... "

	else
		error_msg "source_lemp_stack_env(): The stack environment file '${stack_env}' does not exist."
		exit 1
	fi
}


source_wordpress_stack_env() {
	local stack_name="${1:-$STACK_NAME}"
	local stack_env="${STACKS_PATH}/${stack_name}/.env"

	if [ -f "${stack_env}" ]; then
		. "${stack_env}"
		debug_success_msg "${C_Yellow}${stack_name}/.env${C_Reset} sourced successfully. Proceeding... "
	else
		error_msg "source_wordpress_stack_env(): The stack environment file '${stack_env}' does not exist."
		exit 1
	fi

	local wordpress_name="${2:-$WORDPRESS_NAME}"
	local wordpress_env="${LEMP_CONTAINERS_PATH}/${wordpress_name}/.env"

	if [ -f "${wordpress_env}" ]; then
		. "${wordpress_env}"
		debug_success_msg "${C_Yellow}${wordpress_name}/.env${C_Reset} sourced successfully. Proceeding... "

	else
		error_msg "source_wordpress_stack_env(): The stack environment file '${wordpress_env}' does not exist."
		exit 1
	fi
}
