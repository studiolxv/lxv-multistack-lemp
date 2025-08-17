#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

section_title "DATABASE DUMP"

# Get the first argument (stack name)
STACK_NAME="$1"
