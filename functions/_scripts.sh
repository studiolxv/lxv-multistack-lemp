#!/bin/sh
#####################################################
# SCRIPT HELPERS
make_scripts_executable() {
	# Ensure SCRIPTS_PATH is set
	if [ -z "$SCRIPTS_PATH" ]; then
		echo "❌ Error: SCRIPTS_PATH is not set."
		return 1
	fi

	# Ensure the directory exists
	if [ ! -d "$SCRIPTS_PATH" ]; then
		echo "❌ Error: Directory '$SCRIPTS_PATH' does not exist."
		return 1
	fi

	# Debugging: Show the directory being checked
	# echo "🔍 Checking scripts in: $SCRIPTS_PATH"

	# Loop through each script file in the directory
	find "$SCRIPTS_PATH" -type f | while IFS= read -r script; do
		# Check if the file is NOT already executable
		if [ ! -x "$script" ]; then
			echo "🔄 Changing permissions for: $script"
			chmod +x "$script" || echo "❌ Failed to modify: $script"
			ls -l "$script" # Verify permissions after change
		fi
	done
}
export -f make_scripts_executable

# Run function
# make_scripts_executable
