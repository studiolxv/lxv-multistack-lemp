#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# SSL CERTIFICATES: CREATE & TRUST WITH MKCERT
line_break
section_title "CREATING SSL CERTIFICATES: https://${LEMP_SERVER_DOMAIN}"
line_break

#####################################################
# GENERATE CERTIFICATES
if [[ -f "${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}" && -f "${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}" ]]; then
	success_msg "Wildcard SSL certificate already exists for ${LEMP_SERVER_DOMAIN}."
else
	status_msg "Generating wildcard SSL certificate for ${LEMP_SERVER_DOMAIN} and all subdomains..."

	mkcert -cert-file "${LEMP_TRAEFIK_DOMAIN_SSL_CRT_FILE}" \
		-key-file "${LEMP_TRAEFIK_DOMAIN_SSL_KEY_FILE}" \
		"${LEMP_SERVER_DOMAIN}" \
		"*.${LEMP_SERVER_DOMAIN}"

	success_msg "Wildcard SSL certificate created successfully."
fi
line_break
#####################################################
# MACOS: ADD CERTIFICATE TO TRUSTED KEYCHAIN

section_title "TRUST CERTIFICATE"
body_msg "Attempting to trust the SSL certificate on your host machine..."

add_ssl_certificate_to_trust

#####################################################
# UPDATE TRAEFIK CERTIFICATES CONFIG
update_lemp_ssl "${LEMP_SERVER_DOMAIN}"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-15-backup.sh"
