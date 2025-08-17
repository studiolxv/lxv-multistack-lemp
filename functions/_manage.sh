#!/bin/sh
#####################################################
# CREATE & MANAGE FUNCTIONS

# Function to list all available LEMP stacks
list_stacks() {
	find "$STACKS_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}
export -f list_stacks

# Function to list WordPress containers inside a LEMP stack
list_containers() {
	stack_name="$1"
	find "$STACKS_PATH/$stack_name/containers" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
}
export -f list_containers

# Function to list and select a LEMP stack
# Ensure function is not redefined
select_lemp_stack() {
	section_title "Select a LEMP Stack"

	# Get available stacks using list_stacks and store in a string
	stacks=""
	while IFS= read -r stack; do
		stacks="${stack}"
		# stacks="${stacks}\n${stack}"
	done <<EOF
$(list_stacks)
EOF

	# Check if any stacks exist
	if [ -z "$(echo "$stacks" | tr -d '\n')" ]; then
		log_error "No LEMP stacks found!"
		printf "Would you like to create one now? (y/N): "
		read -r create_stack
		case "$create_stack" in
		[Yy])
			sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-1-init.sh"
			select_lemp_stack # Re-run after creating a stack
			return
			;;
		*)
			exit 1
			;;
		esac
	fi

	# Display stacks for selection
	i=1
	echo "$stacks" | while IFS= read -r stack; do
		body_msg "$i. $stack"
		i=$((i + 1))
	done

	# Read user selection
	while true; do
		printf "\033[1;33m>>> \033[0m"
		read -r choice

		# Check if input is a valid number
		case "$choice" in
		*[!0-9]* | "") log_error "Invalid choice, please try again." ;;
		*)
			num_stacks=$(echo "$stacks" | wc -l)
			if [ "$choice" -ge 1 ] && [ "$choice" -le "$num_stacks" ]; then
				STACK_NAME=$(echo "$stacks" | sed -n "${choice}p")
				break
			else
				log_error "Invalid choice, please try again."
			fi
			;;
		esac
	done
}
export -f select_lemp_stack

# Function to list and select a WordPress container within a LEMP stack
# Ensure function is not redefined
select_wordpress_container() {
	stack_name="$1"
	line_break
	section_title "Select a WordPress Container in ${stack_name}"

	# Get list of WordPress containers
	containers=""
	while IFS= read -r container; do
		containers="${containers}\n${container}"
	done <<EOF
$(list_containers "$stack_name")
EOF

	# Check if any containers exist
	if [ -z "$(echo "$containers" | tr -d '\n')" ]; then
		log_error "No WordPress containers found in ${stack_name}!"
		printf "Would you like to create one now? (y/N): "
		read -r create_wp
		case "$create_wp" in
		[Yy])
			../scripts/create-wordpress.sh
			select_wordpress_container "$stack_name" # Re-run after creating
			return
			;;
		*)
			exit 1
			;;
		esac
	fi

	# Display WordPress containers for selection
	i=1
	echo "$containers" | while IFS= read -r container; do
		body_msg "$i. $container"
		i=$((i + 1))
	done

	# Read user selection
	while true; do
		printf "\033[1;33m>>> \033[0m"
		read -r choice

		# Check if input is a valid number
		case "$choice" in
		*[!0-9]* | "") log_error "Invalid choice, please try again." ;;
		*)
			num_containers=$(echo "$containers" | wc -l)
			if [ "$choice" -ge 1 ] && [ "$choice" -le "$num_containers" ]; then
				WP_NAME=$(echo "$containers" | sed -n "${choice}p")
				break
			else
				log_error "Invalid choice, please try again."
			fi
			;;
		esac
	done
}
export -f select_wordpress_container

# Function to open URLs based on the operating system
open_link() {
	local LINK=$1

	if command -v xdg-open >/dev/null; then
		# Linux
		xdg-open "${LINK}"
	elif command -v open >/dev/null; then
		# macOS
		open "${LINK}"
	elif command -v start >/dev/null; then
		# Windows (Git Bash or similar)
		start "${LINK}"
	else
		# Fallback if no known command exists
		echo "Opening Link: Could not detect the operating system, please open the link manually"
	fi
}
export -f open_link
