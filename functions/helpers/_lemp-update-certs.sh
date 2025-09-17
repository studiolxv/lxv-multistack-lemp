#!/bin/sh
check_cert_in_keychain() {
	cert_name="${1:-$LEMP_SERVER_DOMAIN}"
	security find-certificate -c "$cert_name" /Library/Keychains/System.keychain >/dev/null 2>&1
}


update_lemp_ssl() {
    LEMP_SERVER_DOMAIN="${1:-$LEMP_SERVER_DOMAIN}"
    if [ -z "$LEMP_SERVER_DOMAIN" ]; then
        echo "❌ Error: Missing LEMP_SERVER_DOMAIN argument."
        return 1
    fi
    line_break
	section_title "${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}/${TRAEFIK_CERTS_YML_FILE_NAME}"
	generating_msg "Updating ${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}/${TRAEFIK_CERTS_YML_FILE_NAME}"
    body_msg "🔄 Updating certs.yml with LEMP stack: $LEMP_SERVER_DOMAIN"

    # Append LEMP Stack certificate entry
	# https://doc.traefik.io/traefik/reference/routing-configuration/http/tls/tls-certificates/
    echo "    - certFile: \"/etc/traefik/certs/${LEMP_SERVER_DOMAIN}.crt\"" >> "$TRAEFIK_CERTS_YML_FILE"
    echo "      keyFile: \"/etc/traefik/certs/${LEMP_SERVER_DOMAIN}.key\"" >> "$TRAEFIK_CERTS_YML_FILE"

    success_msg "${TRAEFIK_DIR}/${TRAEFIK_DYNAMIC_DIR}/${TRAEFIK_CERTS_YML_FILE_NAME} updated successfully for LEMP stack."
	line_break
}

# Usage Example:
# update_lemp_ssl "lemp1.test"


remove_lemp_certs_yml() {
    LEMP_SERVER_DOMAIN="$1"

    if [ -z "$LEMP_SERVER_DOMAIN" ]; then
        echo "❌ Error: Missing LEMP_SERVER_DOMAIN argument."
        return 1
    fi

    if [ ! -f "$TRAEFIK_CERTS_YML_FILE" ]; then
        echo "⚠️ Warning: certs.yml file not found."
        return 1
    fi

    echo "🔄 Removing SSL entries for ${LEMP_SERVER_DOMAIN} from $TRAEFIK_CERTS_YML_FILE..."

    # Create a temporary file without the matching lines
    grep -v "${LEMP_SERVER_DOMAIN}" "$TRAEFIK_CERTS_YML_FILE" > "${TRAEFIK_CERTS_YML_FILE}.tmp"

    # Replace the original file with the cleaned one
    mv "${TRAEFIK_CERTS_YML_FILE}.tmp" "$TRAEFIK_CERTS_YML_FILE"

    echo "✅ SSL entries for ${LEMP_SERVER_DOMAIN} removed successfully."
}

# Usage Example:
# remove_lemp_certs_yml "lemp1.test"