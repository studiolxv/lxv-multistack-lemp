#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

line_break
export STACK_NAME="$1"
#####################################################
# SOURCE LEMP STACK .ENV
if [ -z "${STACK_NAME}" ]; then
	status_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	select_lemp_stack
fi

source_lemp_stack_env "${STACK_NAME}"

#####################################################
section_title "HOW TO RECOVER DATABASE TABLES"

body_msg "Before running, manually copy your '.ibd' and '.frm' files"
body_msg "   into a ${C_Yellow}named and empty database folder${C_Reset} inside your LEMP MySQL/MariaDB container directory 'data' matching the database name you want to recover."
line_break
example_msg "   Example: (${DB_DATA_PATH}/${C_Yellow}<database>${C_Reset})" "${C_Yellow}"

line_break
body_msg "If using phpMyAdmin, create the database manually."
body_msg "   - OR select ${C_Yellow}option 1${C_Reset} in this script to create a new database."

line_break
body_msg "The script will:"
body_msg "   - Detect '.frm' and '.ibd' files."
body_msg "   - Recreate missing tables."
body_msg "   - Restore tablespaces."
body_msg "   - Complete the recovery process."

# Define paths and credentials
DB_USER="$(cat "$DB_ROOT_USER_FILE")"
DB_PASS="$(cat "$DB_ROOT_USER_PASSWORD_FILE")"
DB_HOST="${DB_HOST_NAME}"
MYSQL_CONTAINER="${DB_HOST_NAME}"
OUTPUT_FILE="tables_list.txt"

# Ensure DB_DATA_PATH exists
if [ ! -d "$DB_DATA_PATH" ]; then
	error_msg "ERROR: Database directory path '$DB_DATA_PATH' not found!"
	exit 1
fi

# Ensure MySQL container is detected
if [ -z "$MYSQL_CONTAINER" ]; then
	error_msg "No running MySQL/MariaDB container found! Ensure your LEMP stack is running."
	exit 1
fi
line_break
body_msg "✅ Using MySQL/MariaDB container: ${C_Yellow}$MYSQL_CONTAINER"

# Step 1: Ask if the user wants to create a new database or select an existing one
section_title "RECOVER OPTIONS"
body_msg "1) Enter name of database to create and recover tables"
body_msg "2) Select from existing database folders"
line_break
while :; do
	printf "%s" "$(input_cursor)"
	read -r DB_ACTION
	line_break
	case "$DB_ACTION" in
	1)
		read -r -p "Enter the name for the new database: " RECOVER_DB_NAME
		generating_msg "Creating new database: $RECOVER_DB_NAME..."
		docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $RECOVER_DB_NAME;"
		break
		;;
	2)
		break
		;;
	*)
		error_msg "Invalid choice. Please enter 1 to create a new database or 2 to select an existing one."
		;;
	esac
done

# Step 2: Select from existing database folders
if [ "$DB_ACTION" = "2" ]; then
	VALID_FOLDERS=$(find "$DB_DATA_PATH" -mindepth 1 -maxdepth 1 -type d ! -name "mysql" ! -name "information_schema" ! -name "performance_schema" ! -name "sys" ! -name "#mysql50#" ! -name ".cache" | xargs -I {} basename {})

	if [ -z "$VALID_FOLDERS" ]; then
		error_msg "No valid database folders found in $DB_DATA_PATH. Exiting."
		exit 1
	fi

	body_msg "📂 Available Database Folders:"
	line_break
	i=1
	for folder in $VALID_FOLDERS; do
		body_msg "$i) $folder"
		eval "DB_$i=$folder"
		i=$((i + 1))
	done
	line_break
	input_cursor "Enter the number of the database folder you want to recover:"
	while :; do
		read -r DB_CHOICE
		if [ "$DB_CHOICE" -ge 1 ] 2>/dev/null && [ "$DB_CHOICE" -lt "$i" ]; then
			eval "RECOVER_DB_NAME=\$DB_$DB_CHOICE"
			break
		fi
		error_msg "❌ Invalid selection. Please enter a number between 1 and $((i - 1)):"
	done

	body_msg "✅ Selected database folder: $RECOVER_DB_NAME"
fi

