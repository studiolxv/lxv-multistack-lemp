#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# SECRETS: WP CONTAINER SECRETS

# DIRECTORY CREATED
# <wp-container>/secrets/

# FILES THAT WILL BE CREATED
# <wp-container>/secrets/wp_db_name.txt
# <wp-container>/secrets/wp_db_user_password.txt
# <wp-container>/secrets/wp_admin_user_email.txt
# <wp-container>/secrets/wp_admin_user.txt
# <wp-container>/secrets/wp_admin_user_password.txt

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

heading "SAVING SECRETS ${C_Reset}for container: ${C_Yellow}${WORDPRESS_SUBDOMAIN_NAME}"

#########################################
# SECRETS: DIRECTORY & PATH

# Check if the secrets directory exists
if [ -d "${WORDPRESS_SECRETS_PATH}" ]; then
	success_msg "'${WORDPRESS_SUBDOMAIN_NAME}/secrets/' directory ${C_Green}already exists."
else
	mkdir -p "${WORDPRESS_SECRETS_PATH}"
	if [ -d "${WORDPRESS_SECRETS_PATH}" ]; then
		status_msg "✨ ${C_Reset}${WORDPRESS_SUBDOMAIN_NAME}/secrets directory ${C_Green}created successfully."

	else
		error_msg "creating ${WORDPRESS_SECRETS_PATH} directory, create manually or retry."
	fi
fi

#########################################
# SECRETS: WP DB NAME

# Check and create/write to wp_db_name.txt
if [ -f "${WORDPRESS_SECRETS_PATH}/wp_db_name.txt" ]; then
	success_msg "'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_name.txt' ${C_Green}already exists."
else

	# Write Variable to new file
	echo "$WORDPRESS_DB_NAME" >"${WORDPRESS_SECRETS_PATH}/wp_db_name.txt"

	#   status_msg "'wp_db_name.txt' created successfully."
	if [ -f "${WORDPRESS_SECRETS_PATH}/wp_db_name.txt" ]; then
		status_msg "✨ ${C_Reset}'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_name.txt' ${C_Green}created successfully."

		# Remove trailing newline
		tr -d '\n' <"${WORDPRESS_SECRETS_PATH}/wp_db_name.txt" >"${WORDPRESS_SECRETS_PATH}/temp.txt" &&
			mv "${WORDPRESS_SECRETS_PATH}/temp.txt" "${WORDPRESS_SECRETS_PATH}/wp_db_name.txt"

	else
		error_msg "creating '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_name.txt', create manually"
	fi
fi

#########################################
# SECRETS: WP DB USER

# Check and create/write to wp_db_user.txt
if [ -f "${WORDPRESS_SECRETS_PATH}/wp_db_user.txt" ]; then
	success_msg "'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_user.txt' ${C_Green}already exists."
else
	# Write Variable to new file
	echo "$WORDPRESS_DB_USER" >"${WORDPRESS_SECRETS_PATH}/wp_db_user.txt"

	#   status_msg "'wp_db_user.txt' created successfully."
	if [ -f "${WORDPRESS_SECRETS_PATH}/wp_db_user.txt" ]; then
		status_msg "✨ ${C_Reset}'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_user.txt' ${C_Green}created successfully."

		# Remove trailing newline
		tr -d '\n' <"${WORDPRESS_SECRETS_PATH}/wp_db_user.txt" >"${WORDPRESS_SECRETS_PATH}/temp.txt" &&
			mv "${WORDPRESS_SECRETS_PATH}/temp.txt" "${WORDPRESS_SECRETS_PATH}/wp_db_user.txt"

	else
		error_msg "creating '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_user.txt', create manually"
	fi
fi

#####################################################
# SECRETS: WP DB USER PASSWORD

# Check and create/write to wp_db_user_password.txt
if [ -f "${WORDPRESS_SECRETS_PATH}/wp_db_user_password.txt" ]; then
	success_msg "'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_user_password.txt' ${C_Green}already exists."
else

	# Write Variable to new file
	echo "$WORDPRESS_DB_USER_PASSWORD" >"${WORDPRESS_SECRETS_PATH}/wp_db_user_password.txt"

	if [ -f "${WORDPRESS_SECRETS_PATH}/wp_db_user_password.txt" ]; then
		status_msg "✨ ${C_Reset}'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_user_password.txt' ${C_Green}created successfully."

		# Remove trailing newline
		tr -d '\n' <"${WORDPRESS_SECRETS_PATH}/wp_db_user_password.txt" >"${WORDPRESS_SECRETS_PATH}/temp.txt" &&
			mv "${WORDPRESS_SECRETS_PATH}/temp.txt" "${WORDPRESS_SECRETS_PATH}/wp_db_user_password.txt"

	else
		error_msg "creating '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_db_user_password.txt', create manually"
	fi
