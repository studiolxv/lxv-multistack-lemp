#!/bin/sh
wp_container_config_exists() {
    local WORDPRESS_PUBLIC_PATH="${1:-$WORDPRESS_PUBLIC_PATH}"
    local wp_config="${WORDPRESS_PUBLIC_PATH}/wp-config.php"

    if [ -f "$wp_config" ]; then
        return 0  # true
    else
        return 1  # false
    fi
}


install_wpcli_in_container() {
	local WORDPRESS_SERVICE_CONTAINER_NAME="${1:-$WORDPRESS_SERVICE_CONTAINER_NAME}" # Use provided container name or default to 'wordpress'

	status_msg "🔍 Checking if WP-CLI is installed in '${WORDPRESS_SERVICE_CONTAINER_NAME}'..."

	# Check if WP-CLI exists inside the container
	if docker-compose exec "${WORDPRESS_SERVICE_CONTAINER_NAME}" wp --info >/dev/null 2>&1; then
		echo -e "${C_Status}#   ✅ WP-CLI is already installed in '${WORDPRESS_SERVICE_CONTAINER_NAME}'."
	else
		status_msg "⚠️  WP-CLI not found. Installing now in '${WORDPRESS_SERVICE_CONTAINER_NAME}'..."

		# Download and install WP-CLI inside the container
		docker-compose exec "${WORDPRESS_SERVICE_CONTAINER_NAME}" bash -c "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
            chmod +x wp-cli.phar && \
            mv wp-cli.phar /usr/local/bin/wp"

		# Verify the installation
		if docker-compose exec "${WORDPRESS_SERVICE_CONTAINER_NAME}" wp --info >/dev/null 2>&1; then
			echo -e "${C_Status}#   ✅ WP-CLI installed successfully in '${WORDPRESS_SERVICE_CONTAINER_NAME}'."
		else
			echo -e "${C_Red}#   ❌ WP-CLI installation failed in '${WORDPRESS_SERVICE_CONTAINER_NAME}'. Exiting..."
			# exit 1
		fi
	fi
}



start_wordpress() {
	stack_name=${1:-$STACK_NAME}
	wp_container=${2:-$WORDPRESS_NAME}

	# Source LEMP stack .env
	source_lemp_stack_env ${stack_name}

	# Check if LEMP services are running
	if ! is_docker_compose_running ${WORDPRESS_DOCKER_COMPOSE_YML}; then
		docker-compose -f "${WORDPRESS_DOCKER_COMPOSE_YML}" up -d
	fi
}

