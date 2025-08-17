#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

# Display Menu
heading "DOCKER MULTISTACK LEMP"

# Display Environment Variables
project_info
line_break

# Fetch available LEMP stacks
stacks="$(list_stacks)"

# Generate menu options without extra newlines
options="Create New LEMP Stack"
for stack in $stacks; do
	options="$options|Manage $stack"
done
options="$options|Help|Quit"

# Display Options
section_title "MULTISTACK OPTIONS" ${C_Magenta}
i=1
OLD_IFS=$IFS; IFS='|' # Set delimiter for correct iteration
for option in $options; do
	option_msg "$i. $option" ${C_Magenta}
	i=$((i + 1))
done
IFS=$OLD_IFS
line_break
option_question "What would you like to do?"

# Read User Selection
while true; do
	printf "%s " "$(input_cursor)"
	read choice || { log_error "Input cancelled."; exit 1; }

	total_options=$(printf '%s' "$options" | tr '|' '\n' | wc -l | tr -d '[:space:]')

	if printf "%s" "$choice" | grep -qE '^[0-9]+$' && [ "$choice" -ge 1 ] && [ "$choice" -le "$total_options" ]; then
		selected_option=$(echo "$options" | tr '|' '\n' | sed -n "${choice}p")
		input_cursor "Selected: ${C_Magenta}'$selected_option'${C_Reset}"
		break
	else
		log_error "Invalid choice, please try again."
	fi
done
line_break
# Execute the selected action
case "$selected_option" in
"Create New LEMP Stack")
	sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-1-init.sh"
	;;
"Help")
	multistack_help
	;;
"Quit")
	exit 0
	;;
