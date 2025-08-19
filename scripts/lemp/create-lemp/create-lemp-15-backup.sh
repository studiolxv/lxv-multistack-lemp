#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# BACKUP SCHEDULE COMMAND
heading "BACKUPS - DEBIAN: BOOKWORM SLIM"

section_title "BACKUP SCHEDULE" ${C_Magenta}
example_msg "Choose how often to create .sql dumps from '${DB_HOST_NAME}' container while also running the '${LEMP_DIR}-backups' container"
line_break
warning_msg "NOTE: This will only run if your Docker '${LEMP_DIR}-backups' container is running."

# Options Select Menu START
line_break
section_title "BACKUP SCHEDULE OPTION" ${C_Magenta}
# Display options
option_msg "1. Every 30 minutes" ${C_Magenta}
option_msg "2. Every hour" ${C_Magenta}
option_msg "3. Every 3 hours" ${C_Magenta}
option_msg "4. Every 6 hours" ${C_Magenta}
option_msg "5. Every day" ${C_Magenta}
option_msg "6. Every 2 days" ${C_Magenta}
option_msg "7. Every week" ${C_Magenta}
line_break
option_question "Select Backup Schedule" ${C_Magenta}
# Read user input manually
while true; do
    
    read -p "$(input_cursor)" backup_choice
    
    case "$backup_choice" in
        1)
            export BACKUPS_CRON_SCHEDULE_DESC="Every 30 minutes"
            export BACKUPS_CRON_SCHEDULE="*/30 * * * *"
            break
        ;;
        2)
            export BACKUPS_CRON_SCHEDULE_DESC="Every hour"
            export BACKUPS_CRON_SCHEDULE="0 * * * *"
            break
        ;;
        3)
            export BACKUPS_CRON_SCHEDULE_DESC="Every 3 hours"
            export BACKUPS_CRON_SCHEDULE="0 */3 * * *"
            break
        ;;
        4)
            export BACKUPS_CRON_SCHEDULE_DESC="Every 6 hours"
            export BACKUPS_CRON_SCHEDULE="0 */6 * * *"
            break
        ;;
        5)
            export BACKUPS_CRON_SCHEDULE_DESC="Every day"
            export BACKUPS_CRON_SCHEDULE="0 0 * * *"
            break
        ;;
        6) # Fixed: Changed from duplicate 5) to 6)
            export BACKUPS_CRON_SCHEDULE_DESC="Every 2 days"
            export BACKUPS_CRON_SCHEDULE="0 0 */2 * *"
            break
        ;;
        7) # Fixed: Changed from duplicate 6) to 7)
            export BACKUPS_CRON_SCHEDULE_DESC="Every week"
            export BACKUPS_CRON_SCHEDULE="0 0 * * 0"
            break
        ;;
        *)
            error_msg "Invalid choice, please try again."
            break
        ;;
    esac
done

# Confirm selection
input_cursor "Selected Backup Schedule: ${C_Magenta}${C_Underline}$BACKUPS_CRON_SCHEDULE_DESC"

line_break

#####################################################
# BACKUP CLEANUP COMMAND
section_title "BACKUP CLEANUP"

status_msg "Choose a command to cleanup scheduled backups of your Database."
status_msg "If you chose scheduled backups more frequent than every day choose option 1."
status_msg "If you chose scheduled backups every day choose option 2."
line_break


# Display options manually
section_title "BACKUP CLEANUP OPTIONS" ${C_Magenta}
BACKUPS_CLEANUP_SCRIPT_DESC_ONE="Keep all backups for today, latest per day of the last 30 days, latest per month (Forever)"
option_msg "1. ${BACKUPS_CLEANUP_SCRIPT_DESC_ONE}" ${C_Magenta}
BACKUPS_CLEANUP_SCRIPT_DESC_TWO="Keep all backups from last 30 days, and the Latest of each Month (Forever)"
option_msg "2. ${BACKUPS_CLEANUP_SCRIPT_DESC_TWO}" ${C_Magenta}
line_break
option_question "Select your preferred cleanup command:"


# Read user input manually
while true; do
    read -p "$(input_cursor)" cleanup_choice
    
    case "$cleanup_choice" in
        1)
            export BACKUPS_CLEANUP_ACTION="one"
            export BACKUPS_CLEANUP_SCRIPT_DESC="Keep all backups for today, latest per day for last 30 days, latest per month forever"
            
            break
        ;;
        2)
            export BACKUPS_CLEANUP_ACTION="two"
            export BACKUPS_CLEANUP_SCRIPT_DESC="Keep all backups from last 30 days, and the Latest of each Month (Forever)"
            
            break
        ;;
        *)
            error_msg "Invalid choice, please try again."
        ;;
    esac
done

# EXEC PERMISSIONS
chmod +x "${BACKUPS_SCRIPTS_PATH}/lemp-cleanup-backups.sh"

# Confirm selection
input_cursor "Selected cleanup strategy: ${C_Magenta}${C_Underline}$BACKUPS_CLEANUP_SCRIPT_DESC"
line_break
status_msg "Cleanup script file $LEMP_DIR/scripts/lemp-cleanup-backups.sh"

#####################################################
# BACKUP CLEANUP ENABLE DRY RUN

section_title "BACKUP CLEANUP DRY RUN OPTIONS" ${C_Magenta}
example_msg "Enabling the dry run will only log possible cleanup actions without actually deleting any files."
example_msg "These logs will be stored in the '${LEMP_DIR}/log/backup.log' file as well as printed in the Docker container '${LEMP_DIR}-backups' logs tab on Docker Desktop"
line_break

option_msg "1. Enable - Only log possible cleanup backups for testing" ${C_Magenta}
option_msg "2. Disable - Yes cleanup backups" ${C_Magenta}
line_break
option_question "What would you like to do?"

while true; do
    read -p "$(input_cursor)" cleanup_dryrun_choice
    
    case "$cleanup_dryrun_choice" in
        1)
            export BACKUPS_CLEANUP_DRY_RUN="1"
            break
        ;;
        2)
            export BACKUPS_CLEANUP_DRY_RUN="0"
            break
        ;;
        *)
            error_msg "Invalid choice, please try again."
        ;;
    esac
done

#####################################################
# CREATE BACKUP LOG
# Start the backup.log
export BACKUPS_LOG="${LEMP_PATH}/backup.log"
line_break
section_title "BACKUP LOG"
body_msg "Creating backup log at $BACKUPS_LOG"

cat <<EOL >"$BACKUPS_LOG"
# Backup Log created on $(date)

EOL

BACKUPS_CONTAINER_BACKUPS_PATH=""
BACKUPS_CONTAINER_GHOST_BACKUPS_PATH=""

#####################################################
# CREATE LEMP/CRONTAB FILE
line_break
section_title "BACKUP CRONTAB"
export BACKUPS_CRONTAB_FILE="${LEMP_PATH}/crontab"
body_msg "Creating backup crontab at $BACKUPS_CRONTAB_FILE"
# Start the .env
cat <<EOL >"$BACKUPS_CRONTAB_FILE"
# Backup ${BACKUPS_CRON_SCHEDULE_DESC}
${BACKUPS_CRON_SCHEDULE} /scripts/lemp-backup.sh "cron" >> ./backup.log 2>&1

EOL

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-16-env-files.sh"
