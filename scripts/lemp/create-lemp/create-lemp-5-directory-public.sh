#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# PUBLIC DIRECTORY: HTML

section_title "PUBLIC DIRECTORY: HTML"
generating_msg "Creating public directory for HTML files..."

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

generating_msg "Creating basic index.php page..."
line_break

#####################################################
# PUBLIC HTML: PHP INFO index.php
echo "<?php
// Basic PHP info page
phpinfo();
?>" >"${PHP_PUBLIC_PATH}/index.php"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-6-directory-db.sh"
