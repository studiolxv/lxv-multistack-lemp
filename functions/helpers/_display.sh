#!/bin/sh
#####################################################
# DISPLAY SPECIFIED INFORMATION
project_info() {
    section_title "PROJECT Variables:"
    example_msg "PROJECT_NAME = ${C_Status}$PROJECT_NAME${C_Reset}"
    example_msg "PROJECT_PATH = ${C_Status}$PROJECT_PATH${C_Reset}"
    example_msg "STACKS_PATH = ${C_Status}$STACKS_PATH${C_Reset}"
    example_msg "SCRIPTS_PATH = ${C_Status}$SCRIPTS_PATH${C_Reset}"
    example_msg "FUNCTIONS_PATH = ${C_Status}$FUNCTIONS_PATH${C_Reset}"
}


lemp_info() {
    section_title "LEMP DOCKER"
    example_msg "LEMP_DIR:   ${C_Reset}$LEMP_DIR"
    example_msg "LEMP_PATH:   ${C_Reset}$LEMP_PATH"
    example_msg "LEMP_CONTAINER_NAME:   ${C_Reset}$LEMP_CONTAINER_NAME"
    example_msg "LEMP_NETWORK_NAME:   ${C_Reset}$LEMP_NETWORK_NAME"
    line_break
    section_title "LEMP DOCKER SERVICES"
    example_msg "DB_IMAGE:   ${C_Reset}${DB_IMAGE}"
    example_msg "PHP_IMAGE:   ${C_Reset}${PHP_IMAGE}"
    example_msg "PHPMYADMIN_IMAGE:   ${C_Reset}${PHPMYADMIN_IMAGE}"
    example_msg "BACKUPS_IMAGE:   ${C_Reset}${BACKUPS_IMAGE}"
    line_break
    section_title "LEMP DOMAIN"
    example_msg "LEMP_SERVER_DOMAIN:   ${C_Underline}https://${LEMP_SERVER_DOMAIN}"
    example_msg "PHPMYADMIN_SUBDOMAIN:  ${C_Underline}https://${PHPMYADMIN_SUBDOMAIN}"
	line_break
    section_title "LEMP BACKUPS"
	example_msg "BACKUPS_PATH:   ${BACKUPS_PATH}"
	example_msg "BACKUPS_CRON_SCHEDULE_DESC:   ${BACKUPS_CRON_SCHEDULE_DESC}"
	example_msg "BACKUPS_CLEANUP_ACTION:   ${BACKUPS_CLEANUP_ACTION}"
	example_msg "BACKUPS_CLEANUP_SCRIPT_DESC:   ${BACKUPS_CLEANUP_SCRIPT_DESC}"
}

wordpress_info() {
    section_title "WORDPRESS DATABASE"
    example_msg "phpMyAdmin:   ${C_Underline}https://${PHPMYADMIN_SUBDOMAIN}"
    example_msg "User:   ${C_Reset}${WORDPRESS_DB_USER}"
    example_msg "Password:   ${C_Reset}${WORDPRESS_DB_PASSWORD}"
    line_break
    section_title "WORDPRESS WP-ADMIN"
    example_msg "Site URL:   ${C_Underline}https://${WORDPRESS_SUBDOMAIN}"
    example_msg "Admin URL:   ${C_Underline}https://${WORDPRESS_SUBDOMAIN}/wp-admin"
    example_msg "Admin User:   ${C_Reset}${WORDPRESS_ADMIN_USER}"
    example_msg "Admin Password:   ${C_Reset}${WORDPRESS_ADMIN_USER_PASSWORD}"
}


