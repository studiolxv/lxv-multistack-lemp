#!/bin/sh
wp_container_config_exists() {

	local WP_CONTAINER="$1"

	if [[ -z "$WP_CONTAINER" ]]; then
		error_msg "wp_container_config_exists() requires a ${C_Yellow}container${C_Red} name as an argument. Exiting..."
		exit 1
	fi

	heading "WORDPRESS: WP-CONFIG.PHP CHECK ${container_name}..."

	# Define the wp-config.php file path
	local WP_CONFIG_FILE="${WP_CONTAINERS_PATH}/${WP_CONTAINER}/wp-config.php"

	# Check if wp-config.php exists
	if [[ -f "$WP_CONFIG_FILE" ]]; then
		error_msg "wp-config.php already exists in Wordpress container: '${C_Yellow}$WP_CONTAINER${C_Red}'. Exiting..."
		exit 1
	else

		body_msg "${C_Status}#${C_Green}   ✅ wp-config.php not found. Proceeding..."
	fi
}
export -f wp_container_config_exists

install_wpcli_in_container() {
	local WP_CONTAINER="${1:-$wordpress}" # Use provided container name or default to 'wordpress'

	status_msg "🔍 Checking if WP-CLI is installed in '${WP_CONTAINER}'..."

	# Check if WP-CLI exists inside the container
	if docker-compose exec "${WP_CONTAINER}" wp --info >/dev/null 2>&1; then
		echo -e "${C_Status}#   ✅ WP-CLI is already installed in '${WP_CONTAINER}'."
	else
		status_msg "⚠️  WP-CLI not found. Installing now in '${WP_CONTAINER}'..."

		# Download and install WP-CLI inside the container
		docker-compose exec "${WP_CONTAINER}" bash -c "curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
            chmod +x wp-cli.phar && \
            mv wp-cli.phar /usr/local/bin/wp"

		# Verify the installation
		if docker-compose exec "${WP_CONTAINER}" wp --info >/dev/null 2>&1; then
			echo -e "${C_Status}#   ✅ WP-CLI installed successfully in '${WP_CONTAINER}'."
		else
			echo -e "${C_Red}#   ❌ WP-CLI installation failed in '${WP_CONTAINER}'. Exiting..."
			exit 1
		fi
	fi
}

export -f install_wpcli_in_container

start_wordpress() {
	stack_name=${1:-$STACK_NAME}
	wp_container=${2:-$WORDPRESS_NAME}

	# Source LEMP stack .env
	source_lemp_stack_env ${stack_name}
	docker_compose_yml_file=${WORDPRESS_DOCKER_COMPOSE_YML}

	# Check if LEMP services are running
	if ! is_docker_compose_running ${docker_compose_yml_file}; then
		running_msg "% docker-compose -f "${WORDPRESS_DOCKER_COMPOSE_YML}" up -d"
		line_break
		docker-compose -f "${WORDPRESS_DOCKER_COMPOSE_YML}" up -d
	fi
}
export -f start_wordpress
