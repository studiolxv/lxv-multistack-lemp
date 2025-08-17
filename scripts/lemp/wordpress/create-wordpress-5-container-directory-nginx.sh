#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

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

#####################################################
# NGINX PATH

heading "CONFIGURING NGINX"
line_break

# Check if the WORDPRESS_NGINX_PATH directory exists
if [ -d "${WORDPRESS_NGINX_PATH}" ]; then
	success_msg "'${WORDPRESS_NGINX_PATH}' already exists."
else
	generating_msg "'${WORDPRESS_NGINX_CONF_PATH}'..."

	mkdir -p "${WORDPRESS_NGINX_PATH}"

	if [ -d "${WORDPRESS_NGINX_PATH}" ]; then
		# Set permissions for the directory and files
		chmod -R 755 "${WORDPRESS_NGINX_PATH}"
	else
		error_msg "Failed to create '${WORDPRESS_NGINX_PATH}' directory, check permissions or create manually."
	fi
fi

line_break

#####################################################
# NGINX CONF PATH

if [ -d "${WORDPRESS_NGINX_CONF_PATH}" ]; then
	success_msg "'${WORDPRESS_NGINX_CONF_PATH}' directory already exists."
else
	generating_msg "'${WORDPRESS_NGINX_CONF_PATH}'..."

	mkdir -p "${WORDPRESS_NGINX_CONF_PATH}"

	if [ -d "${WORDPRESS_NGINX_CONF_PATH}" ]; then

		# Set permissions for the directory and files
		chmod -R 755 "${WORDPRESS_NGINX_CONF_PATH}"
	else
		error_msg "Failed to create '${WORDPRESS_NGINX_CONF_PATH}' directory, check permissions or create manually."
	fi
fi

line_break

#####################################################
# NGINX CONF FILE
# Check if the NGINX Local CA configuration file already exists
if [ -f "$WORDPRESS_NGINX_CONF_FILE" ]; then
	success_msg "'${WORDPRESS_NGINX_CONF_FILE}' file already exists"
else
	generating_msg "Generating '${WORDPRESS_NGINX_CONF_FILE}'..."

	cat <<EOL >"$WORDPRESS_NGINX_CONF_FILE"
# WORDPRESS Nginx Configuration $(date)
server {
    listen 80;
    server_name ${WORDPRESS_SUBDOMAIN};

    # Serve the app without redirection
    root /usr/share/nginx/html;
    index index.php index.html;

    location ~ \\.php\$ {
        include fastcgi_params;
        fastcgi_pass ${LEMP_SERVER_DOMAIN_NAME}-php-fpm:9000; # Adjust based on your PHP service
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
    }
}

# Catch all subdomains except this WordPress subdomain & phpMyAdmin
server {
    listen 80;
    server_name ~^(?!(${WORDPRESS_SUBDOMAIN_NAME}|phpmyadmin))[^.]+\\.${LEMP_SERVER_DOMAIN_NAME}\\.${LEMP_SERVER_DOMAIN_TLD}\$;

    location / {
        return 404;
    }
}
EOL

	# Output generated NGINX configuration for verification
	cat_msg "$WORDPRESS_NGINX_CONF_FILE"

	line_break

	if [ -f "$WORDPRESS_NGINX_CONF_FILE" ]; then
		success_msg "Created '${WORDPRESS_NGINX_CONF_PATH}/default-local.conf'"
	else
		error_msg "Failed to create '${WORDPRESS_NGINX_CONF_PATH}/default-local.conf', check permissions or create manually."
	fi
fi

line_break

#####################################################
# CREATE LEMP STACK - WORDPRESS CONTAINER
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-6-directory-PUBLIC.sh"