# Ensure MySQL recognizes the database before proceeding
DB_EXISTS=$(docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES LIKE '$RECOVER_DB_NAME';" | grep -o "$RECOVER_DB_NAME")

if [ -z "$DB_EXISTS" ]; then
	error_msg "Database '$RECOVER_DB_NAME' does not exist in MySQL. Creating it now..."
	docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE $RECOVER_DB_NAME;"
fi

body_msg "✅ Database '$RECOVER_DB_NAME' is now recognized in MySQL."
line_break

# Step 3: Extract and recreate tables
RECOVER_TABLES_DIR="$DB_DATA_PATH/$RECOVER_DB_NAME"

# Step 4: Loop through tables and recover them
while read -r RECOVER_TABLE_NAME; do
	body_msg "🛠️ Processing table: $RECOVER_TABLE_NAME"

	# Ensure the table exists in MySQL before discarding tablespace
	TABLE_EXISTS=$(docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "
    SHOW TABLES LIKE '$RECOVER_TABLE_NAME';" | grep -o "$RECOVER_TABLE_NAME")

	TABLE_EXISTS=$(docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "
    SHOW TABLES LIKE '$RECOVER_TABLE_NAME';" | grep -o "$RECOVER_TABLE_NAME")

	if [ -z "$TABLE_EXISTS" ]; then
		warning_msg "❌ Table '$RECOVER_TABLE_NAME' does not exist in MySQL. Attempting recovery..."

		# Drop any incomplete table that might exist
		docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "
        DROP TABLE IF EXISTS $RECOVER_TABLE_NAME;
    "

		# Extract schema from .frm file
		TABLE_SCHEMA=$(strings "$RECOVER_TABLES_DIR/$RECOVER_TABLE_NAME.frm" | grep -A 50 "CREATE TABLE" | tr -d '\n')

		if [ -z "$TABLE_SCHEMA" ]; then
			warning_msg "❗ Could not extract schema from .frm file. Enter a valid CREATE TABLE statement for '$RECOVER_TABLE_NAME':"
			read -r TABLE_SCHEMA
			if [ -z "$TABLE_SCHEMA" ]; then
				error_msg "❌ No schema provided. Skipping '$RECOVER_TABLE_NAME'."
				continue
			fi
		fi

		# Create the table properly
		docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "$TABLE_SCHEMA"

		# Verify MySQL recognizes it
		TABLE_EXISTS=$(docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "
        SHOW TABLES LIKE '$RECOVER_TABLE_NAME';" | grep -o "$RECOVER_TABLE_NAME")

		if [ -z "$TABLE_EXISTS" ]; then
			error_msg "❌ MySQL still doesn't recognize '$RECOVER_TABLE_NAME'. Skipping this table."
			continue
		fi

		success_msg "✅ Table '$RECOVER_TABLE_NAME' successfully created and recognized!"
	fi
	# Step 1: Discard old tablespace
	body_msg "🗑️ Discarding old tablespace for '$RECOVER_TABLE_NAME'..."
	docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "
        ALTER TABLE $RECOVER_TABLE_NAME DISCARD TABLESPACE;
    "

	# Step 2: Move .ibd file to the correct MySQL directory
	body_msg "♻️ Restoring .ibd file for '$RECOVER_TABLE_NAME'..."
	mv "$RECOVER_TABLES_DIR/$RECOVER_TABLE_NAME.ibd" "$DB_DATA_PATH/$RECOVER_DB_NAME/$RECOVER_TABLE_NAME.ibd"
	sudo chown mysql:mysql "$DB_DATA_PATH/$RECOVER_DB_NAME/$RECOVER_TABLE_NAME.ibd"
	sudo chmod 660 "$DB_DATA_PATH/$RECOVER_DB_NAME/$RECOVER_TABLE_NAME.ibd"

	# Step 3: Import the tablespace
	body_msg "📂 Importing tablespace for '$RECOVER_TABLE_NAME'..."
	docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -D "$RECOVER_DB_NAME" -e "
        ALTER TABLE $RECOVER_TABLE_NAME IMPORT TABLESPACE;
    "

	success_msg "✅ Successfully recovered '$RECOVER_TABLE_NAME'!"

done <"$OUTPUT_FILE"
# Step 5: Restart MySQL and Flush Tables
body_msg "🔄 Restarting MySQL..."
docker restart "$MYSQL_CONTAINER"
body_msg "⏳ Waiting for MySQL to be available..."
sleep 5

# Check if MySQL is running before continuing
until docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -e "SELECT 1;" >/dev/null 2>&1; do
	warning_msg "⚠️ MySQL is still starting..."
	sleep 3
done

success_msg "✅ MySQL is back online!"
docker exec -i "$MYSQL_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" -e "FLUSH TABLES;"

celebrate_msg "🎉 Recovery process completed for $RECOVER_DB_NAME."
