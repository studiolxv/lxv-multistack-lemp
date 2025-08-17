#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

section_title "PHPMYADMIN"

# PHPMYADMIN PATH
if [ -d "${PHPMYADMIN_PATH}" ]; then
	success_msg "'${LEMP_DIR}/${PHPMYADMIN_DIR}' directory already exists."
else
	mkdir -p "${PHPMYADMIN_PATH}"

	if [ -d "${PHPMYADMIN_PATH}" ]; then
		success_msg "'${LEMP_DIR}/${PHPMYADMIN_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${PHPMYADMIN_PATH}"
	else
		error_msg "Failed to create '${LEMP_DIR}/${PHPMYADMIN_DIR}' directory, check permissions or create manually."
	fi
fi

line_break

#####################################################
# PHPMYADMIN CONF FILE

# Check if the PHP ini configuration file already exists
if [ -f "$PHPMYADMIN_FILE_CONF" ]; then
	success_msg "'${LEMP_DIR}/${PHPMYADMIN_DIR}/phpmyadmin.conf' file already exists"
else
	warning_msg "'${LEMP_DIR}/${PHPMYADMIN_DIR}/phpmyadmin.conf' file not found"
	line_break
	generating_msg "Generating '${LEMP_DIR}/${PHPMYADMIN_DIR}/phpmyadmin.conf' file with dynamic variables..."
	line_break
	cat <<EOL >"$PHPMYADMIN_FILE_CONF"
# LEMP phpmyadmin/phpmyadmin.conf
ServerName phpmyadmin.${LEMP_SERVER_DOMAIN}
EOL

	# Output generated '${LEMP_DIR}/${PHPMYADMIN_DIR}/phpmyadmin.conf' for verification
	cat_msg "$PHPMYADMIN_FILE_CONF"
	line_break

	if [ -f "$PHPMYADMIN_FILE_CONF" ]; then
		success_msg "'${LEMP_DIR}/${PHPMYADMIN_DIR}/phpmyadmin.conf' written to created successfully!"
	else
		error_msg "Failed to create '${LEMP_DIR}/${PHPMYADMIN_DIR}/phpmyadmin.conf', check permissions or create manually."
	fi
fi



# Fetch phpMyAdmin versions using the same function
line_break

body_msg "🔃   Fetching latest docker images of phpMyAdmin... be patient, this may take a few minutes."

PHPMYADMIN_VERSIONS=$(fetch_all_latest_minor_versions "phpmyadmin")

# Dynamically populate selection list
INDEX=1
AVAILABLE_IMAGES=""

line_break
section_title "PHPMYADMIN IMAGE" ${C_Magenta}

# Add phpMyAdmin images to selection
for VERSION in $PHPMYADMIN_VERSIONS; do
	AVAILABLE_IMAGES="$AVAILABLE_IMAGES\n$INDEX phpmyadmin:$VERSION"
	option_msg "$INDEX. phpmyadmin:$VERSION" ${C_Magenta}
	INDEX=$((INDEX + 1))
done

# Add custom option
option_msg "$INDEX. Other: Enter your own" ${C_Magenta}

line_break
option_question "Select your preferred phpMyAdmin Docker image:"

# Read user input dynamically
while true; do

	printf "%s" "$(input_cursor)"
	read CHOICE

	# Find the matching choice
	CHOSEN_IMAGE=$(printf "%b" "$AVAILABLE_IMAGES" | awk -v choice="$CHOICE" '$1 == choice {print $2}')

	if [ -n "$CHOSEN_IMAGE" ]; then
		export PHPMYADMIN_IMAGE="$CHOSEN_IMAGE"
		break
	elif [ "$CHOICE" -eq "$INDEX" ]; then
		status_msg "Other: Enter your preferred phpMyAdmin Docker image (e.g. phpmyadmin:5.2)"
		printf "%s" "$(input_cursor)"
		read PHPMYADMIN_IMAGE
		export PHPMYADMIN_IMAGE="${PHPMYADMIN_IMAGE}"
		break
	else
		error_msg "Invalid choice, please try again."
	fi
done

input_cursor "Selected phpMyAdmin image: ${C_Magenta}$PHPMYADMIN_IMAGE"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-12-add-domain-host.sh"
