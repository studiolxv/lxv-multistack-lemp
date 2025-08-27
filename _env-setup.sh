#!/bin/sh
. "${PROJECT_PATH}/functions/init.sh"
# debug_file_msg "$(current_basename)"
sleep 0.2
#####################################################
# DEBUG MODE
if [ "$(basename "$0")" = "start.sh" ] || [ "$(basename "$0")" = "manage.sh" ]; then
    debug_msg "🔍 Debug mode is enabled!"
fi


# Avoid infinite loops when sourcing multiple times
# if [ -n "$FUNCTIONS_PATH" ]; then
#     return
# fi

#####################################################
# ENVIRONMENT VARIABLES
# Load project path from .env
if [ -f "${PROJECT_ENV_FILE}" ]; then

    # Source the .env file
        debug_msg "Sourcing .env file"

    . "${PROJECT_ENV_FILE}"

    #####################################################
    # LOAD FUNCTIONS
    load_helper_functions
	make_scripts_executable
else
    # PROJECT (Main Directory for entire project)
    # Ensure PROJECT_PATH is set to where THIS FILE is, not the calling script
    # Determine script path correctly, whether executed or sourced
    if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
        debug_msg "📂  .env file not found. Creating one..."
    fi

    # OPERATING SYSTEM
    # Detect OS type
    export OS_TYPE="$(uname)"
    export OS_TZ="$(cat /etc/timezone 2>/dev/null || ls -l /etc/localtime | awk -F'/zoneinfo/' '{print $2}')"

    #####################################################
    # PATHS
    debug_msg "📦 PROJECT_PATH: ${PROJECT_PATH}"
    debug_msg "📦 PROJECT_ROOT: ${PROJECT_ROOT}"

    # Docker Image Platform (linux/amd64, linux/arm64, etc.) Change to your platform
    export OS_DOCKER_IMAGE_PLATFORM="linux/amd64"

    # STACKS (Multiple LEMP Stack Servers)
    export STACKS_PATH="${PROJECT_PATH}/stacks"

    # SCRIPTS (BASH scripts needed for this project to work)
    export SCRIPTS_PATH="${PROJECT_PATH}/scripts"

    # FUNCTIONS (Reusable functions for this project)
    export FUNCTIONS_PATH="${PROJECT_PATH}/functions"

	# ASSETS (Static files needed for this project to work)
    export ASSETS_PATH="${PROJECT_PATH}/assets"

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
    load_helper_functions
	make_scripts_executable
    wait

    #####################################################
    # DEFAULT LEMP STACK IMAGES FOR NEW STACKS
    export DEFAULT_DB_IMAGE="mysql:latest"
    export DEFAULT_PHP_IMAGE="php:8.5-rc-fpm-bullseye" # Needs to be FPM version
    export DEFAULT_PMA_IMAGE="phpmyadmin:latest"
    export DEFAULT_WP_IMAGE="wordpress:latest" #"wordpress:latest"
    export DEFAULT_BACKUPS_IMAGE="debian:bookworm-slim"

    #####################################################
    # VARIABLES REQUIRING FUNCTIONS

    # Detect OS type
    export OS_NAME="$(detect_os_name)"

    # VARIABLES REQUIRING FUNCTIONS
    export HOSTS_FILE=$(detect_os_hosts_file)

    # HOSTS FILE LOCAL LOOPBACK
    HOSTS_FILE_LOOPBACK_IP="$(get_local_loopback_ip)"; [ -n "$HOSTS_FILE_LOOPBACK_IP" ] || HOSTS_FILE_LOOPBACK_IP=127.0.0.1
    export HOSTS_FILE_LOOPBACK_IP

    # USERNAME
    if [ -n "$USER" ]; then
        mlusername=$USER
        elif [ -n "$LOGNAME" ]; then
        mlusername=$LOGNAME
    else
        mlusername=$(id -un 2>/dev/null || whoami 2>/dev/null)
    fi


    #####################################################
	# START INSTALL WIZARD
    heading "LXV-MULTISTACK-LEMP NEW INSTALL SETUP WIZARD"
    body_msg "Answer the following questions to begin a new installation of LXV Multistack LEMP."
    #####################################################
    # USER INPUT: ADMIN_EMAIL

    # Prompt user to specify the preferred admin email
    line_break
    section_title "DEFAULT ADMIN EMAIL" ${C_Magenta}
    example_msg "This will be used for a default email and fallbacks for email prompts" ${C_Magenta}
    line_break
    option_question "Type in your admin or preferred default email:"
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
    generating_msg "Creating new project root \"${PROJECT_NAME}/.env file\"..."
    line_break
    example_msg "Modify this root .env as needed before creating a lemp stack."
    line_break
    warning_msg "NOTE:"

    warning_msg "Project root, each stack, and each stack container requires its own .env file."
    warning_msg "Moving this project in the future will require ${C_Underline}updating paths in all .env files.${C_Reset}"
    line_break
    # Create .env file with answers
	cat >"$PROJECT_PATH/.env" <<EOF
