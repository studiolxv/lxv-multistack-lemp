#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

line_break
heading "TRAEFIK: DYNAMIC CONFIG"
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
# TRAEFIK YML

# Check if the .yml file already exists
line_break
if [ -f "$WORDPRESS_TRAEFIK_CONFIG_YML_FILE" ]; then
	success_msg "'traefik/dynamic/lemp-${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}.yml' file already exists:"
else
	warning_msg "'traefik/dynamic/lemp-${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}.yml' file not found. Let's create one..."
	line_break
	generating_msg "Generating 'traefik/dynamic/lemp-${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}.yml' file..."
	line_break
	cat <<EOL >"$WORDPRESS_TRAEFIK_CONFIG_YML_FILE"
# traefik.yml
global:
  checkNewVersion: false
  sendAnonymousUsage: false

# Logging configuration
log:
  level: DEBUG

# Entry points
entryPoints:
  web:
    address: ":80"
    # Redirect all HTTP to HTTPS
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"

http:
  routers:
    ${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}-wordpress:
      entryPoints:
        - websecure
      rule: "Host(\`${WORDPRESS_SUBDOMAIN_NAME}.${LEMP_SERVER_DOMAIN}\`)"
      service: ${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}-wordpress
      tls: {}

  services:
    ${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}-wordpress:
      loadBalancer:
        servers:
          - url: "http://${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}-wordpress:80"


  # doc.traefik.io/traefik/middlewares/http/redirectscheme/
  middlewares:
    #------> Middleware for redirecting HTTP to HTTPS
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true

# doc.traefik.io/traefik/https/tls/
tls:
  certificates:
    - certFile: "/etc/traefik/certs/${LEMP_SERVER_DOMAIN}.crt"
      keyFile: "/etc/traefik/certs/${LEMP_SERVER_DOMAIN}.key"
    # ADD CERTS START
    # ADD CERTS END
  stores:
    default:
      defaultCertificate:
        certFile: "/etc/traefik/certs/${LEMP_SERVER_DOMAIN}.crt"
        keyFile: "/etc/traefik/certs/${LEMP_SERVER_DOMAIN}.key"

providers:
  docker:
    watch: true
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: "/etc/traefik"
    watch: true
EOL

	# Output generated NGINX configuration for verification
	cat_msg "$WORDPRESS_TRAEFIK_CONFIG_YML_FILE"
	line_break

	if [ -f "$WORDPRESS_TRAEFIK_CONFIG_YML_FILE" ]; then
		success_msg "'traefik/dynamic/lemp-${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}.yml' created successfully"
	else
		error_msg "Failed to create 'traefik/dynamic/lemp-${LEMP_SERVER_DOMAIN_NAME}-${WORDPRESS_SUBDOMAIN_NAME}.yml', check permissions or create manually."
	fi
fi

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-14-db-verify.sh"
