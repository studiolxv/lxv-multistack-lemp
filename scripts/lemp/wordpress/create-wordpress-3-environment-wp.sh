#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# SOURCE LEMP STACK .ENV
if [[ -z "${STACK_NAME}" ]]; then
	status_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	# Select a LEMP stack using the new function, defines ${STACK_NAME}
	select_lemp_stack
else
	success_msg "${C_Yellow}\$STACK_NAME${C_Reset} is defined as '${C_Yellow}${STACK_NAME}${C_Reset}'. Proceeding..."
fi

source_lemp_stack_env ${STACK_NAME}

# SETUP WORDPRESS ENVIRONMENT VARIABLES
# AFTER THE CONTAINER NAME AND DOMAIN HAVE BEEN DEFINED

#####################################################
# LEMP
export PHP_PUBLIC_DIR="${PHP_PUBLIC_DIR}"
export LEMP_NETWORK_NAME="${LEMP_NETWORK_NAME}"
export DB_HOST_NAME="${DB_HOST_NAME}"

#####################################################
# WORDPRESS: WORDPRESS SITE SUBDOMAIN NAME
export WORDPRESS_SUBDOMAIN="${WORDPRESS_SUBDOMAIN_NAME}.${LEMP_SERVER_DOMAIN}"

#####################################################
# WORDPRESS: CONTAINER
export WORDPRESS_DIR="${WORDPRESS_SUBDOMAIN_NAME}"
export WORDPRESS_PATH="${LEMP_CONTAINERS_PATH}/${WORDPRESS_SUBDOMAIN_NAME}"
export WORDPRESS_CONTAINER_PATH="${LEMP_CONTAINERS_PATH}/${WORDPRESS_SUBDOMAIN_NAME}"
export WORDPRESS_CONTAINER_NAME="${LEMP_CONTAINER_NAME}_${WORDPRESS_SUBDOMAIN_NAME}_wordpress"
export WORDPRESS_SERVICE_CONTAINER_NAME="${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}-wordpress"
# export WORDPRESS_SERVICE_CONTAINER_NAME="${LEMP_SERVER_DOMAIN_NAME}-wordpress-${WORDPRESS_SUBDOMAIN_NAME}"
# Matches for Traefik's subdomain matching api ie 'wordpress-{subdomain}
# export WORDPRESS_SERVICE_CONTAINER_NAME="wordpress-${WORDPRESS_SUBDOMAIN_NAME}"

#####################################################
# WORDPRESS: TRAEFIK DYNAMIC CONFIG
export WORDPRESS_TRAEFIK_CONFIG_YML_FILE="${TRAEFIK_DYNAMIC_PATH}/lemp-${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}.yml"

#####################################################
# WORDPRESS: DIRECTORIES
export WORDPRESS_PUBLIC_DIR="${PHP_PUBLIC_DIR}"
export WORDPRESS_PUBLIC_PATH="${WORDPRESS_PATH}/${WORDPRESS_PUBLIC_DIR}"
export WORDPRESS_SECRETS_DIR="secrets"
export WORDPRESS_SECRETS_PATH="${WORDPRESS_PATH}/${WORDPRESS_SECRETS_DIR}"
# Define the path to WordPress inside the container

#####################################################
# WORDPRESS: WORDPRESS INSTALL
export WORDPRESS_CONTAINER_ROOT_PATH="/var/www/html"

#####################################################
# WORDPRESS: NGINX CONTAINER
export WORDPRESS_NGINX_SERVICE_CONTAINER_NAME="${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}-nginx"
export WORDPRESS_NGINX_PATH="${LEMP_CONTAINERS_PATH}/${WORDPRESS_SUBDOMAIN_NAME}/${NGINX_DIR}"
export WORDPRESS_NGINX_CONF_PATH="${WORDPRESS_NGINX_PATH}/conf.d"
export WORDPRESS_NGINX_CONF_FILE="${WORDPRESS_NGINX_CONF_PATH}/default.conf"

#####################################################
# WORDPRESS: DOCKER COMPOSE
export WORDPRESS_DOCKER_COMPOSE_YML="${WORDPRESS_PATH}/docker-compose.yml"

#####################################################
# WORDPRESS: ENV FILE
# Write the evaluated variables to the .env file for container
export WORDPRESS_ENV_FILE="$WORDPRESS_PATH/.env"

line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-4-container-directory.sh"
