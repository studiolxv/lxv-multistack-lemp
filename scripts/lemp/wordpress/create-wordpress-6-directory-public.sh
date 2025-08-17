#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

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
# PUBLIC DIRECTORY: HTML

section_title "PUBLIC DIRECTORY: HTML"

if [ -d "${LEMP_PATH}/${PHP_PUBLIC_DIR}" ]; then
	success_msg "'${LEMP_DIR}/${PHP_PUBLIC_DIR}' directory already exists."
else
	mkdir -p "${LEMP_PATH}/${PHP_PUBLIC_DIR}"

	if [ -d "${LEMP_PATH}/${PHP_PUBLIC_DIR}" ]; then
		success_msg "'${LEMP_DIR}/${PHP_PUBLIC_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${LEMP_PATH}/${PHP_PUBLIC_DIR}"

	else
		error_msg "Failed to create '${LEMP_DIR}/${PHP_PUBLIC_DIR}', check permissions or create manually."
	fi
fi

line_break

#####################################################
# PUBLIC HTML: PHP INFO index.php
echo "<?php
// Basic PHP info page
phpinfo();
?>" >"${PHP_PUBLIC_PATH}/index.php"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-7-credentials-db.sh"