*)
	# ! SELECTED LEMP STACK  MANAGEMENT OPTIONS
	# If the selection starts with "Manage", extract the stack name and list WordPress containers
	if printf "%s" "$selected_option" | grep -q "^Manage "; then
		STACK_NAME=$(printf "%s" "$selected_option" | cut -d' ' -f2-)

		heading "MANAGE LEMP STACK: $STACK_NAME"

		source_lemp_stack_env "$STACK_NAME"

		containers="$(list_containers "$STACK_NAME")"

		lemp_info
		line_break

		# Generate WordPress container options
		wp_options="Create New WordPress Container"

		# Add additional options
		wp_options="$wp_options|Start ${STACK_NAME}|Restart ${STACK_NAME}|Stop ${STACK_NAME}|Open https://${LEMP_SERVER_DOMAIN} in Browser|Open https://phpmyadmin.${LEMP_SERVER_DOMAIN} in Browser|Database: Backup Dump|Database: Recover Tables|Remove ${STACK_NAME}|Help"

		for container in $containers; do
			wp_options="$wp_options|Manage $container"
		done
		wp_options="$wp_options|Back to Main Menu"

		# Display WordPress Options
		section_title "MULTISTACK LEMP OPTIONS" ${C_Magenta}
		i=1
		OLD_IFS=$IFS; IFS='|' # Set delimiter for correct iteration
		for option in $wp_options; do
			option_msg "$i. $option" ${C_Magenta}
			i=$((i + 1))
		done
		IFS=$OLD_IFS
		line_break
		option_question "Select an option for $STACK_NAME:"
		line_break

		# Read WordPress Selection
		while true; do
			printf "%s " "$(input_cursor)"
			read wp_choice

			total_wp_options=$(echo "$wp_options" | tr '|' '\n' | wc -l)

			if printf "%s" "$wp_choice" | grep -qE '^[0-9]+$' && [ "$wp_choice" -ge 1 ] && [ "$wp_choice" -le "$total_wp_options" ]; then
				selected_wp_option=$(echo "$wp_options" | tr '|' '\n' | sed -n "${wp_choice}p")
				input_cursor "Selected: ${C_Magenta}'$selected_wp_option'${C_Reset}"
				break
			else
				log_error "Invalid choice, please try again."
			fi
		done
		case "$selected_wp_option" in
		"Create New WordPress Container")
			sh "${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-1-init.sh" "$STACK_NAME"
			;;
		"Start ${STACK_NAME}")
			start_lemp ${STACK_NAME}
			;;
		"Restart ${STACK_NAME}")
			restart_lemp ${STACK_NAME}
			;;
		"Stop ${STACK_NAME}")
			stop_lemp ${STACK_NAME}
			;;
		"Open https://${LEMP_SERVER_DOMAIN} in Browser")
			open_link "https://${LEMP_SERVER_DOMAIN}"
			;;
		"Open https://phpmyadmin.${LEMP_SERVER_DOMAIN} in Browser")
			open_link "https://phpmyadmin.${LEMP_SERVER_DOMAIN}"
			;;
		"Database: Backup Dump")
			sh "${SCRIPTS_PATH}/lemp/database/backup-lemp.sh" "$STACK_NAME"
			;;
		"Database: Recover Tables")
			sh "${SCRIPTS_PATH}/lemp/database/recover-tables.sh" "$STACK_NAME"
			;;
		"Remove ${STACK_NAME}")
			sh "${SCRIPTS_PATH}/multistack/remove-lemp.sh" "$STACK_NAME"
			;;
		"Help")
			lemp_help
			;;
		"Back to Main Menu")
			exec "$0" # Restart script
			;;
		*)

			# ! SELECTED WORDPRESS MANAGEMENT OPTIONS
			# If selected option is "Manage {WordPress Container}"
			if printf "%s" "$selected_wp_option" | grep -q "^Manage "; then
				WORDPRESS_NAME=$(printf "%s" "$selected_wp_option" | cut -d' ' -f2-)
				heading "MANAGE WORDPRESS CONTAINER: $WORDPRESS_NAME"
				# Fetch WordPress container details
				source_wordpress_stack_env "$STACK_NAME" "$WORDPRESS_NAME"

				wordpress_info
				line_break

				# Generate WordPress management options
				wp_manage_options="Start ${WORDPRESS_NAME}|Restart ${WORDPRESS_NAME}|Stop ${WORDPRESS_NAME}|Search & Replace in Database: ${WORDPRESS_DB_NAME}|Open https://${WORDPRESS_SUBDOMAIN}.${LEMP_SERVER_DOMAIN} in Browser|Remove ${WORDPRESS_NAME}|Back to WordPress Menu"

				# Display WordPress Management Options
				section_title "WORDPRESS MANAGEMENT OPTIONS" ${C_Magenta}
				i=1
				OLD_IFS=$IFS; IFS='|' # Set delimiter for correct iteration
				for option in $wp_manage_options; do
					option_msg "$i. $option" ${C_Magenta}
					i=$((i + 1))
				done
				IFS=$OLD_IFS
				line_break
				option_question "Select an option for $WORDPRESS_NAME:"
				line_break

				# Read WordPress Management Selection
				while true; do
					printf "%s " "$(input_cursor)"
					read wp_manage_choice

					total_wp_manage_options=$(echo "$wp_manage_options" | tr '|' '\n' | wc -l)

					if printf "%s" "$wp_manage_choice" | grep -qE '^[0-9]+$' && [ "$wp_manage_choice" -ge 1 ] && [ "$wp_manage_choice" -le "$total_wp_manage_options" ]; then
						selected_wp_manage_option=$(echo "$wp_manage_options" | tr '|' '\n' | sed -n "${wp_manage_choice}p")
						input_cursor "Selected: ${C_Magenta}'$selected_wp_manage_option'${C_Reset}"
						break
					else
						log_error "Invalid choice, please try again."
					fi
				done

				# Execute WordPress Management Action
				case "$selected_wp_manage_option" in
				"Start ${WORDPRESS_NAME}")
					start_wordpress "$STACK_NAME" "$WORDPRESS_NAME"
					;;
				"Restart ${WORDPRESS_NAME}")
					restart_wordpress "$STACK_NAME" "$WORDPRESS_NAME"
					;;
				"Stop ${WORDPRESS_NAME}")
					stop_wordpress "$STACK_NAME" "$WORDPRESS_NAME"
					;;
				"Search & Replace in Database: ${WORDPRESS_DB_NAME}")

					replace_wp_url "$STACK_NAME" "$WORDPRESS_NAME"
					;;
				"Open https://${WORDPRESS_SUBDOMAIN}.${LEMP_SERVER_DOMAIN} in Browser")
					open_link "https://${WORDPRESS_SUBDOMAIN}.${LEMP_SERVER_DOMAIN}"
					;;
				"Remove ${WORDPRESS_NAME}")
					sh "${SCRIPTS_PATH}/lemp/wordpress/remove-wordpress.sh" "$STACK_NAME" "$WORDPRESS_NAME"
					;;
				"Back to WordPress Menu")
					exec "$0" # Restart script to go back
					;;
				esac
			fi
			# ! SELECTED WORDPRESS MANAGEMENT OPTIONS

			;;
		esac
	fi
	# ! SELECTED LEMP STACK  MANAGEMENT OPTIONS
	;;
esac
