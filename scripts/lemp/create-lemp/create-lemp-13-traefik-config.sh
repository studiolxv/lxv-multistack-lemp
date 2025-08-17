#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# TRAEFIK YML

# Check if the traefik/traefik.yaml file already exists
if [ -f "$LEMP_TRAEFIK_CONFIG_YML_FILE" ]; then
	success_msg "'${TRAEFIK_DYNAMIC_PATH}/${LEMP_SERVER_DOMAIN}.yaml' file already exists:"
else
	warning_msg "'${TRAEFIK_DYNAMIC_PATH}/${LEMP_SERVER_DOMAIN}.yaml' file not found"
	line_break
	generating_msg "Generating 'traefik.yaml' file..."
	line_break
	cat <<EOL >"$LEMP_TRAEFIK_CONFIG_YML_FILE"
# traefik.yaml
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
    ${LEMP_SERVER_DOMAIN_NAME}-nginx:
      entryPoints:
        - websecure
      rule: "Host(\`${LEMP_SERVER_DOMAIN}\`)"
      service: ${LEMP_SERVER_DOMAIN_NAME}-nginx
      tls: {}

    ${LEMP_SERVER_DOMAIN_NAME}-phpmyadmin:
      entryPoints:
        - websecure
      rule: "Host(\`phpmyadmin.${LEMP_SERVER_DOMAIN}\`)"
      service: ${LEMP_SERVER_DOMAIN_NAME}-phpmyadmin
      tls: {}

  services:
    ${LEMP_SERVER_DOMAIN_NAME}-nginx:
      loadBalancer:
        servers:
          - url: "http://${LEMP_SERVER_DOMAIN_NAME}-nginx:80"

    ${LEMP_SERVER_DOMAIN_NAME}-phpmyadmin:
      loadBalancer:
        servers:
          - url: "http://${LEMP_SERVER_DOMAIN_NAME}-phpmyadmin:80"

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
	cat_msg "$LEMP_TRAEFIK_CONFIG_YML_FILE"
	line_break

	if [ -f "$LEMP_TRAEFIK_CONFIG_YML_FILE" ]; then
		success_msg "'${TRAEFIK_DYNAMIC_PATH}/${LEMP_SERVER_DOMAIN}.yaml' created successfully"
	else
		error_msg "Failed to create '${TRAEFIK_DYNAMIC_PATH}/${LEMP_SERVER_DOMAIN}.yaml', check permissions or create manually."
	fi
fi

#####################################################
# Reload Traefik to pick up new routes (if helper is available)
if command -v traefik_reload >/dev/null 2>&1; then
  running_msg "% traefik_reload" ${C_BrightBlue}
  traefik_reload
fi

# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-14-ssl-certificates.sh"
