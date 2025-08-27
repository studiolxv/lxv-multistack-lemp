#!/bin/sh
STACK_NAME="$1"

if [ -z "$STACK_NAME" ]; then
    echo "Usage: $0 <stack-name>"
    exit 1
fi

. "$PROJECT_PATH/_env-setup.sh"


heading "MANAGE LEMP STACK: \"$STACK_NAME\""

source_lemp_stack_env "$STACK_NAME"

containers="$(list_dirs containers $opt_sort "$STACK_NAME")"

# Generate WordPress container options
wp_options="Create New WordPress Container"

# Add additional options (non-container items)
wp_options="$wp_options|Start ${STACK_NAME}|Restart ${STACK_NAME}|Stop ${STACK_NAME}|Open https://${LEMP_SERVER_DOMAIN} in Browser|Open https://phpmyadmin.${LEMP_SERVER_DOMAIN} in Browser|Database: Backup Dump|Database: Recover Tables|Remove ${STACK_NAME}|${STACK_NAME} Info|Help|Back to Main Menu"

# Record how many non-container options exist to know where the container section begins
non_container_count=$(printf '%s' "$wp_options" | awk -F'|' '{print NF}')

# Append container management options
if [ -n "$containers" ]; then
    for container in $containers; do
        wp_options="$wp_options|Manage $container"
    done
    container_start_index=$((non_container_count + 1))
else
    container_start_index=0
fi

# Final option
wp_options="$wp_options"

# Display WordPress Options
STACK_NAME_UC=$(uc_word "$STACK_NAME")
section_title "\"$STACK_NAME_UC\" STACK OPTIONS" ${C_Magenta}
i=1
OLD_IFS=$IFS; IFS='|' # Set delimiter for correct iteration
for option in $wp_options; do
    # When we reach the first container option, insert a visual separator and section title
    if [ -n "$containers" ] && [ "$container_start_index" -gt 0 ] && [ "$i" -eq "$container_start_index" ]; then
	line_break
	body_msg "MANAGE \"${STACK_NAME_UC}\" CONTAINERS" ${C_Magenta}
    fi
    option_msg "$i. $option" ${C_Magenta}
    i=$((i + 1))
done
IFS=$OLD_IFS
line_break
option_question "What would you like to do?"

# Read WordPress Selection
while true; do
    printf "%s " "$(input_cursor)"
    read wp_choice

    total_wp_options=$(echo "$wp_options" | tr '|' '\n' | wc -l)

    if printf "%s" "$wp_choice" | grep -qE '^[0-9]+$' && [ "$wp_choice" -ge 1 ] && [ "$wp_choice" -le "$total_wp_options" ]; then
        selected_wp_option=$(echo "$wp_options" | tr '|' '\n' | sed -n "${wp_choice}p")
        input_cursor "Selected: ${C_Magenta}'$selected_wp_option'${C_Reset}"
		line_break
        break
    else
        log_error "Invalid choice, please try again."
    fi
