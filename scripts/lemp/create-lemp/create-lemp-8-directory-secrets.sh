#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"
#####################################################
# DATABASE: SECRETS
line_break
section_title "DATABASE: SECRETS"

#####################################################
# SECRETS PATH
# Check if the secrets directory exists
if [ -d "$LEMP_SECRETS_PATH" ]; then
	success_msg "'${LEMP_DIR}/${SECRETS_DIR}' directory already exists."
else
	mkdir -p "${LEMP_SECRETS_PATH}"

	if [ -d "${LEMP_SECRETS_PATH}" ]; then
		success_msg "'${LEMP_DIR}/${SECRETS_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${LEMP_SECRETS_PATH}"
	else
		error_msg "Error creating '${LEMP_DIR}/${SECRETS_DIR}' directory, check permissions or create manually."
	fi
fi
sleep 1

line_break

#####################################################
# SECRETS: DB ROOT USER
# Save passwords to secrets files, ensuring they are not overwritten
if [ -f "${LEMP_SECRETS_PATH}/db_root_user.txt" ]; then
	success_msg "'${LEMP_DIR}/${SECRETS_DIR}/db_root_user.txt' file already exists."
else
	# Save root password to variable to save in secrets
	DB_ROOT_USER="root"

	# Write the password to a file
	echo "$DB_ROOT_USER" >"${LEMP_SECRETS_PATH}/db_root_user.txt"

	# Remove trailing newline
	tr -d '\n' <"${LEMP_SECRETS_PATH}/db_root_user.txt" >"${LEMP_SECRETS_PATH}/temp.txt" &&
		mv "${LEMP_SECRETS_PATH}/temp.txt" "${LEMP_SECRETS_PATH}/db_root_user.txt"

	sleep 1

	if [ -f "${LEMP_SECRETS_PATH}/db_root_user.txt" ]; then
		success_msg "'${LEMP_DIR}/${SECRETS_DIR}/db_root_user.txt' created successfully."
	else
		error_msg "Failed to create '${LEMP_DIR}/${SECRETS_DIR}/db_root_user.txt', check permissions or create manually."
	fi
fi

line_break

#####################################################
# SECRETS: DB ROOT USER PASSWORD
if [ -f "${LEMP_SECRETS_PATH}/db_root_user_password.txt" ]; then
	success_msg "'${LEMP_DIR}/${SECRETS_DIR}/db_root_user_password.txt' file already exists."
else
	# Generate Root password for Database
	DB_ROOT_PASSWORD="$(openssl rand -hex 16)"

	# Write the password to a file
	echo "$DB_ROOT_PASSWORD" >"${LEMP_SECRETS_PATH}/db_root_user_password.txt"

	# Remove trailing newline
	tr -d '\n' <"${LEMP_SECRETS_PATH}/db_root_user_password.txt" >"${LEMP_SECRETS_PATH}/temp.txt" &&
		mv "${LEMP_SECRETS_PATH}/temp.txt" "${LEMP_SECRETS_PATH}/db_root_user_password.txt"

	sleep 1

	if [ -f "${LEMP_SECRETS_PATH}/db_root_user_password.txt" ]; then
		success_msg "'${LEMP_DIR}/${SECRETS_DIR}/db_root_user_password.txt' created successfully."
	else
		error_msg "Failed to create '${LEMP_DIR}/${SECRETS_DIR}/db_root_user_password.txt', check permissions or create manually."
	fi
fi

line_break

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-9-directory-nginx.sh"
