#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

section_title "Running LEMP & WordPress Containers"
line_break

docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}"

line_break
status_msg "End of list."
