#!/bin/sh
#####################################################
# CREATE & MANAGE FUNCTIONS

# Unified lister
# Usage:
#   list_dirs stacks <mode>
#   list_dirs containers <mode> <stack_name>
# Modes: time_desc (default), time_asc, alpha_asc, alpha_desc
list_dirs() {
    kind="$1"            # stacks | containers
    mode="${2:-time_desc}"
    stack_name="$3"     # required for containers

    case "$kind" in
        stacks)
            base_dir="$STACKS_PATH"
            ;;
        containers)
            if [ -z "$stack_name" ]; then
                echo "❌ list_dirs: stack_name missing for containers" >&2
                return 1
            fi
            base_dir="$STACKS_PATH/$stack_name/containers"
            ;;
        *)
            echo "❌ list_dirs: unknown kind '$kind' (use 'stacks' or 'containers')" >&2
            return 1
            ;;
    esac

    # Ensure base_dir exists
    [ -d "$base_dir" ] || return 0

    case "$mode" in
        alpha_asc)
            find "$base_dir" -mindepth 1 -maxdepth 1 -type d -print0 \
              | xargs -0 -I{} basename "{}" \
              | sort
            ;;
        alpha_desc)
            find "$base_dir" -mindepth 1 -maxdepth 1 -type d -print0 \
              | xargs -0 -I{} basename "{}" \
              | sort -r
            ;;
        time_desc)
            if [ "$(uname)" = "Darwin" ]; then
                find "$base_dir" -mindepth 1 -maxdepth 1 -type d -print0 \
                  | xargs -0 -I{} stat -f '%m\t%N' "{}" \
                  | sort -nr \
                  | cut -f2- \
                  | sed 's!.*/!!'
            else
                find "$base_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\0' 2>/dev/null \
                  | sort -z -nr \
                  | tr '\0' '\n' \
                  | cut -d' ' -f2- \
                  | sed 's!.*/!!'
            fi
            ;;
        time_asc)
            if [ "$(uname)" = "Darwin" ]; then
                find "$base_dir" -mindepth 1 -maxdepth 1 -type d -print0 \
                  | xargs -0 -I{} stat -f '%m\t%N' "{}" \
                  | sort -n \
                  | cut -f2- \
                  | sed 's!.*/!!'
            else
                find "$base_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\0' 2>/dev/null \
                  | sort -z -n \
                  | tr '\0' '\n' \
                  | cut -d' ' -f2- \
                  | sed 's!.*/!!'
            fi
            ;;
        *)
            echo "❌ Unknown sort mode: $mode (use 'time_desc', 'time_asc', 'alpha_asc', or 'alpha_desc')" >&2
            return 1
            ;;
    esac
}

# Function to list and select a LEMP stack
# Ensure function is not redefined
select_lemp_stack() {
	section_title "Select a LEMP Stack"

	# Get available stacks using list_dirs and store in a string
	stacks=""
	while IFS= read -r stack; do
		stacks="${stack}"
		# stacks="${stacks}\n${stack}"
	done <<EOF
$(list_dirs stacks time_asc)
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
$(list_dirs containers time_asc "$stack_name")
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



