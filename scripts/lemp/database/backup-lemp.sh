#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

section_title "DATABASE DUMP"

# Get the first argument (stack name)
STACK_NAME="$1"
