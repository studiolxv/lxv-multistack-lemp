#!/bin/sh
STACK_NAME="$1"
WORDPRESS_NAME="$2"

if [ -z "$STACK_NAME" ] || [ -z "$WORDPRESS_NAME" ]; then
    echo "Usage: $0 <stack-name> <wordpress-name>"
    exit 1
fi

. "$PROJECT_PATH/_env-setup.sh"
source_wordpress_stack_env "$STACK_NAME" "$WORDPRESS_NAME"

heading "MANAGE WORDPRESS CONTAINER: $WORDPRESS_NAME"
wordpress_info
line_break

# Options for WordPress container
wp_manage_options="Start ${WORDPRESS_NAME}|Restart ${WORDPRESS_NAME}|Stop ${WORDPRESS_NAME}|Search & Replace in Database: ${WORDPRESS_DB_NAME}|Open https://${WORDPRESS_SUBDOMAIN} in Browser|Open https://${WORDPRESS_SUBDOMAIN}/wp-admin in Browser|Remove ${WORDPRESS_NAME}|Back to WordPress Menu"

section_title "WORDPRESS MANAGEMENT OPTIONS" ${C_Magenta}
i=1
OLD_IFS=$IFS; IFS='|'
for option in $wp_manage_options; do
    option_msg "$i. $option" ${C_Magenta}
    i=$((i + 1))
done
IFS=$OLD_IFS
line_break

option_question "What would you like to do?"

while true; do
    printf "%s " "$(input_cursor)"
    read wp_manage_choice
    total_wp_manage_options=$(echo "$wp_manage_options" | tr '|' '\n' | wc -l)
    if printf "%s" "$wp_manage_choice" | grep -qE '^[0-9]+$' && [ "$wp_manage_choice" -ge 1 ] && [ "$wp_manage_choice" -le "$total_wp_manage_options" ]; then
        selected_wp_manage_option=$(echo "$wp_manage_options" | tr '|' '\n' | sed -n "${wp_manage_choice}p")
        input_cursor "Selected: ${C_Magenta}'$selected_wp_manage_option'${C_Reset}"
        break
    else
        log_error "Invalid choice, please try again."
    fi
done

case "$selected_wp_manage_option" in
    "Start ${WORDPRESS_NAME}")   start_wordpress "$STACK_NAME" "$WORDPRESS_NAME" ;;
    "Restart ${WORDPRESS_NAME}") restart_wordpress "$STACK_NAME" "$WORDPRESS_NAME" ;;
    "Stop ${WORDPRESS_NAME}")    stop_wordpress "$STACK_NAME" "$WORDPRESS_NAME" ;;
    "Search & Replace in Database: ${WORDPRESS_DB_NAME}") replace_wp_url "$STACK_NAME" "$WORDPRESS_NAME" ;;
    "Open https://${WORDPRESS_SUBDOMAIN} in Browser")
        open_link "https://${WORDPRESS_SUBDOMAIN}"
        show_popup "WordPress: ${WORDPRESS_TITLE}" "
        /wp-admin credentials:\n\n
        ${WORDPRESS_URL}\n\n
        Admin:\n ${WORDPRESS_ADMIN_USER}\n\n
        Password:\n ${WORDPRESS_ADMIN_USER_PASSWORD}
        "
		sh "${SCRIPTS_PATH}/lemp/wordpress/manage-wordpress.sh" "$STACK_NAME" "$WORDPRESS_NAME"
    ;;
    "Open https://${WORDPRESS_SUBDOMAIN}/wp-admin in Browser")
        open_link "https://${WORDPRESS_SUBDOMAIN}/wp-admin"
        show_popup "WordPress: ${WORDPRESS_TITLE}" "
        /wp-admin credentials:\n\n
        ${WORDPRESS_URL}/wp-admin\n\n
        Admin:\n ${WORDPRESS_ADMIN_USER}\n
        Password:\n ${WORDPRESS_ADMIN_USER_PASSWORD}
        "
		sh "${SCRIPTS_PATH}/lemp/wordpress/manage-wordpress.sh" "$STACK_NAME" "$WORDPRESS_NAME"
    ;;
    "Remove ${WORDPRESS_NAME}") sh "${SCRIPTS_PATH}/lemp/wordpress/remove-wordpress.sh" "$STACK_NAME" "$WORDPRESS_NAME" ;;
    "Back to WordPress Menu") sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh" ;;
esac