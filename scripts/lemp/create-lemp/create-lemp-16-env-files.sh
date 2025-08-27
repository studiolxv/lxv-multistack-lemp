#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#
# CREATE LEMP/.ENV FILE
section_title "LEMP/.ENV"

# Write the evaluated variables to the .env file for the container
if [ -f "$LEMP_ENV_FILE" ]; then
    success_msg "'${LEMP_DIR}/.env' file already exists."
else
    warning_msg "'${LEMP_DIR}/.env' file not found."
    line_break
    generating_msg "Generating .env with dynamic variables..."
    line_break
    TIMESTAMP=$(env TZ="$OS_TZ" date +"%Y-%m-%d_%I%M%S_%p_%Z")

    # Generate .env file for Docker (without export)
	cat <<EOL >"$LEMP_ENV_FILE"
# ENVIRONMENT VARIABLES
# Created $TIMESTAMP
#
# MULTISTACK
ADMIN_EMAIL="${ADMIN_EMAIL}"
PROJECT_PATH="${PROJECT_PATH}"
PROJECT_NAME="${PROJECT_NAME}"
STACKS_PATH="${STACKS_PATH}"
SCRIPTS_PATH="${SCRIPTS_PATH}"
FUNCTIONS_PATH="${FUNCTIONS_PATH}"
ASSETS_PATH="${ASSETS_PATH}"
ASSETS_PHPMYADMIN_THEMES_PATH="${ASSETS_PHPMYADMIN_THEMES_PATH}"
#
# OS
OS_TYPE="${OS_TYPE}"
OS_NAME="${OS_NAME}"
OS_TZ="${OS_TZ}"
OS_DOCKER_IMAGE_PLATFORM="${OS_DOCKER_IMAGE_PLATFORM}"
#
# LEMP DOCKER COMPOSE FILE
LEMP_DOCKER_COMPOSE_YML="${LEMP_DOCKER_COMPOSE_YML}"
#
# LEMP ENV FILE
LEMP_ENV_FILE="${LEMP_ENV_FILE}"
#
# LEMP STACK
LEMP_DIR="${LEMP_DIR}"
LEMP_STACK_NAME="${LEMP_STACK_NAME}"
LEMP_PATH="${LEMP_PATH}"
LEMP_CONTAINER_NAME="${LEMP_CONTAINER_NAME}"
LEMP_SERVER_DOMAIN_NAME="${LEMP_SERVER_DOMAIN_NAME}"
LEMP_SERVER_DOMAIN_TLD="${LEMP_SERVER_DOMAIN_TLD}"
LEMP_SERVER_DOMAIN="${LEMP_SERVER_DOMAIN}"
LEMP_NETWORK_NAME="${LEMP_NETWORK_NAME}"
#
# LEMP NETWORK DOCKER CONTAINERS
LEMP_CONTAINERS_PATH="${LEMP_CONTAINERS_PATH}"
#
# DATABASE
DB_CONTAINER_NAME="${DB_CONTAINER_NAME}"
DB_HOST_NAME="${DB_HOST_NAME}"
DB_IMAGE="${DB_IMAGE}"
DB_DIR="${DB_DIR}"
DB_PATH="${DB_PATH}"
DB_DATA_DIR="${DB_DATA_DIR}"
DB_DATA_PATH="${DB_DATA_PATH}"
DB_CONTAINER_DATA_PATH="${DB_CONTAINER_DATA_PATH}"
DB_CONF_FILE="${DB_CONF_FILE}"
DB_CONTAINER_CONF_PATH="${DB_CONTAINER_CONF_PATH}"
DB_CONTAINER_DATA_PATH="${DB_CONTAINER_DATA_PATH}"
WORDPRESS_DB_HOST="${DB_HOST_NAME}" # Match docker compose "db" service container name
#
# PHP
PHP_CONTAINER_NAME="${PHP_CONTAINER_NAME}"
PHP_PUBLIC_DIR="${PHP_PUBLIC_DIR}"
PHP_PUBLIC_PATH="${PHP_PUBLIC_PATH}"
PHP_IMAGE="${PHP_IMAGE}"
#
# PHPMYADMIN
PHPMYADMIN_CONTAINER_NAME="${PHPMYADMIN_CONTAINER_NAME}"
PHPMYADMIN_IMAGE="${PHPMYADMIN_IMAGE}"
PHPMYADMIN_DIR="${PHPMYADMIN_DIR}"
PHPMYADMIN_PATH="${PHPMYADMIN_PATH}"
PHPMYADMIN_FILE_CONF="${PHPMYADMIN_FILE_CONF}"
PHPMYADMIN_SUBDOMAIN="${PHPMYADMIN_SUBDOMAIN}"
#
# NGINX
NGINX_DIR="${NGINX_DIR}"
NGINX_CONF_DIR="${NGINX_CONF_DIR}"
LEMP_NGINX_PATH="${LEMP_NGINX_PATH}"
LEMP_NGINX_CONF_PATH="${LEMP_NGINX_CONF_PATH}"
LEMP_NGINX_CONF_FILE="${LEMP_NGINX_CONF_FILE}"
LEMP_NGINX_CATCHALL_CONF_FILE="${LEMP_NGINX_CATCHALL_CONF_FILE}"
#
# TRAEFIK
TRAEFIK_DIR="${TRAEFIK_DIR}"
TRAEFIK_PATH="${TRAEFIK_PATH}"
TRAEFIK_DYNAMIC_DIR="${TRAEFIK_DYNAMIC_DIR}"
TRAEFIK_DYNAMIC_PATH="${TRAEFIK_DYNAMIC_PATH}"
TRAEFIK_CERTS_DIR="${TRAEFIK_CERTS_DIR}"
TRAEFIK_CERTS_PATH="${TRAEFIK_CERTS_PATH}"
#
# LEMP TRAEFIK CONFIG
LEMP_TRAEFIK_CONFIG_YML_FILE="${LEMP_TRAEFIK_CONFIG_YML_FILE}"
LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE="${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}"
LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE="${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}"
#
# BACKUPS
BACKUPS_CONTAINER_NAME="${BACKUPS_CONTAINER_NAME}"
BACKUPS_DIR="${BACKUPS_DIR}"
BACKUPS_PATH="${BACKUPS_PATH}"
BACKUPS_SCRIPTS_DIR="${BACKUPS_SCRIPTS_DIR}"
BACKUPS_SCRIPTS_PATH="${BACKUPS_SCRIPTS_PATH}"
BACKUPS_CRON_DIR="${BACKUPS_CRON_DIR}"
BACKUPS_CRONTAB_FILE="${BACKUPS_CRONTAB_FILE}"
BACKUPS_CRON_SCHEDULE_DESC="${BACKUPS_CRON_SCHEDULE_DESC}"
BACKUPS_CRON_SCHEDULE="${BACKUPS_CRON_SCHEDULE}"
BACKUPS_CLEANUP_ACTION="${BACKUPS_CLEANUP_ACTION}"
BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC}"
BACKUPS_CLEANUP_SCRIPT_FILE="${BACKUPS_CLEANUP_SCRIPT_FILE}"
BACKUPS_CLEANUP_SCRIPT_FILE_PATH="${BACKUPS_CLEANUP_SCRIPT_FILE_PATH}"
BACKUPS_CLEANUP_DRY_RUN="${BACKUPS_CLEANUP_DRY_RUN}" # Dry run (only log possible cleanup actions) enable '1', disable '0'
BACKUPS_CONTAINER_BACKUPS_PATH="${BACKUPS_CONTAINER_BACKUPS_PATH}"
BACKUPS_CONTAINER_GHOST_BACKUPS_PATH="${BACKUPS_CONTAINER_GHOST_BACKUPS_PATH}"
BACKUPS_USE_OS_TRASH="${BACKUPS_USE_OS_TRASH}" # 1 moves deleted backups to the OS Trash/Recycle Bin, while 0 permanently deletes them.
BACKUPS_REQUIRE_OS_TRASH="${BACKUPS_REQUIRE_OS_TRASH}" # 1 Abort cleanup if OS Trash cmd missing, while 0 falls back to permanent deletion
#
# DATABASE SECRETS
LEMP_SECRETS_PATH="${LEMP_SECRETS_PATH}"
DB_ROOT_USER_FILE="${DB_ROOT_USER_FILE}"
DB_ROOT_USER_PASSWORD_FILE="${DB_ROOT_USER_PASSWORD_FILE}"
#
# LOG
LOG_DIR="${LOG_DIR}"
LOG_PATH="${LOG_PATH}"
LOG_CONTAINER_PATH="${LOG_CONTAINER_PATH}"
#
# DEFAULT IMAGES
DEFAULT_DB_IMAGE="${DEFAULT_DB_IMAGE}"
DEFAULT_PHP_IMAGE="${DEFAULT_PHP_IMAGE}"
DEFAULT_PMA_IMAGE="${DEFAULT_PMA_IMAGE}"
DEFAULT_WP_IMAGE="${DEFAULT_WP_IMAGE}"
DEFAULT_BACKUPS_IMAGE="${DEFAULT_BACKUPS_IMAGE}"

