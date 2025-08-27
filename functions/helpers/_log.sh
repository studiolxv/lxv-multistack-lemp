#!/bin/sh
#####################################################
# LOG FILE

check_log_file_exists_or_create() {
	# Check if the log file exists
	if [ -f "$LOG_FILE" ]; then
		return
	else
		cat <<EOL >"$LOG_FILE"
# ${LOG_FILE}
EOL
		if [ -f "$LOG_FILE" ]; then
			# Log Init to file
			echo "[$timestamp] '${LOG_FILE}' file created successfully [${file_name}:${line_number}]" | tee -a "$LOG_FILE"
		else
			echo "Failed to create '$LOG_FILE', check permissions or create manually."
		fi
	fi
}


# EXAMPLE: log_action "Example Log Message" $(basename "$0") $(caller | cut -d' ' -f1)
log_action() {
	message="$1"
	file_name="${2:-$(basename "$0")}"            # Get script name
	line_number="${3:-$(caller | cut -d' ' -f1)}" # Extract line number if `caller` is available
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	check_log_file_exists_or_create

	body_msg "$message"

	# Log message
	cat <<EOL >"$LOG_FILE"
	[$timestamp] $message [${file_name}:${line_number}]

EOL
}


# EXAMPLE: log_error "Example Error Message" $(basename "$0") $(caller | cut -d' ' -f1)
log_error() {
	message="$1"
	file_name="${2:-$(basename "$0")}"            # Get script name
	line_number="${3:-$(caller | cut -d' ' -f1)}" # Extract line number if `caller` is available
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	check_log_file_exists_or_create

	# Echo to terminal
	error_msg "$message"

	# Log message
	cat <<EOL >"$LOG_FILE"
	[$timestamp] $message [${file_name}:${line_number}]

EOL
}


# EXAMPLE: log_success "Example Success Message" $(basename "$0") $(caller | cut -d' ' -f1)
log_success() {
	message="$1"
	file_name="${2:-$(basename "$0")}"            # Get script name
	line_number="${3:-$(caller | cut -d' ' -f1)}" # Extract line number if `caller` is available
	timestamp=$(date +"%Y-%m-%d %H:%M:%S")

	check_log_file_exists_or_create

	# Echo to terminal
	if [ -n "$opt_debug" ] && [ "$opt_debug" = "true" ]; then
		success_msg "$message"
	fi

	# Log message
	cat <<EOL >"$LOG_FILE"
	[$timestamp] $message [${file_name}:${line_number}]

EOL
}

