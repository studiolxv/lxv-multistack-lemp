#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# PHP
line_break
section_title "PHP"

#####################################################
# PHP PATH

if [ -d "${LEMP_PHP_PATH}" ]; then
line_break
	success_msg "'${LEMP_DIR}/${PHP_DIR}' directory already exists."
else
	mkdir -p "${LEMP_PHP_PATH}"

	if [ -d "${LEMP_PHP_PATH}" ]; then
line_break
		success_msg "'${LEMP_DIR}/${PHP_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${LEMP_PHP_PATH}"
	else
line_break
		error_msg "Failed to create '${LEMP_DIR}/${PHP_DIR}' directory, check permissions or create manually."
	fi
fi

#####################################################
# PHP INI FILE

# Check if the PHP ini configuration file already exists
if [ -f "$LEMP_PHP_FILE_INI" ]; then
line_break
	success_msg "'php/php.ini' file already exists"
else
	line_break
	generating_msg "Generating 'php.ini' file with dynamic variables..."
	line_break
	cat <<EOL >"$LEMP_PHP_FILE_INI"
# LEMP php.ini
memory_limit = -1
max_execution_time = 0
max_input_time = -1
upload_max_filesize = 2G
post_max_size = 2G
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = On
# date.timezone = "Phoenix/Arizona"
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1
EOL

	# Output generated 'php/php.ini' for verification
	cat_msg "$LEMP_PHP_FILE_INI"
	line_break

	if [ -f "$LEMP_PHP_FILE_INI" ]; then
		success_msg "'php/php.ini' written to created successfully!"
	else
		error_msg "Failed to create 'php/php.ini', check permissions or create manually."
	fi
fi

line_break

section_title "PHP-FPM IMAGE"

if [ -n "${DEFAULT_PHP_IMAGE:-}" ]; then
    input_cursor "DEFAULT_PHP_IMAGE is defined: $DEFAULT_PHP_IMAGE"
	PHP_IMAGE="$DEFAULT_PHP_IMAGE"
else
    warning_msg "DEFAULT_PHP_IMAGE is not defined"

	warning_msg "NOTE: FPM version required."
	warning_msg "Typing in a non-FPM PHP image (like php:8.3 or php:8.3-apache) will break the php serving files from \"${LEMP_DIR}/html\" that expect an FPM listener on port 9000."
	warning_msg "This php version you are picking now is completely separate from any Wordpress container image's PHP version you create within this stack."
	warning_msg "You can use any PHP version you want here, even if it is different from the Wordpress image's PHP version."
	line_break
	body_msg "🔃   Fetching latest docker images of PHP... be patient, this may take a few minutes."

	PHP_VERSIONS=$(fetch_all_latest_minor_versions php '(fpm$|fpm-)')


	# Dynamically populate selection list
	INDEX=1
	AVAILABLE_IMAGES=""
	line_break
	section_title "PHP VERSION OPTIONS" ${C_Magenta}

	# Add PHP images to selection
	for VERSION in $PHP_VERSIONS; do
		AVAILABLE_IMAGES="$AVAILABLE_IMAGES\n$INDEX php:$VERSION"
		option_msg "$INDEX. php:$VERSION" ${C_Magenta}
		INDEX=$((INDEX + 1))
	done

	# Add custom option
	option_msg "$INDEX. Enter your own" ${C_Magenta}

	line_break
	option_question "Select your preferred PHP Docker image:"

	# Read user input dynamically
	while true; do
		printf "%s" "$(input_cursor)"
		read CHOICE

		# Find the matching choice
		CHOSEN_IMAGE=$(printf "%b" "$AVAILABLE_IMAGES" | awk -v choice="$CHOICE" '$1 == choice {print $2}')

		if [ -n "$CHOSEN_IMAGE" ]; then
			PHP_IMAGE="$CHOSEN_IMAGE"
			break
		elif [ "$CHOICE" -eq "$INDEX" ]; then
			line_break
			option_msg "Other: Enter your preferred PHP Docker image tag (e.g. \"php:8.1-fpm\"):"
			printf "%s" "$(input_cursor)"
			read PHP_IMAGE
			PHP_IMAGE="${PHP_IMAGE}"
			break
		else
			error_msg "Invalid choice, please try again."
		fi
	done

	input_cursor "Selected PHP image: ${C_Magenta}${PHP_IMAGE}${C_Reset}"
fi

line_break

#####################################################
# EXPORT
export PHP_IMAGE="${PHP_IMAGE}"
export PHPMYADMIN_FILE_CONF="${PHPMYADMIN_PATH}/phpmyadmin.conf"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-11-directory-phpmyadmin.sh"