EOL

    # Generate lemp-env.sh file to export all variables into docker containers and into cron jobs
    EXPORT_ENV_FILE="${BACKUPS_SCRIPTS_PATH}/lemp-env.sh"
	cat <<EOL >"$EXPORT_ENV_FILE"
#!/bin/sh
# ENVIRONMENT VARIABLE EXPORTS
# Created $TIMESTAMP
# This file was created to export all variables into docker containers and into cron jobs
# See scripts/lemp-cron.sh for usage
#
# MULTISTACK
export ADMIN_EMAIL="${ADMIN_EMAIL}"
export PROJECT_PATH="${PROJECT_PATH}"
export PROJECT_NAME="${PROJECT_NAME}"
export STACKS_PATH="${STACKS_PATH}"
export SCRIPTS_PATH="${SCRIPTS_PATH}"
export FUNCTIONS_PATH="${FUNCTIONS_PATH}"
export ASSETS_PATH="${ASSETS_PATH}"
export ASSETS_PHPMYADMIN_THEMES_PATH="${ASSETS_PHPMYADMIN_THEMES_PATH}"
#
# OS
export OS_TYPE="${OS_TYPE}"
export OS_NAME="${OS_NAME}"
export OS_TZ="${OS_TZ}"
export OS_DOCKER_IMAGE_PLATFORM="${OS_DOCKER_IMAGE_PLATFORM}"
#
# LEMP DOCKER COMPOSE FILE
export LEMP_DOCKER_COMPOSE_YML="${LEMP_DOCKER_COMPOSE_YML}"
#
# LEMP ENV FILE
export LEMP_ENV_FILE="${LEMP_ENV_FILE}"
#
# LEMP STACK
export LEMP_DIR="${LEMP_DIR}"
export LEMP_STACK_NAME="${LEMP_STACK_NAME}"
export LEMP_PATH="${LEMP_PATH}"
export LEMP_CONTAINER_NAME="${LEMP_CONTAINER_NAME}"
export LEMP_SERVER_DOMAIN_NAME="${LEMP_SERVER_DOMAIN_NAME}"
export LEMP_SERVER_DOMAIN_TLD="${LEMP_SERVER_DOMAIN_TLD}"
export LEMP_SERVER_DOMAIN="${LEMP_SERVER_DOMAIN}"
export LEMP_NETWORK_NAME="${LEMP_NETWORK_NAME}"
#
# LEMP NETWORK DOCKER CONTAINERS
export LEMP_CONTAINERS_PATH="${LEMP_CONTAINERS_PATH}"
#
# DATABASE
export CONTAINER_NAME="${CONTAINER_NAME}"
export DB_HOST_NAME="${DB_HOST_NAME}"
export DB_IMAGE="${DB_IMAGE}"
export DB_DIR="${DB_DIR}"
export DB_PATH="${DB_PATH}"
export DB_DATA_DIR="${DB_DATA_DIR}"
export DB_DATA_PATH="${DB_DATA_PATH}"
export DB_CONTAINER_DATA_PATH="${DB_CONTAINER_DATA_PATH}"
export DB_CONF_FILE="${DB_CONF_FILE}"
export DB_CONTAINER_CONF_PATH="${DB_CONTAINER_CONF_PATH}"
export DB_CONTAINER_DATA_PATH="${DB_CONTAINER_DATA_PATH}"
export WORDPRESS_DB_HOST="${DB_HOST_NAME}" # Match docker compose "db" service container name
#
# PHP
export PHP_CONTAINER_NAME="${PHP_CONTAINER_NAME}"
export PHP_PUBLIC_DIR="${PHP_PUBLIC_DIR}"
export PHP_PUBLIC_PATH="${PHP_PUBLIC_PATH}"
export PHP_IMAGE="${PHP_IMAGE}"
#
# PHPMYADMIN
export PHPMYADMIN_CONTAINER_NAME="${PHPMYADMIN_CONTAINER_NAME}"
export PHPMYADMIN_IMAGE="${PHPMYADMIN_IMAGE}"
export PHPMYADMIN_DIR="${PHPMYADMIN_DIR}"
export PHPMYADMIN_PATH="${PHPMYADMIN_PATH}"
export PHPMYADMIN_FILE_CONF="${PHPMYADMIN_FILE_CONF}"
#
# NGINX
export NGINX_DIR="${NGINX_DIR}"
export NGINX_CONF_DIR="${NGINX_CONF_DIR}"
export LEMP_NGINX_PATH="${LEMP_NGINX_PATH}"
export LEMP_NGINX_CONF_PATH="${LEMP_NGINX_CONF_PATH}"
export LEMP_NGINX_CONF_FILE="${LEMP_NGINX_CONF_FILE}"
export LEMP_NGINX_CATCHALL_CONF_FILE="${LEMP_NGINX_CATCHALL_CONF_FILE}"
#
# TRAEFIK
export TRAEFIK_DIR="${TRAEFIK_DIR}"
export TRAEFIK_PATH="${TRAEFIK_PATH}"
export TRAEFIK_DYNAMIC_DIR="${TRAEFIK_DYNAMIC_DIR}"
export TRAEFIK_DYNAMIC_PATH="${TRAEFIK_DYNAMIC_PATH}"
export TRAEFIK_CERTS_DIR="${TRAEFIK_CERTS_DIR}"
export TRAEFIK_CERTS_PATH="${TRAEFIK_CERTS_PATH}"
#
# LEMP TRAEFIK CONFIG
export LEMP_TRAEFIK_CONFIG_YML_FILE="${LEMP_TRAEFIK_CONFIG_YML_FILE}"
export LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE="${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}"
export LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE="${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}"
#
# BACKUPS
export BACKUPS_CONTAINER_NAME="${BACKUPS_CONTAINER_NAME}"
export BACKUPS_DIR="${BACKUPS_DIR}"
export BACKUPS_PATH="${BACKUPS_PATH}"
export BACKUPS_SCRIPTS_DIR="${BACKUPS_SCRIPTS_DIR}"
export BACKUPS_SCRIPTS_PATH="${BACKUPS_SCRIPTS_PATH}"
export BACKUPS_CRON_DIR="${BACKUPS_CRON_DIR}"
export BACKUPS_CRONTAB_FILE="${BACKUPS_CRONTAB_FILE}"
export BACKUPS_CRON_SCHEDULE_DESC="${BACKUPS_CRON_SCHEDULE_DESC}"
export BACKUPS_CRON_SCHEDULE="${BACKUPS_CRON_SCHEDULE}"
export BACKUPS_CLEANUP_ACTION="${BACKUPS_CLEANUP_ACTION}"
export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC}"
export BACKUPS_CLEANUP_SCRIPT_FILE="${BACKUPS_CLEANUP_SCRIPT_FILE}"
export BACKUPS_CLEANUP_SCRIPT_FILE_PATH="${BACKUPS_CLEANUP_SCRIPT_FILE_PATH}"
export BACKUPS_CLEANUP_DRY_RUN="${BACKUPS_CLEANUP_DRY_RUN}" # Dry run (only log possible cleanup actions) enable '1', disable '0'
export BACKUPS_CONTAINER_BACKUPS_PATH="${BACKUPS_CONTAINER_BACKUPS_PATH}"
export BACKUPS_CONTAINER_GHOST_BACKUPS_PATH="${BACKUPS_CONTAINER_GHOST_BACKUPS_PATH}"
export BACKUPS_USE_OS_TRASH="${BACKUPS_USE_OS_TRASH}" # 1 moves deleted backups to the OS Trash/Recycle Bin, while 0 permanently deletes them.
export BACKUPS_REQUIRE_OS_TRASH="${BACKUPS_REQUIRE_OS_TRASH}" # 1 Abort cleanup if OS Trash cmd missing, while 0 falls back to permanent deletion
#
# DATABASE SECRETS
export LEMP_SECRETS_PATH="${LEMP_SECRETS_PATH}"
export DB_ROOT_USER_FILE="${DB_ROOT_USER_FILE}"
export DB_ROOT_USER_PASSWORD_FILE="${DB_ROOT_USER_PASSWORD_FILE}"
#
# LOG
export LOG_DIR="${LOG_DIR}"
export LOG_PATH="${LOG_PATH}"
export LOG_CONTAINER_PATH="${LOG_CONTAINER_PATH}"
#
# # TERMINAL COLORS (tput)
# export C_Reset=\$(tput sgr0)
# export C_Bold=\$(tput bold)
# export C_Underline=\$(tput smul)
# export C_Black=\$(tput setaf 0)
# export C_Red=\$(tput setaf 1)
# export C_Green=\$(tput setaf 2)
# export C_Yellow=\$(tput setaf 3)
# export C_Blue=\$(tput setaf 4)
# export C_Magenta=\$(tput setaf 5)
# export C_Cyan=\$(tput setaf 6)
# export C_White=\$(tput setaf 7)
# export C_BrightBlack=\$(tput setaf 8)
# export C_BrightRed=\$(tput setaf 9)
# export C_BrightGreen=\$(tput setaf 10)
# export C_BrightYellow=\$(tput setaf 11)
# export C_BrightBlue=\$(tput setaf 12)
# export C_BrightMagenta=\$(tput setaf 13)
# export C_BrightCyan=\$(tput setaf 14)
# export C_BrightWhite=\$(tput setaf 15)

