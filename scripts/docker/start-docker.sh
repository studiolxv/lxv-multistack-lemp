#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

if ! is_docker_desktop_app_open; then
	heading "DOCKER DESKTOP"
	start_docker_desktop
fi
line_break
