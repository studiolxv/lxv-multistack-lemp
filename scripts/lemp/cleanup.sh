#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

section_title "Cleaning Up Old LEMP Stacks"
line_break

# Function to cleanup old LEMP stacks
cleanup_old_stacks() {
	line_break
	status_msg "Removing unused LEMP stacks..."

	find "$STACKS_PATH" -mindepth 1 -maxdepth 1 -type d | while read -r stack; do
		printf "Do you want to remove %s? (y/N): " "$stack"
		read confirm
		case "$confirm" in
		[Yy])
			line_break
			status_msg "Removing $stack..."
			rm -rf "$stack"
			;;
		esac
	done

	line_break
	status_msg "Cleanup complete."
}

status_msg "Cleanup completed!"
