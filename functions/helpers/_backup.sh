#!/bin/sh

# Function to dump the database for a specific container
dump_container_db() {
	local container_name=$1
	if [[ -d "${LEMP_CONTAINERS_PATH}/$container_name" ]]; then

		line_break
		running_msg "Dumping ${container_name}..."
		line_break

		# Check if the container is running
		if docker-compose -f "${LEMP_CONTAINERS_PATH}/$container_name/docker-compose.yml" ps | grep 'Up' >/dev/null; then
			line_break
			heading "DATABASE DUMP: $container_name"
			line_break

			# Read the wp db name secret file
			WORDPRESS_DB_NAME=$(cat "${LEMP_CONTAINERS_PATH}/$container_name/secrets/wp_db_name.txt")

			# Read the root password from the secret file
			DB_ROOT_USER=$(cat "$DB_ROOT_USER_FILE")
			DB_ROOT_PASSWORD=$(cat "$DB_ROOT_USER_PASSWORD_FILE")

			status_msg "Dumping $container_name's '$DB_NAME' database..."
			docker exec $container_name mysqldump -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" ${WORDPRESS_DB_NAME} >"${BACKUPS_PATH}/${WORDPRESS_DB_NAME}/${WORDPRESS_DB_NAME}_$(date +%F_%H-%M-%S).sql"

		else
			error_msg "'${container_name}' container is not running."
			return 1
		fi
	else
		error_msg "'${container_name}' container not found."
		return 1
	fi

}


# Call the function with an optional argument for database name
# Example usage: backup_database "specific_database_name"
backup_database() {
	# Use provided database or dump all if empty
	WORDPRESS_DB_NAME="${1:-"--all-databases"}"

	heading "DATABASE BACKUP OPTIONS"

	# Read MySQL credentials from files
	DB_ROOT_USER=$(cat "$DB_ROOT_USER_FILE")
	DB_ROOT_PASSWORD=$(cat "$DB_ROOT_USER_PASSWORD_FILE")

	# Display menu
	status_msg "1. Simple Backup to a File (No Deletion)"
	status_msg "2. Compressed Backup Using gzip (No Deletion)"
	status_msg "3. Automated Backup with Deletion of Older Backups"
	status_msg "4. Backup All Databases"

	# Read user choice
	while true; do
		line_break
		printf "%s " "$(input_cursor)"
		read choice

		# Ensure choice is numeric and within range
		case "$choice" in
		1)
			echo "Executing: Simple Backup to a File (No Deletion)"
			mysqldump -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" "$WORDPRESS_DB_NAME" >"${BACKUPS_PATH}/${WORDPRESS_DB_NAME}/${WORDPRESS_DB_NAME}_$(date +%F_%H-%M-%S).sql"
			break
			;;
		2)
			echo "Executing: Compressed Backup Using gzip (No Deletion)"
			mysqldump -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" "$WORDPRESS_DB_NAME" | gzip >"${BACKUPS_PATH}/${WORDPRESS_DB_NAME}/${WORDPRESS_DB_NAME}_$(date +%F_%H-%M-%S).sql.gz"
			break
			;;
		3)
			echo "Executing: Automated Backup with Deletion of Older Backups"
			mysqldump -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" "$WORDPRESS_DB_NAME" >"${BACKUPS_PATH}/${WORDPRESS_DB_NAME}/${WORDPRESS_DB_NAME}_$(date +%F_%H-%M-%S).sql" &&
				find "$BACKUPS_PATH" -type f -name "*.sql" -mtime +14 -exec rm {} \;
			break
			;;
		4)
			echo "Executing: Backup All Databases"
			mysqldump -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" --all-databases >"${BACKUPS_PATH}/all_databases_$(date +%F_%H-%M-%S).sql"
			break
			;;
		*)
			error_msg "Invalid choice, please try again."
			;;
		esac
	done
}