# TERMINAL COLORS (Truecolor-ready; no tput)
export C_Reset='\033[0m';
export C_Bold='\033[1m';
export C_Underline='\033[4m'
# Standard (24-bit examples; swap to taste)
export C_Black='\033[38;2;0;0;0m'
export C_Red='\033[38;2;205;0;0m'
export C_Green='\033[38;2;0;205;0m'
export C_Yellow='\033[38;2;205;205;0m'
export C_Blue='\033[38;2;0;0;205m'
export C_Magenta='\033[38;2;205;0;205m'
export C_Cyan='\033[38;2;0;205;205m'
export C_White='\033[38;2;229;229;229m'
# Bright
export C_BrightBlack='\033[38;2;127;127;127m'
export C_BrightRed='\033[38;2;255;0;0m'
export C_BrightGreen='\033[38;2;0;255;0m'
export C_BrightYellow='\033[38;2;255;255;0m'
export C_BrightBlue='\033[38;2;0;0;255m'
export C_BrightMagenta='\033[38;2;255;0;255m'
export C_BrightCyan='\033[38;2;0;255;255m'
export C_BrightWhite='\033[38;2;255;255;255m'
export C_DockerBlue='\033[38;2;36;150;237m'  # #2496ED

#
# FUNCTIONS
get_timestamp() {
	echo "\$(env TZ="\$OS_TZ" date +"%Y-%m-%d_%H%M%S_%Z")"
}

