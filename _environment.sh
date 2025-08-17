#!/bin/sh

#####################################################
# TERMINAL COLORS

export C_Reset=$(tput sgr0)
export C_Bold=$(tput bold)
export C_Underline=$(tput smul)

# Standard Colors
export C_Black=$(tput setaf 0)
export C_Red=$(tput setaf 1)
export C_Green=$(tput setaf 2)
export C_Yellow=$(tput setaf 3)
export C_Blue=$(tput setaf 4)
export C_Magenta=$(tput setaf 5)
export C_Cyan=$(tput setaf 6)
export C_White=$(tput setaf 7)

# Bright Colors
export C_BrightBlack=$(tput setaf 8)
export C_BrightRed=$(tput setaf 9)
export C_BrightGreen=$(tput setaf 10)
export C_BrightYellow=$(tput setaf 11)
export C_BrightBlue=$(tput setaf 12)
export C_BrightMagenta=$(tput setaf 13)
export C_BrightCyan=$(tput setaf 14)
export C_BrightWhite=$(tput setaf 15)

export C_Status="${C_BrightBlue}"

#####################################################
# SOURCE MESSAGE FUNCTIONS
. "${PROJECT_PATH}/functions/_messages.sh"

#####################################################
# DEBUG MODE MESSAGES

if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
if [ "$(basename "$0")" = "start.sh" ]; then
    debug_msg "🔍 Debug mode is enabled!"
fi
	debug_msg "📦 _environment.sh sourced from file: $(basename "$0")"
fi

# Avoid infinite loops when sourcing multiple times
if [ -n "$FUNCTIONS_PATH" ]; then
	return
fi

#####################################################
# LOAD FUNCTIONS
load_functions() {
	# Ensure FUNCTION_PATH is valid
	if [ ! -d "$FUNCTIONS_PATH" ]; then
		echo "❌ Error: FUNCTIONS_PATH is not set cannot source functions!" >&2
		exit 1
	else
		if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
			debug_msg "✅ FUNCTIONS_PATH is set and functions can be sourced from:"
			debug_msg "↳$FUNCTIONS_PATH"
		fi

	fi

	# Ensure functions directory exists
	if [ -d "$FUNCTIONS_PATH" ]; then
		# Source each function file in the current shell
		for file in $(find "$FUNCTIONS_PATH" -type f -name "*.sh"); do
			if [ -f "$file" ]; then
				if [ -n "$debug_file_sourcing" ] && [ "$debug_file_sourcing" = "true" ]; then
					debug_msg "📦 sourcing function file: $file"
				fi

				source "$file"
				# wait ensures any background processes (if applicable) complete first
				wait
			fi
		done
	else
		echo "❌ Error: Directory '$FUNCTIONS_PATH' does not exist." >&2
	fi
}
export -f load_functions

#####################################################
# ENVIRONMENT VARIABLES
# Load project path from .env
if [ -f "./.env" ]; then

	if [ "$(basename "$0")" = "start.sh" ]; then
	    heading ".ENV FILE"
		success_msg ".env file found"
		line_break
	fi
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		body_msg "📂   Sourcing .env file..."
		line_break
	fi

	# Source the .env file
	. ./.env

	#####################################################
	# LOAD FUNCTIONS
	load_functions