# PROJECT: ${PROJECT_NAME}
# Created: $(date)
#
# MULTISTACK
ADMIN_EMAIL="${ADMIN_EMAIL}"
PROJECT_PATH="${PROJECT_PATH}"
PROJECT_NAME="${PROJECT_NAME}"
PROJECT_ENV_FILE="${PROJECT_ENV_FILE}"
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
DEFAULT_BACKUPS_IMAGE="${DEFAULT_BACKUPS_IMAGE}"
#
# CLI OPTIONS
opt_debug=${opt_debug} # [true|false] for debug mode for multistack
opt_debug_file_msg=${opt_debug_file_msg} # [true|false] logs files sourced/used in runtime
opt_line_breaks=${opt_line_breaks} # [true|false] for line breaks between messages
opt_dividers=${opt_dividers} # [true|false] for line dividers between cli output
opt_indent=${opt_indent} # [true|false] for indentation
opt_left_wall=${opt_left_wall} # [true|false] for left wall #
opt_heading_char="${opt_heading_char}" # [true|false] character for heading
opt_wall_char="${opt_wall_char}" # character for left wall
opt_open_docker_on_start=${opt_open_docker_on_start} # [true|false] for opening Docker on start
opt_sort="${opt_sort}" # [alpha_asc|alpha_desc|time_asc|time_desc] stacks/containers sort order
#
# INSTALLATION FLAGS

EOF

    success_msg ".env Environment variables created successfully"
    line_break
fi

debug_success_msg "✅ env-setup.sh sourced successfully"


#####################################################
	# PHPMYADMIN THEMES
	export ASSETS_PHPMYADMIN_THEMES_PATH="${ASSETS_PATH}/phpmyadmin/themes"
	if [ ! -d "${ASSETS_PHPMYADMIN_THEMES_PATH}/blueberry" ] && [ ! -d "${ASSETS_PHPMYADMIN_THEMES_PATH}/boodark-teal" ] && [ ! -d "${ASSETS_PHPMYADMIN_THEMES_PATH}/darkwolf" ]; then
		heading "PHPMYADMIN THEMES"

		mkdir -p "${ASSETS_PHPMYADMIN_THEMES_PATH}"
		example_msg "phpmyadmin default theme sucks lets grab some dark themes..."
		line_break
		cd "${ASSETS_PHPMYADMIN_THEMES_PATH}"
		if [ ! -d "${ASSETS_PHPMYADMIN_THEMES_PATH}/blueberry" ]; then
			body_msg "🫐 Downloading PHPMYADMIN theme: blueberry"
			curl -fL -O https://files.phpmyadmin.net/themes/blueberry/1.1.0/blueberry-1.1.0.zip
			unzip -q blueberry-1.1.0.zip && rm blueberry-1.1.0.zip
		fi
		if [ ! -d "${ASSETS_PHPMYADMIN_THEMES_PATH}/boodark-teal" ]; then
			body_msg "👻 Downloading PHPMYADMIN theme: boodark-teal"
			curl -fL -O https://files.phpmyadmin.net/themes/boodark-teal/1.1.0/boodark-teal-1.1.0.zip
			unzip -q boodark-teal-1.1.0.zip && rm boodark-teal-1.1.0.zip
		fi
		if [ ! -d "${ASSETS_PHPMYADMIN_THEMES_PATH}/darkwolf" ]; then
			body_msg "🐺 Downloading PHPMYADMIN theme: darkwolf"
			curl -fL -O https://files.phpmyadmin.net/themes/darkwolf/5.2/darkwolf-5.2.zip
			unzip -q darkwolf-5.2.zip && rm darkwolf-5.2.zip
		fi
		cd "${PROJECT_PATH}"
	fi