get_local_timestamp() {
	echo "\$(env TZ="\$OS_TZ" date +"%Y-%m-%d %H:%M%p %Z")"
}

get_local_time() {
	echo "\$(env TZ="\$OS_TZ" date +"%H:%M%p")"
}

get_today_dir() {
	echo "\$(env TZ="\$OS_TZ" date +"%Y-%m-%d")"
}

backup_heading() {
    # terminal (colored)
    [ -t 2 ] && printf '%s\n' "----------------------------------------------------" >&2
    [ -t 2 ] && printf '%s\n' "" >&2
    [ -t 2 ] && printf '%s\n' "\$1" >&2
    [ -t 2 ] && printf '%s\n' "" >&2
    # file (plain)
    printf '%s\n'"\$1" >> "\${LOG_CONTAINER_PATH}/backup.log"
}

backup_section_end() {
    # terminal (colored)
    [ -t 2 ] && printf '%s\n' "----------------------------------------------------" >&2
    [ -t 2 ] && printf '%s\n' "\$1" >&2
    [ -t 2 ] && printf '%s\n' "----------------------------------------------------" >&2
    # file (plain)
    printf '%s\n'"\$1" >> "\${LOG_CONTAINER_PATH}/backup.log"
}

backup_log() {
    terminal_stamp="\$(get_local_timestamp)|\$(basename \$0)]"
    log_stamp="[\$(get_timestamp)|\$(basename \$0)]"
    # Docker logs already have timestamps setting
    # printf '%s%s\n' "\${terminal_stamp}" "\${1}" >&2
    printf '%s\n' "\${1}" >&2
    # file (plain)
    printf '%s %s\n' "\${log_stamp}" "\${1}" >> "\${LOG_CONTAINER_PATH}/backup.log"
}

backup_cleanup_file_log() {
    # terminal (colored)
    [ -t 2 ] && printf '%s\n' "\$1" >&2
    # file (plain)
    printf '%s\n' "- \$1" >> "\${LOG_CONTAINER_PATH}/backup.log"
}

export MYSQL_USER=\$(cat /run/secrets/db_root_user 2>/dev/null)
export MYSQL_ROOT_PASSWORD=\$(cat /run/secrets/db_root_user_password 2>/dev/null)
export MYSQL_PWD="\$MYSQL_ROOT_PASSWORD"

backup_log "📄 Exported Variables \$(basename "\$0") >>>"

EOL

    # Make export-env.sh executable
    chmod +x "$EXPORT_ENV_FILE"

    if [ -f "$LEMP_ENV_FILE" ] && [ -f "$EXPORT_ENV_FILE" ]; then
        success_msg "${LEMP_DIR}/.env and ${LEMP_DIR}/scripts/lemp-env.sh files created successfully"
    else
        error_msg "Failed to create ${LEMP_DIR}/.env or lemp-env.sh, please check manually."
    fi
fi

#
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-17-complete.sh"