multistack_help() {
    heading "LEMP MULTISTACK HELP"
    body_msg "Local Development Multi-Stack LEMP Environment" ${C_Status}
    body_msg "[PHP|PhpMyAdmin|Database] Docker Compose service image selection, [Up|Cron|Down|User] Automated .sql dump backups + optional .sql cleanup methods, NGINX, quick and easy SSL Virtual Hosts + Traefik routing" ${C_Status}
    body_msg "LEMP stands for Linux (operating system), Nginx [EngineX] (web server), MySQL (database), and PHP (scripting language)" ${C_Status}
    line_break

    info_msg "How the Multistack Setup Actually Works"
    line_break

    section_title "Traefik Container"
    example_msg "Runs traefik to route browsers to each LEMP Stack virtual host domain and subdomains in traefik/dynamic."
    example_msg "Building LEMP Stacks creates a new virtual host config file in traefik/dynamic. (ie https://<LEMP_DOMAIN>, https://phpmyadmin.<LEMP_DOMAIN>)"
    example_msg "Building Wordpress Containers creates a new virtual host subdomain for parent LEMP's domain config file in traefik/dynamic. (ie https://<WORDPRESS_SUBDOMAIN>.<LEMP_DOMAIN>)"
    line_break

    section_title "LEMP STACK(S)"
    example_msg "Creates new virutal host domains, Nginx, MySQL, PHP, and phpMyAdmin"
    example_msg "Unique PHP root directory and independant PHP version for files hosted from the \$STACK_NAME/${PHP_PUBLIC_PATH} directory."
    example_msg "LEMP's MySQL container contains all databases unique to the LEMP stack and databases created for Wordpress containers under this LEMP STACK."
    example_msg "LEMP's PHP container version ${C_Underline}DOES NOT${C_Reset} affect LEMP STACK phpMyAdmin ${C_Underline}NOR${C_Reset} WordPress container's PHP version."
    example_msg "LEMP STACK phpMyAdmin routed under LEMP STACK's main domain, (ie https://phpmyadmin.<LEMP_DOMAIN>)"
    example_msg "LEMP STACK phpMyAdmin container runs its on PHP version inside its own container."
    example_msg "LEMP STACK phpMyAdmin container connects to the LEMP's MYSQL container hosting databases unique to the LEMP stack."
    line_break

    section_title "LEMP STACK(S) > WordPress Container(s)"
    example_msg "Creates a new subdomain under LEMP STACK's main domain, and unique traefik config file for this subdomain"
    example_msg "Connects to the LEMP Stack docker network LEMP STACK MYSQL container to create database during set up of this WordPress container."
    example_msg "Wordpress images contain its own PHP version. (ie wordpress:latest = PHP likely > 8.x.x)"
    example_msg "${C_Underline}DOES NOT${C_Reset} use the LEMP STACK PHP container."
    example_msg "Runs independently."

}


lemp_help() {
    heading "LEMP HELP"
    info_msg "How the LEMP Setup Actually Works"
    line_break

    section_title "LEMP STACK(S)"
    example_msg "Creates new virutal host domains, Nginx, MySQL, PHP, and phpMyAdmin"
    example_msg "Unique PHP root directory and independant PHP version for files hosted from the \$STACK_NAME/${PHP_PUBLIC_PATH} directory."
    example_msg "LEMP's PHP container version ${C_Underline}DOES NOT${C_Reset} affect LEMP STACK phpMyAdmin ${C_Underline}NOR${C_Reset} WordPress container's PHP version."
    section_title "LEMP STACK phpMyAdmin routed under LEMP STACK's main domain, (ie https://phpmyadmin.<LEMP_DOMAIN>)"
    section_title "LEMP STACK phpMyAdmin container runs its on PHP version inside its own container."
    example_msg "LEMP STACK phpMyAdmin container connects to the LEMP's MYSQL container hosting databases unique to the LEMP stack."
    line_break

    section_title "LEMP STACK(S) > WordPress Container(s)"
    example_msg "Creates a new subdomain under LEMP STACK's main domain, and unique traefik config file for this subdomain"
    example_msg "Connects to the LEMP Stack docker network LEMP STACK MYSQL container to create database during set up of this WordPress container."
    example_msg "Wordpress images contain its own PHP version. (ie wordpress:latest = PHP likely > 8.x.x)"
    example_msg "${C_Underline}DOES NOT${C_Reset} use the LEMP STACK PHP container."
    example_msg "Runs independently."

}


show_popup() {
    title="$1"
    message="$2"
    case "$(uname -s)" in
        Darwin)
            # macOS

ICNSPATH="${PROJECT_PATH}/assets/icons/folder.icns"
            osascript -e "display dialog \"$message\" with title \"$title\" with icon POSIX file \"$ICNSPATH\" buttons {\"OK\"}" >/dev/null
            ;;
        Linux)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "$title" "$message"
            elif command -v zenity >/dev/null 2>&1; then
                zenity --info --title="$title" --text="$message"
            else
                printf '%s: %s\n' "$title" "$message"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if command -v powershell.exe >/dev/null 2>&1; then
                powershell.exe -Command "[System.Windows.Forms.MessageBox]::Show('$message','$title')" >/dev/null
            else
                printf '%s: %s\n' "$title" "$message"
            fi
            ;;
        *)
            printf '%s: %s\n' "$title" "$message"
            ;;
    esac
}

