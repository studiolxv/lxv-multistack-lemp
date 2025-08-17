#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

section_title "Removing a LEMP Stack"

# Get the first argument (stack name)
STACK_NAME="$1"
if [[ -z "${STACK_NAME}" ]]; then
	warning_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	# Select a LEMP stack using the new function, defines ${STACK_NAME}
	select_lemp_stack
else
	debug_success_msg "${C_Yellow}\$STACK_NAME${C_Reset} is defined as '${C_Yellow}${STACK_NAME}${C_Reset}'. Proceeding..."
fi

source_lemp_stack_env ${STACK_NAME}

if [[ -z "${LEMP_SERVER_DOMAIN}" ]]; then
	error_msg "${C_Yellow}\$LEMP_SERVER_DOMAIN${C_Reset} is not defined. Please set it before running the script."
	exit 1
else
	success_msg "${C_Yellow}\$LEMP_SERVER_DOMAIN${C_Reset} is defined as '${C_Yellow}${LEMP_SERVER_DOMAIN}${C_Reset}'. Proceeding..."
fi

# Ensure the LEMP stack exists
STACK_PATH="${STACKS_PATH}/${STACK_NAME}"
if [ ! -d "$STACK_PATH" ]; then
	log_error "LEMP stack ${C_Yellow}'$STACK_NAME'${C_Reset} does not exist!"
	exit 1
else
	success_msg "${C_Yellow}\$STACK_PATH${C_Reset} is defined as '${C_Yellow}${STACK_PATH}${C_Reset}'. Proceeding..."
fi

STACK_PATH="${STACKS_PATH}/${STACK_NAME}"

LEMP_SERVER_DOMAIN_NAME=$(get_env_variable_value "LEMP_SERVER_DOMAIN_NAME" "${STACKS_PATH}/${STACK_NAME}/.env")
STACK_DOMAIN_CERT_NAME="${TRAEFIK_CERTS_PATH}/${LEMP_SERVER_DOMAIN_NAME}"

line_break

# Confirm deletion
input_cursor "Are you sure you want to delete LEMP Stack ${C_Underline}${C_Yellow}${STACK_NAME}${C_Reset}? (y/n): "
line_break
printf "%s" "$(input_cursor)"
read confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	status_msg "Operation cancelled."
	exit 0
fi

# Stop & remove Docker containers
docker-compose -f "$STACK_PATH/docker-compose.yml" down --volumes --remove-orphans

# Remove stack directory
rm -rf "$STACK_PATH"

# Remove Traefik configuration
if [[ -f "$LEMP_TRAEFIK_CONFIG_YML_FILE" ]]; then
	rm "$LEMP_TRAEFIK_CONFIG_YML_FILE"
	status_msg "Removed Traefik configuration file for ${STACK_NAME}."
fi

# Remove SSL certificates
LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE=${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}
LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE=${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}

if [[ -f "${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}" || -f "${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}" ]]; then
	rm "${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}" "${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}"
	status_msg "Removed SSL certificates for ${STACK_NAME}."
fi

remove_lemp_certs_yml "${LEMP_SERVER_DOMAIN}"

# macOS: Remove old certificate if it exists
if [[ "$(uname)" == "Darwin" ]]; then
	line_break
	status_msg "🔍 MacOS detected, attempting to delete the certificate..."

	# Force quit Keychain Access
	# Check if Keychain Access is running
	if pgrep -x "Keychain Access" >/dev/null; then
		echo "🔍 Keychain Access cannot be running. Quitting..."
		osascript -e 'quit app "Keychain Access"' || killall "Keychain Access"
		echo "✅ Keychain Access has been closed."
	fi

	# Wait a second to ensure it closes
	sleep 1
	# Check if the certificate is already in the keychain
	if security find-certificate -c "${LEMP_SERVER_DOMAIN}" >/dev/null 2>&1; then
		status_msg "🔍 Found existing certificate for ${LEMP_SERVER_DOMAIN}, removing it..."
		sudo security remove-trusted-cert -d ${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}
		sleep 1
		sudo security delete-certificate -c "${LEMP_SERVER_DOMAIN}" /Library/Keychains/System.keychain
		sleep 2
	fi

	# Add the new certificate to the trusted keychain
	status_msg "🔍 Trusting the new SSL certificate for ${LEMP_SERVER_DOMAIN}..."
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}"

	sleep 3

	# Double-check if the cert is trusted
	if check_cert_in_keychain; then
		echo "✅ Certificate is now trusted."
	else
		echo "❌ Failed to trust the certificate, try manually trusting in Keychain Access."
	fi
fi

# Restart Traefik to apply changes
cd "${TRAEFIK_PATH}" || exit
docker restart traefik

section_title "Removing a LEMP Stack"
status_msg "LEMP stack ${STACK_NAME} has been removed successfully!"

cd ${PROJECT_PATH} || exit
sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
