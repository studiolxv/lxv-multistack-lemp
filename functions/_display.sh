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
export -f project_info

lemp_info() {
    line_break
    section_title "LEMP DOCKER" ${C_Green}
    example_msg "${C_Green}LEMP_DIR = ${C_Reset}$LEMP_DIR"
    example_msg "${C_Green}LEMP_PATH = ${C_Reset}$LEMP_PATH"
    example_msg "${C_Green}LEMP_CONTAINER_NAME = ${C_Reset}$LEMP_CONTAINER_NAME"
    example_msg "${C_Green}LEMP_NETWORK_NAME = ${C_Reset}$LEMP_NETWORK_NAME"
    line_break
    section_title "LEMP DOCKER SERVICES" ${C_Green}
    example_msg "${C_Green}DB_IMAGE = ${C_Reset}${DB_IMAGE}"
    example_msg "${C_Green}PHP_IMAGE = ${C_Reset}${PHP_IMAGE}"
    example_msg "${C_Green}PHPMYADMIN_IMAGE = ${C_Reset}${PHPMYADMIN_IMAGE}"
    line_break
    section_title "LEMP DOMAIN" ${C_Green}
    example_msg "${C_Green}LEMP_DOMAIN_NAME = ${C_Reset}${LEMP_DOMAIN_NAME}"
    example_msg "${C_Green}LEMP_DOMAIN_NAME_TLD = ${C_Reset}${LEMP_DOMAIN_NAME_TLD}"
    example_msg "${C_Green}LEMP_DOMAIN = ${C_Underline}https://${LEMP_DOMAIN}"
    example_msg "${C_Green}PHPMYADMIN = ${C_Underline}https://phpmyadmin.${LEMP_DOMAIN}"
}
export -f lemp_info

wordpress_info() {
    
    section_title "WORDPRESS DATABASE" ${C_Green}
    example_msg "${C_Green}PHPMYADMIN_URL  ${C_Underline}https://phpmyadmin.${LEMP_DOMAIN}"
    example_msg "${C_Green}WORDPRESS_DB_USER  ${C_Reset}${WORDPRESS_DB_USER}"
    example_msg "${C_Green}WORDPRESS_DB_USER_PASSWORD  ${C_Reset}${WORDPRESS_DB_USER_PASSWORD}"
    line_break
    section_title "WORDPRESS WP-ADMIN" ${C_Green}
    example_msg "${C_Green}WORDPRESS SITE URL  ${C_Underline}https://${WORDPRESS_SUBDOMAIN}"
    example_msg "${C_Green}WORDPRESS ADMIN URL  ${C_Underline}https://${WORDPRESS_SUBDOMAIN}/wp-admin"
    example_msg "${C_Green}WORDPRESS_ADMIN_USER  ${C_Reset}${WORDPRESS_ADMIN_USER}"
    example_msg "${C_Green}WORDPRESS_ADMIN_USER_PASSWORD  ${C_Reset}${WORDPRESS_ADMIN_USER_PASSWORD}"
    
}
export -f wordpress_info

multistack_help() {
    heading "MULTISTACK HELP"
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
export -f multistack_help

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
export -f lemp_help