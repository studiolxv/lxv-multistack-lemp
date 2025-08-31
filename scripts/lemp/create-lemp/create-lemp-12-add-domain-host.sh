#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# MODIFY HOSTS FILE
line_break
section_title "MODIFY HOSTS FILE"
if [ -z "$LEMP_SERVER_DOMAIN" ]; then
    line_break
    error_msg "${C_Red}\$LEMP_SERVER_DOMAIN is not set!"
fi

if [ -z "$LEMP_SERVER_DOMAIN_TLD" ]; then
    line_break
    error_msg "${C_Red}\$LEMP_SERVER_DOMAIN_TLD is not set!"
fi

append_to_hosts_file "$LEMP_SERVER_DOMAIN"
wait
append_to_hosts_file "phpmyadmin.$LEMP_SERVER_DOMAIN"
wait
append_to_hosts_file "mailpit.$LEMP_SERVER_DOMAIN"
wait

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-13-traefik-config.sh"
