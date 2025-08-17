#!/bin/sh
#####################################################
# Alerts

send_alert() {
	local SUBJECT="$1"
	local MESSAGE="$2"
	log_action "ALERT: ${SUBJECT} - ${MESSAGE}"

	# Send Email (Requires `mailutils` package)
	echo "$MESSAGE" | mail -s "$SUBJECT" ${ADMIN_EMAIL}

	# Send Discord/Webhook Notification (Optional)
	# curl -X POST -H "Content-Type: application/json" -d '{"content": "'"${MESSAGE}"'"}' "YOUR_DISCORD_WEBHOOK_URL"
}
export -f send_alert
