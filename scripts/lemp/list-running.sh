#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

section_title "Running LEMP & WordPress Containers"
line_break

docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

line_break
status_msg "End of list."
