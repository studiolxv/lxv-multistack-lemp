#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

heading "Creating New LEMP Stack"
body_msg "Initializing LEMP Stack Creation..."
line_break
#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-2-stack-name-and-domain.sh"
