#!/bin/sh
#####################################################
# SOURCING .ENV FILE

source_lemp_stack_env() {
	local stack_name="${1:-$STACK_NAME}"
	local stack_env="${STACKS_PATH}/${stack_name}/.env"
	if [ -f "${stack_env}" ]; then
		. "${stack_env}"
		success_msg "${C_Yellow}${stack_name}/.env${C_Reset} sourced successfully. Proceeding... "

	else
		error_msg "source_lemp_stack_env(): The stack environment file '${stack_env}' does not exist."
		exit 1
	fi
}
export -f source_lemp_stack_env

source_wordpress_stack_env() {
	local stack_name="${1:-$STACK_NAME}"
	local stack_env="${STACKS_PATH}/${stack_name}/.env"

	if [ -f "${stack_env}" ]; then
		. "${stack_env}"
		success_msg "${C_Yellow}${stack_name}/.env${C_Reset} sourced successfully. Proceeding... "
	else
		error_msg "source_wordpress_stack_env(): The stack environment file '${stack_env}' does not exist."
		exit 1
	fi

	local wordpress_name="${2:-$WORDPRESS_NAME}"
	local wordpress_env="${LEMP_CONTAINERS_PATH}/${wordpress_name}/.env"

	if [ -f "${wordpress_env}" ]; then
		. "${wordpress_env}"
		success_msg "${C_Yellow}${wordpress_name}/.env${C_Reset} sourced successfully. Proceeding... "

	else
		error_msg "source_wordpress_stack_env(): The stack environment file '${wordpress_env}' does not exist."
		exit 1
	fi
}
export -f source_wordpress_stack_env

get_env_variable_value() {
	local var_name="$1"
	local file_name="${2:-$LEMP_ENV_FILE}"
	if [ -f "${file_name}" ]; then
		local var_value
		# Extract the value, remove surrounding quotes if they exist
		var_value=$(grep -E "^${var_name}=" "${file_name}" | cut -d '=' -f2- | sed -e 's/^"//' -e 's/"$//')
		if [ -n "${var_value}" ]; then
			echo "${var_value}"
		else
			return 1 # Indicate failure
		fi
	else
		return 1 # Indicate failure
	fi
}
export -f get_env_variable_value
