#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# NGINX PATH

section_title "NGINX"
line_break

# Check if the LEMP_NGINX_PATH directory exists
if [ -d "${LEMP_NGINX_PATH}" ]; then
	success_msg "'${LEMP_DIR}/${NGINX_DIR}' already exists."
else
	mkdir -p "${LEMP_NGINX_PATH}"

	if [ -d "${LEMP_NGINX_PATH}" ]; then
		success_msg "'${LEMP_DIR}/${NGINX_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${LEMP_NGINX_PATH}"
	else
		error_msg "Failed to create '${LEMP_DIR}/${NGINX_DIR}' directory, check permissions or create manually."
	fi
fi

line_break

#####################################################
# NGINX CONF PATH

if [ -d "${LEMP_NGINX_CONF_PATH}" ]; then
	success_msg "'${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}' directory already exists."
else
	mkdir -p "${LEMP_NGINX_CONF_PATH}"

	if [ -d "${LEMP_NGINX_CONF_PATH}" ]; then
		success_msg "'${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}' directory created successfully."

		# Set permissions for the directory and files
		chmod -R 755 "${LEMP_NGINX_CONF_PATH}"
	else
		error_msg "Failed to create '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}' directory, check permissions or create manually."
	fi
fi

line_break

#####################################################
# NGINX CONF FILE
if [ -f "$LEMP_NGINX_CONF_FILE" ]; then
	success_msg "'${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/${LEMP_SERVER_DOMAIN_NAME}.conf' file already exists"
else
	warning_msg "'${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/${LEMP_SERVER_DOMAIN_NAME}.conf' file not found"
	line_break
	generating_msg "Generating '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/${LEMP_SERVER_DOMAIN_NAME}.conf'..."
	line_break
	cat <<EOL >"$LEMP_NGINX_CONF_FILE"
# LEMP Nginx Configuration $(date)

server {
    listen 80;
    server_name ${LEMP_SERVER_DOMAIN};

    # Serve the app without redirection
    root /usr/share/nginx/html;
    index index.php index.html;

    client_max_body_size 512M;

    location ~ \\.php\$ {
        include fastcgi_params;
        fastcgi_pass ${LEMP_SERVER_DOMAIN_NAME}-php-fpm:9000; # Adjust based on your PHP service
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
    }
}

# Catch all subdomains and return 404 (except phpMyAdmin, which is handled separately)
server {
    listen 80;
    server_name ~^(?!phpmyadmin)[^.]+\\.${LEMP_SERVER_DOMAIN_NAME}\\.${LEMP_SERVER_DOMAIN_TLD}\$;

    client_max_body_size 512M;

    location / {
        return 404;
    }
}
EOL
	line_break
	# Output generated NGINX configuration for verification
	cat_msg "$LEMP_NGINX_CONF_FILE"
	if [ -f "$LEMP_NGINX_CONF_FILE" ]; then
		success_msg "Created '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/${LEMP_SERVER_DOMAIN_NAME}.conf'"
	else
		error_msg "Failed to create '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/${LEMP_SERVER_DOMAIN_NAME}.conf', check permissions or create manually."
	fi
fi

line_break

#####################################################
# NGINX CATCHALL CONF FILE
if [ -f "$LEMP_NGINX_CATCHALL_CONF_FILE" ]; then
	success_msg "'${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/catchall.conf' file already exists"
else
	warning_msg "'${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/catchall.conf' file not found"
	line_break
	generating_msg "Generating '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/catchall.conf'..."
	line_break
	cat <<EOL >"$LEMP_NGINX_CATCHALL_CONF_FILE"
# Catch all subdomains (except phpMyAdmin) and return 404
server {
    listen 80;
    server_name ~^(?!phpmyadmin)[^.]+\\.${LEMP_SERVER_DOMAIN_NAME}\\.${LEMP_SERVER_DOMAIN_TLD}$;

    location / {
        return 404;
    }
}
EOL
	line_break
	# Output generated NGINX configuration for verification
	cat_msg "$LEMP_NGINX_CATCHALL_CONF_FILE"

	if [ -f "$LEMP_NGINX_CATCHALL_CONF_FILE" ]; then
		success_msg "Created '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/catchall.conf'"
	else
		error_msg "Failed to create '${LEMP_DIR}/${NGINX_DIR}/${NGINX_CONF_DIR}/catchall.conf', check permissions or create manually."
	fi
fi

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-10-directory-php.sh"
