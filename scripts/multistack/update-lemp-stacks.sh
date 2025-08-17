#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

LOG_FILE="../logs/update-lemp.log"

line_break
section_title "Updating All LEMP Stacks"
line_break

echo "$(date) - Starting LEMP stack update process." >>"$LOG_FILE"

# Restart each LEMP stack's NGINX & phpMyAdmin containers
for stack in "${STACKS_PATH}}"/*; do
	[[ -d "$stack" ]] || continue
	STACK_NAME=$(basename "$stack")
	status_msg "Updating ${STACK_NAME}..."

	# Restart NGINX and phpMyAdmin for this stack
	docker restart "${STACK_NAME}-nginx" "${STACK_NAME}-phpmyadmin" >>"$LOG_FILE" 2>&1
	echo "$(date) - Restarted ${STACK_NAME}-nginx and ${STACK_NAME}-phpmyadmin." >>"$LOG_FILE"
done

# Restart Traefik to ensure it loads new configs
cd "${TRAEFIK_PATH}" || exit
docker restart traefik >>"$LOG_FILE" 2>&1
log_action "Restarted Traefik."

status_msg "All LEMP stacks updated!"
echo "$(date) - LEMP stack update process completed." >>"$LOG_FILE"
