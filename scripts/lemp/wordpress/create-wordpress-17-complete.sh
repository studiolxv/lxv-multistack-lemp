#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# SOURCE LEMP STACK .ENV
if [[ -z "${STACK_NAME}" ]]; then
	warning_msg "${C_Yellow}\$STACK_NAME${C_Reset} is not defined, please select a LEMP stack."
	# Select a LEMP stack using the new function, defines ${STACK_NAME}
	select_lemp_stack
else
	debug_success_msg "${C_Yellow}\$STACK_NAME${C_Reset} is defined as '${C_Yellow}${STACK_NAME}${C_Reset}'. Proceeding..."
fi

source_lemp_stack_env ${STACK_NAME}

# # Start the WordPress container
# cd "$WORDPRESS_LEMP_CONTAINER_PATH" || exit 1
# docker-compose up -d

status_msg "WordPress container ${WORDPRESS_SUBDOMAIN_NAME} added to ${STACK_NAME}!"

#####################################################
# WAIT TIL CONTAINER READY

# Wait for the WordPress service container to be healthy or running
if ! wait_for_container_ready "$WORDPRESS_SERVICE_CONTAINER_NAME" 180 2; then
    warning_msg "${C_Yellow}Timed out waiting for '$WORDPRESS_SERVICE_CONTAINER_NAME' to be healthy.${C_Reset} Proceeding anyway."
fi

#####################################################
# Wait for WP CLI to report installed, and for HTTP to return 200/302 before opening browser
WP_READY_TIMEOUT=${WP_READY_TIMEOUT:-120}
WP_PATH_IN_CONTAINER="${WORDPRESS_CONTAINER_PATH:-/var/www/html}"
end=$(( $(date +%s) + WP_READY_TIMEOUT ))

# 1) Wait for wp core is-installed
while ! docker exec "$WORDPRESS_SERVICE_CONTAINER_NAME" sh -lc "wp core is-installed --path='${WP_PATH_IN_CONTAINER}' --allow-root" >/dev/null 2>&1; do
    [ $(date +%s) -ge $end ] && { warning_msg "Timed out waiting for WordPress to report installed."; break; }
    sleep 2
done

# 2) Wait for HTTP to be up (2xx/3xx)
SITE_URL="https://${WORDPRESS_SUBDOMAIN}"
end=$(( $(date +%s) + WP_READY_TIMEOUT ))
while :; do
    CODE=$(curl -ks -o /dev/null -w '%{http_code}' "$SITE_URL")
    case "$CODE" in 200|201|202|203|204|301|302|307|308) break;; esac
    [ $(date +%s) -ge $end ] && { warning_msg "Timed out waiting for HTTP at $SITE_URL (last code: $CODE)"; break; }
    sleep 2
done

#####################################################
# WORDPRESS: SUCCESS MESSAGE

line_break
heading "SUCCESS"
success_msg "🎉 Wordpress Container \"${C_Magenta}${WORDPRESS_SUBDOMAIN}${C_Reset}\" successfully set up."
line_break

# Output success message
wordpress_info "${LEMP_SERVER_DOMAIN}"

# Open the default browser to the WordPress site and phpMyAdmin
open_link "https://$WORDPRESS_PHPMYADMIN_SUBDOMAIN"
open_link "https://$WORDPRESS_SUBDOMAIN"
open_link "https://$WORDPRESS_SUBDOMAIN/wp-admin"

# Show DB credentials popup for user convenience
    show_popup "Success! New WordPress installed!" "
You new WordPress has been installed use the following credentials to log in.

Stack/Container
${STACK_NAME}/${WORDPRESS_DIR}

phpMyAdmin
https://${WORDPRESS_PHPMYADMIN_SUBDOMAIN}

Database
${WORDPRESS_DB_NAME}
User:
${WORDPRESS_DB_USER}
Password:
${WORDPRESS_DB_PASSWORD}

Log into ${WORDPRESS_TITLE} Wordpress admin with new admin credentials:
${WORDPRESS_URL}/wp-admin
User:
${WORDPRESS_ADMIN_USER}
Password:
${WORDPRESS_ADMIN_USER_PASSWORD}
"
line_break
# wait
sh "${SCRIPTS_PATH}/lemp/wordpress/manage-wordpress.sh" "${STACK_NAME}" "${WORDPRESS_DIR}"