done
case "$selected_wp_option" in
    "Create New WordPress Container")
        sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-1-init.sh" "$STACK_NAME"
    ;;
    "Start ${STACK_NAME}")
        start_lemp "${STACK_NAME}"
		wait
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Restart ${STACK_NAME}")
        restart_lemp "${STACK_NAME}"
		wait
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Stop ${STACK_NAME}")
        stop_lemp "${STACK_NAME}"
		wait
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Open https://${LEMP_SERVER_DOMAIN} in Browser")
        open_link "https://${LEMP_SERVER_DOMAIN}"
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Open https://phpmyadmin.${LEMP_SERVER_DOMAIN} in Browser")
        open_link "https://phpmyadmin.${LEMP_SERVER_DOMAIN}"

		# Show DB credentials popup for user convenience
		if [ -f "${LEMP_PATH}/secrets/db_root_user.txt" ] && [ -f "${LEMP_PATH}/secrets/db_root_user_password.txt" ]; then
		    DB_USER=$(cat "${LEMP_PATH}/secrets/db_root_user.txt")
		    DB_PASS=$(cat "${LEMP_PATH}/secrets/db_root_user_password.txt")
		    show_popup "LXV MULTISTACK LEMP: ${STACK_NAME}" "Copy and paste the user and password to log into phpMyAdmin with the following credentials\n\nUser: $DB_USER\nPassword: $DB_PASS"
		fi
		wait
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Database: Backup Dump")
        # Run the backup INSIDE the backups container
        # Requires: BACKUPS_CONTAINER_NAME already set in env by source_lemp_stack_env "$STACK_NAME"
		line_break
		section_title "ENTER DUMP LABEL" ${C_Magenta}
		example_msg "This label will be used to identify the backup dump file. Leave empty to use 'user_initiated'."
		line_break
		option_question "File name appendix to the .sql file:"
		printf "%s" "$(input_cursor)"
		read USER_INPUT_DUMP_LABEL

		if [ -z "$USER_INPUT_DUMP_LABEL" ]; then
		    input_cursor "🚨 No label provided. Using \"${C_Magenta}${C_Underline}user_initiated${C_Reset}\""
		    DUMP_LABEL="user_initiated"
		else
		    input_cursor "Entered label: \"${C_Magenta}${C_Underline}${USER_INPUT_DUMP_LABEL}${C_Reset}\""
		    DUMP_LABEL="$(sanitize_string "$USER_INPUT_DUMP_LABEL" "_")"
		fi

		line_break

        # 1) Ensure the container exists
        if docker ps -a --format '{{.Names}}' | grep -Fxq "$BACKUPS_CONTAINER_NAME"; then
            # 2) Ensure it is running (start if needed)
            if ! docker ps --format '{{.Names}}' | grep -Fxq "$BACKUPS_CONTAINER_NAME"; then
                body_msg "🐳 Starting $BACKUPS_CONTAINER_NAME …"
                docker start "$BACKUPS_CONTAINER_NAME" >/dev/null 2>&1 || {
                    log_error "Could not start container: $BACKUPS_CONTAINER_NAME"
                    break
                }
            fi

            # 3) Build optional env passthroughs (only if set on host)
            _BACKUP_ENV_ARGS=""
            [ -n "${MYSQL_ROOT_PASSWORD:-}" ] && _BACKUP_ENV_ARGS="$_BACKUP_ENV_ARGS -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD"

            # 4) Exec the in-container backup script
            body_msg "➡️  Running backup inside $BACKUPS_CONTAINER_NAME for stack '$STACK_NAME' …"
            docker exec $_BACKUP_ENV_ARGS \
              -e BACKUPS_CONTAINER_NAME="$BACKUPS_CONTAINER_NAME" \
              -e STACK_NAME="$STACK_NAME" \
              "$BACKUPS_CONTAINER_NAME" \
              sh "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh" "$DUMP_LABEL" "$STACK_NAME"
        else
            log_error "Backups container not found: $BACKUPS_CONTAINER_NAME"
            body_msg "Tip: ensure your stack env sets BACKUPS_CONTAINER_NAME and the container exists."
        fi
		wait
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Database: Recover Tables")
        sh "${SCRIPTS_PATH}/lemp/database/recover-tables.sh" "$STACK_NAME"
		wait
		sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
    ;;
    "Remove ${STACK_NAME}")
        sh "${SCRIPTS_PATH}/multistack/remove-lemp.sh" "$STACK_NAME"
		wait
		sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
    ;;
    "${STACK_NAME} Info")
        lemp_info
		line_break
        printf "%s " "$(input_cursor)Press 'e' to exit back to main menu: "
        read ans
        if [ "$ans" = "e" ]; then
            line_break
            sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
        fi
    ;;
    "Help")
        lemp_help
		line_break
        printf "%s " "$(input_cursor)Press 'e' to exit back to main menu: "
        read ans
        if [ "$ans" = "e" ]; then
            line_break
            sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
        fi
    ;;
    "Back to Main Menu")
        sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
    ;;
    *)
		# If the option starts with "Manage ", extract the container name and call manage script
		if printf "%s" "$selected_wp_option" | grep -q "^Manage "; then
			WORDPRESS_NAME=$(printf "%s" "$selected_wp_option" | cut -d' ' -f2-)
			. "$PROJECT_PATH/_env-setup.sh"
			source_wordpress_stack_env "$STACK_NAME" "$WORDPRESS_NAME"
	        sh "${SCRIPTS_PATH}/lemp/wordpress/manage-wordpress.sh" "$STACK_NAME" "$WORDPRESS_NAME"
		else
			log_error "Unexpected option format: $selected_wp_option"
			sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "${STACK_NAME}"
		fi

    ;;
esac