fi

#########################################
# SECRETS: WP ADMIN USER EMAIL

# Check and create/write to wp_admin_user_email.txt
if [ -f "${WORDPRESS_SECRETS_PATH}/wp_admin_user_email.txt" ]; then
	success_msg "'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user_email.txt' ${C_Green}already exists."
else
	# Write Variable to new file
	echo "$WORDPRESS_ADMIN_USER_EMAIL" >"${WORDPRESS_SECRETS_PATH}/wp_admin_user_email.txt"

	if [ -f "${WORDPRESS_SECRETS_PATH}/wp_admin_user_email.txt" ]; then
		status_msg "✨ ${C_Reset}'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user_email.txt' ${C_Green}created successfully."

		# Remove trailing newline
		tr -d '\n' <"${WORDPRESS_SECRETS_PATH}/wp_admin_user_email.txt" >"${WORDPRESS_SECRETS_PATH}/temp.txt" &&
			mv "${WORDPRESS_SECRETS_PATH}/temp.txt" "${WORDPRESS_SECRETS_PATH}/wp_admin_user_email.txt"

	else
		error_msg "creating '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user_email.txt', create manually"
	fi
fi

#####################################################
# SECRETS: WP ADMIN USER

# Check and create/write to wp_admin_user.txt
if [ -f "${WORDPRESS_SECRETS_PATH}/wp_admin_user.txt" ]; then
	success_msg "'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user.txt' ${C_Green}already exists."
else

	# Write Variable to new file
	echo "$WORDPRESS_ADMIN_USER" >"${WORDPRESS_SECRETS_PATH}/wp_admin_user.txt"

	if [ -f "${WORDPRESS_SECRETS_PATH}/wp_admin_user.txt" ]; then
		status_msg "✨ ${C_Reset}'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user.txt' ${C_Green}created successfully."

		# Remove trailing newline
		tr -d '\n' <"${WORDPRESS_SECRETS_PATH}/wp_admin_user.txt" >"${WORDPRESS_SECRETS_PATH}/temp.txt" &&
			mv "${WORDPRESS_SECRETS_PATH}/temp.txt" "${WORDPRESS_SECRETS_PATH}/wp_admin_user.txt"

	else
		error_msg "creating '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user.txt', create manually"
	fi
fi

#########################################
# SECRETS: WP ADMIN USER PASSWORD

# Check and create/write to wp_admin_user_password.txt
if [ -f "${WORDPRESS_SECRETS_PATH}/wp_admin_user_password.txt" ]; then
	status_msg "✅ '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user_password.txt' ${C_Green}already exists."
else

	# Write Variable to new file
	echo "$WORDPRESS_ADMIN_USER_PASSWORD" >"${WORDPRESS_SECRETS_PATH}/wp_admin_user_password.txt"

	if [ -f "${WORDPRESS_SECRETS_PATH}/wp_admin_user_password.txt" ]; then
		status_msg "✨ ${C_Reset}'${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user_password.txt' ${C_Green}created successfully."

		# Remove trailing newline
		tr -d '\n' <"${WORDPRESS_SECRETS_PATH}/wp_admin_user_password.txt" >"${WORDPRESS_SECRETS_PATH}/temp.txt" &&
			mv "${WORDPRESS_SECRETS_PATH}/temp.txt" "${WORDPRESS_SECRETS_PATH}/wp_admin_user_password.txt"

	else
		error_msg "creating '${WORDPRESS_SUBDOMAIN_NAME}/secrets/wp_admin_user_password.txt', create manually"
	fi
fi

line_break

#####################################################
# COPY LEMP SECRETS TO WORDPRESS SECRETS

cp "${LEMP_SECRETS_PATH}/db_root_user.txt" "${WORDPRESS_SECRETS_PATH}/db_root_user.txt"

cp "${LEMP_SECRETS_PATH}/db_root_user_password.txt" "${WORDPRESS_SECRETS_PATH}/db_root_user_password.txt"

#####################################################
# FILES CREATED

# LEMP MYSQL ROOT CREDENTIALS
# /secrets/db_root_user.txt
# /secrets/db_root_user_password.txt

# Wordpress MYSQL Database
# /secrets/wp_db_name.txt
# /secrets/wp_db_user_password.txt

# Wordpress Admin
# /secrets/wp_admin_user_email.txt
# /secrets/wp_admin_user.txt
# /secrets/wp_admin_user_password.txt

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-10-db-init.sh"
