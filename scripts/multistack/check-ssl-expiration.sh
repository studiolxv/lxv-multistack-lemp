#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

SSL_LOG_FILE="../logs/multistack-ssl-expiration.log"
ALERT_THRESHOLD_DAYS=10 # Days before expiration to trigger alert

line_break
section_title "Checking SSL Certificate Expiration"
line_break

echo "$(date) - Checking SSL expiration." >>"$SSL_LOG_FILE"

for cert in ../traefik/certs/*.crt; do
	[[ -f "$cert" ]] || continue
	CERT_NAME=$(basename "$cert")

	EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
	EXPIRY_TIMESTAMP=$(date -d "$EXPIRY_DATE" +%s)
	CURRENT_TIMESTAMP=$(date +%s)
	DAYS_LEFT=$(((EXPIRY_TIMESTAMP - CURRENT_TIMESTAMP) / 86400))

	if [[ $DAYS_LEFT -le 0 ]]; then
		log_action "❌ SSL Certificate for ${CERT_NAME} has expired!"
		send_alert "SSL Certificate Expired" "The SSL certificate for ${CERT_NAME} has expired."
	elif [[ $DAYS_LEFT -le $ALERT_THRESHOLD_DAYS ]]; then
		log_action "⚠️ SSL Certificate for ${CERT_NAME} expires in ${DAYS_LEFT} days."
		send_alert "SSL Expiring Soon" "The SSL certificate for ${CERT_NAME} will expire in ${DAYS_LEFT} days."
	else
		log_action "✅ SSL Certificate for ${CERT_NAME} is valid for ${DAYS_LEFT} more days."
	fi
done
