#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# DATABASE IMAGE
section_title "DATABASE IMAGE"

if [ -n "${DEFAULT_DB_IMAGE:-}" ]; then
    input_cursor "DEFAULT_DB_IMAGE is defined: $DEFAULT_DB_IMAGE"
    DB_IMAGE="$DEFAULT_DB_IMAGE"
    # Rename the database directory to selected db image
    DB_DIR=$(sanitize_string "$DB_IMAGE" "-")
    DB_HOST_NAME="${LEMP_SERVER_DOMAIN_NAME}-${DB_DIR}"
    DB_PATH="$LEMP_PATH/${DB_DIR}"
    DB_DATA_PATH="${DB_PATH}/${DB_DATA_DIR}"
    BACKUPS_PATH="${DB_PATH}/${BACKUPS_DIR}"
else

    body_msg "Now let's select the optimal database image for this LEMP stack..."
    line_break
    # Get the value of DB_IMAGE from the .env file
    DB_IMAGE=$(get_env_variable_value DB_IMAGE)

    # Check if the function succeeded
    if [ $? -ne 0 ]; then

        #####################################################
        # DATABASE IMAGE OPTION

        # Ask if this database is for WordPress
        section_title "WORDPRESS COMPATIBILITY" ${C_Magenta}
        option_question "Is this database for a WordPress installation? (y/n):"

        while true; do
            printf "%s " "$(input_cursor)"
            read is_wordpress_db

            case "$is_wordpress_db" in
                [yY])
                    # WordPress-compatible databases only
                    line_break
                    section_title "WORDPRESS DATABASE OPTIONS" ${C_Magenta}
                    body_msg "Select a WordPress-compatible database image"
                    line_break
                    db_options="MySQL|MariaDB|Percona"
                    break
                ;;
                [nN])
                    # All databases
                    line_break
                    section_title "DATABASE OPTIONS" ${C_Magenta}
                    body_msg "Select any project-compatible database image"
                    line_break
                    db_options="MySQL|MariaDB|Percona|PostgreSQL|MongoDB|Redis|Enter your own"
                    break
                ;;
                *)
                    log_error "Invalid choice. Please enter 'y' or 'n'."
                ;;
            esac
        done
        # Step 1: Choose a database type first
        i=1
        OLD_IFS=$IFS; IFS='|' # Set delimiter for correct iteration
        for option in $db_options; do
            option_msg "$i. $option" ${C_Magenta}
            i=$((i + 1))
        done
        IFS=$OLD_IFS

        line_break
        option_question "Select a database type:"

        # Read database selection
        while true; do
            printf "%s " "$(input_cursor)"
            read db_choice

            total_db_options=$(echo "$db_options" | tr '|' '\n' | wc -l)

            if printf "%s" "$db_choice" | grep -qE '^[0-9]+$' && [ "$db_choice" -ge 1 ] && [ "$db_choice" -le "$total_db_options" ]; then
                selected_db=$(echo "$db_options" | tr '|' '\n' | sed -n "${db_choice}p")
                input_cursor "Selected: ${C_Magenta}'$selected_db'"
                break
            else
                log_error "Invalid choice, please try again."
            fi
        done

        # Map selection to database repository names
        case "$selected_db" in
            "MySQL") DB_REPO="mysql" ;;
            "MariaDB") DB_REPO="mariadb" ;;
            "Percona") DB_REPO="percona" ;;
            "PostgreSQL") DB_REPO="postgres" ;;
            "MongoDB") DB_REPO="mongo" ;;
            "Redis") DB_REPO="redis" ;;
            "Enter your own")
                status_msg "Enter your preferred database Docker image name (e.g., mysql, mariadb, postgres):"
                printf "%s" "$(input_cursor)"
                read DB_REPO
            ;;
            *)
                error_msg "Invalid choice, please try again."
                exit 1
            ;;
        esac

        # Step 2: Fetch latest minor versions of the selected database
        line_break

        status_msg "🔃   Fetching latest versions for $DB_REPO... be patient, this may take a few minutes."

        REPO_DB_IMAGES=$(fetch_all_latest_minor_versions "$DB_REPO" | sort -Vr) # Sort in descending order
        DB_REPO_UCCASE="$(uc_word "$DB_REPO")"

        # Step 3: Let the user choose a version
        # Dynamically populate selection list
        INDEX=1
        AVAILABLE_IMAGES=""

        line_break
        # Display database version options
        section_title "${DB_REPO_UCCASE} VERSION OPTIONS" ${C_Magenta}

        for VERSION in $REPO_DB_IMAGES; do
            AVAILABLE_IMAGES="$AVAILABLE_IMAGES\n$INDEX ${DB_REPO}:$VERSION"
            option_msg "$INDEX. ${DB_REPO}:${VERSION}" ${C_Magenta}
            INDEX=$((INDEX + 1))
        done
        # Add custom option
        option_msg "$INDEX. Enter your own" ${C_Magenta}
        line_break
        option_question "Select a version for $DB_REPO:"

        # Read user input dynamically
        while true; do

            printf "%s" "$(input_cursor)"
            read DB_CHOICE

            # Find the matching choice
            CHOSEN_IMAGE=$(printf "%b" "$AVAILABLE_IMAGES" | awk -v choice="$DB_CHOICE" '$1 == choice {print $2}')

            if [ -n "$CHOSEN_IMAGE" ]; then
                DB_IMAGE="$CHOSEN_IMAGE"
                break
                elif [ "$DB_CHOICE" -eq "$INDEX" ]; then
                status_msg "Enter your preferred database Docker image (e.g. mysql:8.0)"
                printf "%s" "$(input_cursor)"
                read INPUT_DB_IMAGE
                DB_IMAGE="${INPUT_DB_IMAGE}"
                break
            else
                error_msg "Invalid choice, please try again."
            fi
        done

        # Confirm selection
        input_cursor "Selected: ${C_Magenta}'$DB_IMAGE'"

        # Rename the database directory to selected db image
        DB_DIR=$(sanitize_string "$DB_IMAGE" "-")
        DB_HOST_NAME="${LEMP_SERVER_DOMAIN_NAME}-${DB_DIR}"
        DB_PATH="$LEMP_PATH/${DB_DIR}"
        DB_DATA_PATH="${DB_PATH}/${DB_DATA_DIR}"
        BACKUPS_PATH="${DB_PATH}/${BACKUPS_DIR}"

    else
        status_msg "DB_IMAGE is set to: $DB_IMAGE, if this is incorrect delete .env and rerun ./start.sh"
    fi
fi

line_break

#####################################################
# MAKE DB DIRECTORY
mkdir -p "${LEMP_PATH}/${DB_DIR}"

#####################################################
# EXPORT
export DB_IMAGE="${DB_IMAGE}"
export DB_DIR="${DB_DIR}"
export DB_HOST_NAME="${DB_HOST_NAME}"
export DB_PATH="${DB_PATH}"
export DB_DATA_PATH="${DB_DATA_PATH}"
export BACKUPS_PATH="${BACKUPS_PATH}"
export BACKUPS_CRON_DIR="${DB_PATH}/cron"
mkdir -p "$BACKUPS_CRON_DIR"
export BACKUPS_CRONTAB_FILE="${BACKUPS_CRON_DIR}/backups"

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-7-directory-db-config.sh"
