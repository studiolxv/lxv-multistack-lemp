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

echo "testing path variable -> ${LEMP_ENV_FILE}"
source ${LEMP_ENV_FILE}
#####################################################
# START DOCKER WORDPRESS

# Change to the new WordPress container directory before executing docker-compose commands
# Ensure the new WordPress container connects to the LEMP MySQL database

heading "WORDPRESS DOCKER CONTAINER"
line_break
status_msg "🚀 ${C_Reset}Starting WordPress container: ${C_Yellow}${WORDPRESS_DIR}${C_Reset}..."
line_break

# Back to the WordPress container directory
changed_to_dir_msg "${LEMP_DIR}/containers/${WORDPRESS_DIR}"
cd "$WORDPRESS_PATH"
line_break

# Check if the WordPress container configuration exists before running
wp_container_config_exists "${WORDPRESS_DIR}"

# Use WP-CLI to set up WordPress: create admin user, set up plugins, and create a page
# Install WordPress with specified DB parameters and site details
# DB_HOST should typically be the name of the service defined in the docker-compose.yml for your LEMP stack
# Start up new Wordpress Container
running_msg "% docker-compose -f \"${WORDPRESS_PATH}/docker-compose.yml\" up -d"

docker-compose -f "${WORDPRESS_DOCKER_COMPOSE_YML}" up -d

#####################################################
# DOCKER INSTALL WORDPRESS

heading "INSTALL WORDPRESS"
status_msg "Installing Wordpress with WP-CLI..."
line_break

sleep 3

docker-compose exec ${WORDPRESS_SERVICE_CONTAINER_NAME} wp core install \
	--url="https://$WORDPRESS_SUBDOMAIN" \
	--title="$WORDPRESS_SUBDOMAIN_NAME" \
	--admin_user="$WORDPRESS_ADMIN_USER" \
	--admin_password="$WORDPRESS_ADMIN_USER_PASSWORD" \
	--admin_email="$WORDPRESS_ADMIN_USER_EMAIL" \
	--dbhost="${DB_HOST_NAME}" \
	--dbname="$WORDPRESS_DB_NAME" \
	--dbuser="$WORDPRESS_DB_USER" \
	--dbpass="$WORDPRESS_DB_USER_PASSWORD" \
	--path="$WORDPRESS_CONTAINER_ROOT_PATH" \
	--allow-root 2>&1 | tee wp-cli.log

sleep 4

#####################################################
# WP-CLI: WORDPRESS OPTIONS

# Update site URL to use HTTPS
# line_break
# heading "🔄 Updating WordPress site URL to HTTPS..."
# docker-compose exec "$WORDPRESS_SERVICE_CONTAINER_NAME" wp option update home "https://$WORDPRESS_SUBDOMAIN" --allow-root
# docker-compose exec "$WORDPRESS_SERVICE_CONTAINER_NAME" wp option update siteurl "https://$WORDPRESS_SUBDOMAIN" --allow-root

#####################################################
# WP-CLI: WORDPRESS PLUGINS

# Install essential plugins
# ESSENTIAL_PLUGINS=(
# 	"classic-editor"
# 	"akismet"
# 	"wordfence"
# 	"woocommerce"
# 	"all-in-one-wp-migration"
# )

# line_break
# heading "🔌 Installing and activating essential plugins..."
# for PLUGIN in "${ESSENTIAL_PLUGINS[@]}"; do
# 	echo "Installing plugin: $PLUGIN"
# 	docker-compose exec "$WORDPRESS_CONTAINER" wp plugin install "$PLUGIN" --activate --allow-root
# done

#####################################################
# WP-CLI: ENABLE SSL FOR WORDPRESS

# Enable SSL for WordPress (Force HTTPS)

# line_break
# heading "🔒 Enforcing HTTPS in WordPress settings..."
# docker-compose exec "$WORDPRESS_CONTAINER" wp rewrite structure '/%postname%/' --allow-root
# docker-compose exec "$WORDPRESS_CONTAINER" wp option update siteurl "https://$WORDPRESS_SUBDOMAIN" --allow-root
# docker-compose exec "$WORDPRESS_CONTAINER" wp option update home "https://$WORDPRESS_SUBDOMAIN" --allow-root
# docker-compose exec "$WORDPRESS_CONTAINER" wp plugin install really-simple-ssl --activate --allow-root
# docker-compose exec "$WORDPRESS_CONTAINER" wp plugin activate really-simple-ssl --allow-root

# Flush rewrite rules

# heading "🔄 Flushing rewrite rules..."
#docker-compose exec "$WORDPRESS_CONTAINER" wp rewrite flush --hard --allow-root

#####################################################
# WP-CLI: CREATE PAGES

# line_break
# heading "📄 Creating default pages..."

# PAGES=("Home" "About Us" "Contact" "Blog")

# for PAGE in "${PAGES[@]}"; do
# 	status_msg "Creating page: $PAGE"
# 	docker-compose exec "$WORDPRESS_CONTAINER" wp post create \
# 		--post_type=page \
# 		--post_title="$PAGE" \
# 		--post_status=publish \
# 		--allow-root
# done

# # Set "Home" as the static front page
# docker-compose exec "$WORDPRESS_CONTAINER" wp option update show_on_front 'page' --allow-root
# docker-compose exec "$WORDPRESS_CONTAINER" wp option update page_on_front $(docker-compose exec "$WORDPRESS_CONTAINER" wp post list --post_type=page --format=ids --allow-root | awk '{print $1}') --allow-root

# success_msg "Default pages created!"

#####################################################
# WP-CLI: CONFIGURE WORDPRESS SETTINGS
# line_break
# heading "⚙️ Configuring WordPress settings..."

# # Set timezone
# docker-compose exec "$WORDPRESS_CONTAINER" wp option update timezone_string "America/New_York" --allow-root

# # Set permalink structure
# docker-compose exec "$WORDPRESS_CONTAINER" wp rewrite structure '/%postname%/' --allow-root
# docker-compose exec "$WORDPRESS_CONTAINER" wp rewrite flush --hard --allow-root

# # Set default admin color scheme
# docker-compose exec "$WORDPRESS_CONTAINER" wp user meta update 1 admin_color midnight --allow-root

# success_msg "WordPress settings configured!"

#########################################
# WP-CLI: INSTALL DEFAULT THEME
# public theme in the repository required
#########################################

# Set default theme
# DEFAULT_THEME="twentytwentythree"

# line_break
# heading "🎨 Installing and activating theme: $DEFAULT_THEME..."
# docker-compose exec "$WORDPRESS_CONTAINER" wp theme install "$DEFAULT_THEME" --activate --allow-root

# echo "✅ Theme setup complete!"

# Back to the Project directory
cd "${PROJECT_PATH}"

# Debugging
changed_to_dir_msg "/${PROJECT_NAME}"
status_msg "${C_Yellow}$(pwd)"
line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-16-complete.sh"
