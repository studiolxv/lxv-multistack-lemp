#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

if [ -f "${PROJECT_ENV_FILE}" ] && [ ! "${INSTALLATION_COMPLETE}" = true ]; then
	heading "Installation Complete"
	success_msg "Initial check to see if .env file exists"
fi

lxv_header
line_break

 if [ -f "${PROJECT_ENV_FILE}" ] && [ ! "${INSTALLATION_COMPLETE}" = true ]; then
	update_env_var "INSTALLATION_COMPLETE" true
	line_break
fi

# Fetch available LEMP stacks
stacks="$(list_dirs stacks $opt_sort)"

# Generate menu options without extra newlines
options="Create New LEMP Stack"
for stack in $stacks; do
    options="$options|Manage $stack"
done
options="$options|Help|Quit"



# Display Options
section_title "OPTIONS" ${C_Magenta}
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

    # After you calculate total_options
    total_options=$(printf '%s' "$options" | tr '|' '\n' | wc -l | tr -d '[:space:]')
    help_index=$((total_options - 1))
    quit_index=$((total_options))

    if printf "%s" "$choice" | grep -qE '^[0-9]+$' && [ "$choice" -ge 1 ]; then
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
    *)
        # ! SELECTED LEMP STACK  MANAGEMENT OPTIONS
        # If the selection starts with "Manage", extract the stack name and list WordPress containers
        if printf "%s" "$selected_option" | grep -q "^Manage "; then
            STACK_NAME=$(printf "%s" "$selected_option" | cut -d' ' -f2-)
			sh "${SCRIPTS_PATH}/lemp/manage-lemp.sh" "$STACK_NAME"

        fi
        # ! SELECTED LEMP STACK  MANAGEMENT OPTIONS
        if [ "$selected_option" = "Help" ]; then
            multistack_help
            line_break
            printf "%s " "$(input_cursor)Press 'e' to exit back to main menu: "
            read ans
            if [ "$ans" = "e" ]; then
                line_break
                sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh"
            fi
        fi
        if [ "$selected_option" = "Quit" ]; then
            exit 0
        fi

    ;;
esac
