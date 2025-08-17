#!/bin/sh
# lxv.test/wordpress/one ->
# studiolxv.mysql57.test
replace_wp_url() {
	stack_name="$1"
	wp_container="$2"

	heading "Database Search & Replace"

	status_msg "DB_HOST_NAME = ${C_Yellow}${DB_HOST_NAME}${C_Reset}"
	status_msg "WORDPRESS_DB_NAME = ${C_Yellow}${WORDPRESS_DB_NAME}"
	status_msg "WORDPRESS_SERVICE_CONTAINER_NAME = ${C_Yellow}${WORDPRESS_SERVICE_CONTAINER_NAME}"
	status_msg "WORDPRESS_TABLE_PREFIX = ${C_Yellow}${WORDPRESS_TABLE_PREFIX}"
	line_break

	# Load environment variables
	source_wordpress_stack_env "$stack_name" "$wp_container"

	# Prompt for URLs
	option_question "Enter the current (old) site URL in the database:"
	line_break
	printf "%s " "$(input_cursor)"
	read old_url
	line_break

	option_question "Enter the new site URL:"
	line_break
	printf "%s " "$(input_cursor)"
	read new_url

	# Convert URLs to escaped versions
	escaped_old_url=$(printf "%s" "$old_url" | sed 's#/#\\/#g')
	escaped_new_url=$(printf "%s" "$new_url" | sed 's#/#\\/#g')

	# Confirm before proceeding (Replaces confirm_action)
	line_break
	warning_msg "This will replace:\n- '${old_url}' → '${new_url}'\n- '${escaped_old_url}' → '${escaped_new_url}'\nAcross all tables in '${WORDPRESS_DB_NAME}'."
	line_break

	status_msg "Are you sure you want to proceed? (y/n)"
	printf "%s " "$(input_cursor)"
	read confirm
	case "$confirm" in
	[yY][eE][sS] | [yY])
		success_msg "Proceeding with URL replacement..."
		;;
	*)
		error_msg "Operation canceled."
		return 1
		;;
	esac

	# Run the MYSQL 8.0 SQL command inside the MySQL container
	# 	docker exec -i "$DB_HOST_NAME" mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_USER_PASSWORD" "$WORDPRESS_DB_NAME" <<EOF
	# SET @DB_NAME = '${WORDPRESS_DB_NAME}';
	# SET @OLD_URL = '${old_url}';
	# SET @NEW_URL = '${new_url}';
	# SET @ESCAPED_OLD_URL = '${escaped_old_url}';
	# SET @ESCAPED_NEW_URL = '${escaped_new_url}';

	# -- Get the table prefix dynamically
	# SET @TABLE_PREFIX = (
	#     SELECT SUBSTRING_INDEX(table_name, '_options', 1)
	#     FROM information_schema.tables
	#     WHERE table_schema = @DB_NAME
	#     AND table_name LIKE '%_options'
	#     LIMIT 1
	# );

	# -- Generate and execute update statements
	# SET SESSION group_concat_max_len = 1000000;

	# SET @sql_command = (
	#     SELECT GROUP_CONCAT(
	#         'UPDATE $(', TABLE_NAME, ') SET $(', COLUMN_NAME, ') = REPLACE($(', COLUMN_NAME, '), \'', @OLD_URL, '\', \'', @NEW_URL, '\'); '
	#         'UPDATE $(', TABLE_NAME, ') SET $(', COLUMN_NAME, ') = REPLACE($(', COLUMN_NAME, '), \'', @ESCAPED_OLD_URL, '\', \'', @ESCAPED_NEW_URL, '\'); '
	#         SEPARATOR ' '
	#     )
	#     FROM INFORMATION_SCHEMA.COLUMNS
	#     WHERE TABLE_SCHEMA = @DB_NAME
	#     AND DATA_TYPE IN ('varchar', 'text', 'longtext')
	#     AND TABLE_NAME IS NOT NULL
	#     AND COLUMN_NAME IS NOT NULL
	# );

	# PREPARE stmt FROM @sql_command;
	# EXECUTE stmt;
	# DEALLOCATE PREPARE stmt;
	# EOF

	# Run the MYSQL 5.7 SQL command inside the MySQL container
	docker exec -i "$DB_HOST_NAME" mysql -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_USER_PASSWORD" "$WORDPRESS_DB_NAME" <<EOF
SET @DB_NAME = '${WORDPRESS_DB_NAME}';
SET @OLD_URL = '${old_url}';
SET @NEW_URL = '${new_url}';
SET @ESCAPED_OLD_URL = '${escaped_old_url}';
SET @ESCAPED_NEW_URL = '${escaped_new_url}';

-- Get the WordPress table prefix dynamically
SET @TABLE_PREFIX = (
    SELECT SUBSTRING_INDEX(table_name, '_options', 1)
    FROM information_schema.tables
    WHERE table_schema = @DB_NAME
    AND table_name LIKE '%_options'
    LIMIT 1
);

-- Generate correct UPDATE statements for each table and column individually
SELECT CONCAT('UPDATE $(', TABLE_NAME, ') SET $(', COLUMN_NAME, ') = REPLACE($(', COLUMN_NAME, '), \'', @OLD_URL, '\', \'', @NEW_URL, '\');')
INTO @update_sql
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @DB_NAME
AND DATA_TYPE IN ('varchar', 'text', 'longtext');

PREPARE stmt FROM @update_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Run second pass for escaped URLs
SELECT CONCAT('UPDATE $(', TABLE_NAME, ') SET $(', COLUMN_NAME, ') = REPLACE($(', COLUMN_NAME, '), \'', @ESCAPED_OLD_URL, '\', \'', @ESCAPED_NEW_URL, '\');')
INTO @escaped_update_sql
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @DB_NAME
AND DATA_TYPE IN ('varchar', 'text', 'longtext');

PREPARE stmt FROM @escaped_update_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
EOF

	if [ $? -eq 0 ]; then
		success_msg "✅ Successfully replaced '${old_url}' and '${escaped_old_url}' with '${new_url}' and '${escaped_new_url}' in WordPress database!"
	else
		error_msg "❌ Failed to update database. Check logs for errors."
	fi

	line_break
}
export -f replace_wp_url