else
	# PROJECT (Main Directory for entire project)
	# Ensure PROJECT_PATH is set to where THIS FILE is, not the calling script
	# Determine script path correctly, whether executed or sourced
	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		debug_msg "📂  .env file not found. Creating one..."
	fi

	# OPERATING SYSTEM
	# Detect OS type
	export OS_TYPE="$(uname)"
	export OS_TZ="$(cat /etc/timezone 2>/dev/null || ls -l /etc/localtime | awk -F'/zoneinfo/' '{print $2}')"

	#####################################################
	# PATHS

	if [ -n "$debug_multistack" ] && [ "$debug_multistack" = "true" ]; then
		debug_msg "📦 PROJECT_PATH: ${PROJECT_PATH}"
	fi

	# Docker Image Platform (linux/amd64, linux/arm64, etc.) Change to your platform
	export OS_DOCKER_IMAGE_PLATFORM="linux/amd64"

	# Get the current directory name
	export PROJECT_NAME="$(basename "$PROJECT_PATH")"

	# STACKS (Multiple LEMP Stack Servers)
	export STACKS_PATH="${PROJECT_PATH}/stacks"

	# SCRIPTS (BASH scripts needed for this project to work)
	export SCRIPTS_PATH="${PROJECT_PATH}/scripts"

	# FUNCTIONS (Reusable functions for this project)
	export FUNCTIONS_PATH="${PROJECT_PATH}/functions"

	# TRAEFIK (Centralized Traefik Reverse Proxy for all LEMP stacks)
	export TRAEFIK_DIR="traefik"
	export TRAEFIK_PATH="${PROJECT_PATH}/${TRAEFIK_DIR}"
	export TRAEFIK_DOCKER_YML_FILE="${TRAEFIK_PATH}/docker-compose.yml"
	# DYNA CONFIGS
	export TRAEFIK_DYNAMIC_DIR="dynamic"
	export TRAEFIK_DYNAMIC_PATH="${TRAEFIK_PATH}/${TRAEFIK_DYNAMIC_DIR}"
	# CERTS/ CERTIFICATES
	export TRAEFIK_CERTS_DIR="certs"
	export TRAEFIK_CERTS_PATH="${TRAEFIK_PATH}/${TRAEFIK_CERTS_DIR}"
	export TRAEFIK_CERTS_YML_FILE_NAME="certs.yml"
	export TRAEFIK_CERTS_YML_FILE="${TRAEFIK_DYNAMIC_PATH}/${TRAEFIK_CERTS_YML_FILE_NAME}"
	# LOG FILE
	export LOG_FILE="${PROJECT_PATH}/debug.log"

	#####################################################
	# LOAD FUNCTIONS
	load_functions
	wait

	#####################################################
	# DEFAULT LEMP STACK IMAGES FOR NEW STACKS
	export DEFAULT_DB_IMAGE="mysql:latest"
	export DEFAULT_PHP_IMAGE="php:8.5-rc-fpm-bullseye" # Needs to be FPM version
	export DEFAULT_PMA_IMAGE="phpmyadmin:latest"
	export DEFAULT_WP_IMAGE="wordpress:latest" #"wordpress:latest"

	#####################################################
	# VARIABLES REQUIRING FUNCTIONS

	# Detect OS type
	export OS_NAME="$(detect_os_name)"

	# VARIABLES REQUIRING FUNCTIONS
	export HOSTS_FILE=$(detect_os_hosts_file)

	# HOSTS FILE LOCAL LOOPBACK
	HOSTS_FILE_LOOPBACK_IP="$(get_local_loopback_ip)"; [ -n "$HOSTS_FILE_LOOPBACK_IP" ] || HOSTS_FILE_LOOPBACK_IP=127.0.0.1
	export HOSTS_FILE_LOOPBACK_IP

	body_msg "${HOSTS_FILE_LOOPBACK_IP}"

	# USERNAME
	if [ -n "$USER" ]; then
	    mlusername=$USER
	elif [ -n "$LOGNAME" ]; then
	    mlusername=$LOGNAME
	else
	    mlusername=$(id -un 2>/dev/null || whoami 2>/dev/null)
	fi

    heading "NEW INSTALL SETUP WIZARD"
	body_msg "Answer the following questions to begin a new installation of Multistack LEMP."
	#####################################################
	# USER INPUT: ADMIN_EMAIL

	# Prompt user to specify the preferred admin email
	line_break
	section_title "LEMP ADMIN EMAIL"
	option_question "Type in your admin email"
	read -p "$(input_cursor)" USER_INPUT_ADMIN_EMAIL

	# If $USER_INPUT_ADMIN_EMAIL is empty
	if [ -z "$USER_INPUT_ADMIN_EMAIL" ]; then

		error_msg "No admin email provided. ${C_Reset}Using \"admin@example.com\")"

		export ADMIN_EMAIL="admin@example.com"
	else
		export ADMIN_EMAIL="$USER_INPUT_ADMIN_EMAIL"
	fi
	line_break

	heading ".ENV FILE"
	generating_msg "Creating new project root .env file..."
	warning_msg "Project root, each stack, and each stack container requires its own .env file."
	# Create .env file with answers
	cat >"$PROJECT_PATH/.env" <<EOF
# PROJECT: ${PROJECT_NAME}
# Created: $(date)
#
# MULTISTACK
ADMIN_EMAIL="${ADMIN_EMAIL}"
PROJECT_PATH="${PROJECT_PATH}"
PROJECT_NAME="${PROJECT_NAME}"
STACKS_PATH="${STACKS_PATH}"
SCRIPTS_PATH="${SCRIPTS_PATH}"
FUNCTIONS_PATH="${FUNCTIONS_PATH}"
#
# OS
OS_TZ="${OS_TZ}"
OS_NAME="${OS_NAME}"
OS_TYPE="${OS_TYPE}"
OS_DOCKER_IMAGE_PLATFORM="${OS_DOCKER_IMAGE_PLATFORM}"
HOSTS_FILE="${HOSTS_FILE}"
HOSTS_FILE_LOOPBACK_IP="${HOSTS_FILE_LOOPBACK_IP}"
#
# TRAEFIK
TRAEFIK_DIR="${TRAEFIK_DIR}"
TRAEFIK_PATH="${TRAEFIK_PATH}"
TRAEFIK_DYNAMIC_DIR="${TRAEFIK_DYNAMIC_DIR}"
TRAEFIK_DYNAMIC_PATH="${TRAEFIK_DYNAMIC_PATH}"
TRAEFIK_DOCKER_YML_FILE="${TRAEFIK_DOCKER_YML_FILE}"
#
# CERTS/ CERTIFICATES
TRAEFIK_CERTS_DIR="${TRAEFIK_CERTS_DIR}"
TRAEFIK_CERTS_PATH="${TRAEFIK_CERTS_PATH}"
TRAEFIK_CERTS_YML_FILE_NAME="${TRAEFIK_CERTS_YML_FILE_NAME}"
TRAEFIK_CERTS_YML_FILE="${TRAEFIK_CERTS_YML_FILE}"
#
# ENV FILE
PROJECT_ENV_FILE="${PROJECT_PATH}/.env"
#
# NOTIFICATIONS
ADMIN_EMAIL="${ADMIN_EMAIL}"
#
# LOG FILE
LOG_FILE="${LOG_FILE}"
# DEFAULT LEMP STACK IMAGES
DEFAULT_DB_IMAGE="${DEFAULT_DB_IMAGE}"
DEFAULT_PHP_IMAGE="${DEFAULT_PHP_IMAGE}"
DEFAULT_PMA_IMAGE="${DEFAULT_PMA_IMAGE}"
DEFAULT_WP_IMAGE="${DEFAULT_WP_IMAGE}"
EOF

generating_msg ".env Environment variables created successfully."
warning_msg "Modify these as needed before creating a lemp stack."
line_break
fi

debug_success_msg "✅ environment.sh sourced successfully."

