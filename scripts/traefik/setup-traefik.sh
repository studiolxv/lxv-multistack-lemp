#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# TRAEFIK NETWORK
heading "DOCKER TRAEFIK NETWORK"

#####################################################
# TRAEFIK CERTS DIRECTORY

# Check if the TRAEFIK_CERTS_PATH directory exists
if [ -d "${TRAEFIK_CERTS_PATH}" ]; then
	success_msg "'${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_CERTS_DIR}' directory already exists."
else
	mkdir -p "${TRAEFIK_CERTS_PATH}"

	if [ -d "${TRAEFIK_CERTS_PATH}" ]; then
		success_msg "'${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_CERTS_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${TRAEFIK_CERTS_PATH}"
	else
		error_msg "Failed to create '${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_CERTS_DIR}' directory, check permissions or create manually."
	fi
fi

line_break_debug

#####################################################
# TRAEFIK DYNAMIC DIRECTORY

# Check if the TRAEFIK_CERTS_PATH directory exists
if [ -d "${TRAEFIK_DYNAMIC_PATH}" ]; then
	success_msg "'${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}' directory already exists."
else
	mkdir -p "${TRAEFIK_DYNAMIC_PATH}"

	if [ -d "${TRAEFIK_DYNAMIC_PATH}" ]; then
		success_msg "'${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${TRAEFIK_DYNAMIC_PATH}"
	else
		error_msg "Failed to create '${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}' directory, check permissions or create manually."
	fi
fi
#####################################################
# TRAEFIK DYNAMIC/certs.yml
# CREATE TRAEFIK CERTS FILE
line_break
section_title "TRAEFIK CERTS FILE"

# Write the evaluated variables to the certs.yml file for the container
if [ -f "$TRAEFIK_CERTS_YML_FILE" ]; then
	success_msg "'${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}/${TRAEFIK_CERTS_YML_FILE_NAME}' file already exists."
else
	warning_msg "'${LEMP_DIR}/${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}/${TRAEFIK_CERTS_YML_FILE_NAME}' file not found."
	line_break
	generating_msg "Generating certs.yml with dynamic variables..."

	# Generate certs.yml file for Docker (without export)
	cat <<EOL >"$TRAEFIK_CERTS_YML_FILE"
# Traefik SSL Certificates
tls:
  certificates:
EOL

	# Make export-env.sh executable
	chmod +x "$TRAEFIK_CERTS_YML_FILE"

	if [ -f "$TRAEFIK_CERTS_YML_FILE" ]; then
		success_msg "'${TRAEFIK_CERTS_YML_FILE_NAME}' file created successfully."
	else
		error_msg "Failed to create '${TRAEFIK_CERTS_YML_FILE_NAME}' file, check permissions or create manually."
	fi
fi


line_break

section_title "Docker Network Pruning"
docker network prune -f
# Ensure the traefik_network exists
if ! docker network inspect traefik_network >/dev/null 2>&1; then
	generating_msg "Creating traefik_network"
	docker network create traefik_network
	success_msg "Docker Network \"${C_Yellow}traefik_network${C_Reset}\" created"
else
	success_msg "Docker Network \"${C_Yellow}traefik_network${C_Reset}\" already exists"
fi

line_break

#####################################################
# TRAEFIK DOCKER CONTAINER

#
# Deploy/Update Traefik
section_title "Deploying Docker Traefik Container"

# Regenerate override aliases before (re)starting
if command -v traefik_up >/dev/null 2>&1; then
  running_msg "% traefik_up" ${C_BrightBlue}
  traefik_up
else
  # Fallback if functions not loaded
  PROJECT_PATH=${PROJECT_PATH:-"$(pwd)"}
  STACKS_PATH=${STACKS_PATH:-"$PROJECT_PATH/stacks"}
  sh "$PROJECT_PATH/scripts/traefik/update-traefik-network-overrides.sh"
  OVERRIDE_YML="${LEMP_DIR}/${TRAEFIK_DIR}/docker-compose.override.yml"
  if [ -f "$OVERRIDE_YML" ]; then
    running_msg "% docker-compose -f ${TRAEFIK_DOCKER_YML_FILE} -f $OVERRIDE_YML up -d" ${C_BrightBlue}
    docker-compose -f "${TRAEFIK_DOCKER_YML_FILE}" -f "$OVERRIDE_YML" up -d
  else
    running_msg "% docker-compose -f ${TRAEFIK_DOCKER_YML_FILE} up -d" ${C_BrightBlue}
    docker-compose -f "${TRAEFIK_DOCKER_YML_FILE}" up -d
  fi
fi

line_break
success_msg "Traefik setup complete!"
line_break
