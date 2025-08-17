#!/bin/sh
if [ -d "$PROJECT_PATH" ] || [ -f "./.env" ]; then
. "${PROJECT_PATH}/_environment.sh"
else
echo "Environment variables not loaded ($(basename "$0"))"
kill -TERM $$
fi
file_msg "$(basename "$0")"
heading "DOCKER DESKTOP"
start_docker_desktop
line_break
