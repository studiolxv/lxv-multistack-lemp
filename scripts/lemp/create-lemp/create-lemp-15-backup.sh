#!/bin/sh
. "$PROJECT_PATH/_environment.sh"
file_msg "$(basename "$0")"

#####################################################
# BACKUP SCHEDULE COMMAND
DB_HOST_NAME_UPPER=$(printf '%s' "${DB_HOST_NAME}" | tr '[:lower:]' '[:upper:]')
heading "${DB_HOST_NAME_UPPER} BACKUPS"

example_msg "NOTE:"
example_msg "Our backup script will ${C_Underline}ALWAYS${C_Reset} dump a .sql backup"
example_msg "of your '${DB_HOST_NAME}' container (full db) ${C_Underline}AND${C_Reset}"
example_msg "each Wordpress container database (wp db table) separately upon docker-compose"
example_msg "up and down of '${LEMP_DIR}-backups' container."
example_msg ""
example_msg "Backup directory: ${BACKUPS_PATH}"
line_break

section_title "BACKUP SCHEDULE" ${C_Magenta}
example_msg "Choose how often to create .sql dumps through cron jobs."
line_break
warning_msg "NOTE: This will only run if your Docker '${LEMP_DIR}-backups' container is running."

# Options Select Menu START
line_break
section_title "CRON OPTIONS" ${C_Magenta}
# Display options
option_msg "1. Backup every 30 minutes" ${C_Magenta}
option_msg "2. Backup every hour" ${C_Magenta}
option_msg "3. Backup every 3 hours" ${C_Magenta}
option_msg "4. Backup every 6 hours" ${C_Magenta}
option_msg "5. Backup every day" ${C_Magenta}
option_msg "6. Backup every 2 days" ${C_Magenta}
option_msg "7. No cron backups" ${C_Magenta}
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
        6)
            export BACKUPS_CRON_SCHEDULE_DESC="Every 2 days"
            export BACKUPS_CRON_SCHEDULE="0 0 */2 * *"
            break
        ;;
        7)
            export BACKUPS_CRON_SCHEDULE_DESC="No cron backups"
            export BACKUPS_CRON_SCHEDULE="# <<Uncomment and replace this with your preferred cron schedule>>"
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
# BACKUP SQL DUMP CLEANUP COMMAND
section_title "CLEANUP SQL BACKUPS"
status_msg "Choose a command to cleanup your saved backup .sql files of your Database."
line_break

# CLEANUP OPTIONS
section_title "CLEANUP OPTIONS" ${C_Magenta}

BACKUPS_CLEANUP_SCRIPT_DESC_ONE="Keep all backups for today, latest per day of the last 30 days, latest per month (Forever)"
option_msg "1. ${BACKUPS_CLEANUP_SCRIPT_DESC_ONE}" ${C_Magenta}

BACKUPS_CLEANUP_SCRIPT_DESC_TWO="Keep all backups from last 30 days, and the Latest of each Month (Forever)"
option_msg "2. ${BACKUPS_CLEANUP_SCRIPT_DESC_TWO}" ${C_Magenta}

BACKUPS_CLEANUP_SCRIPT_DESC_THREE="None"
option_msg "3. ${BACKUPS_CLEANUP_SCRIPT_DESC_THREE}" ${C_Magenta}

line_break
option_question "Select your preferred cleanup command:"


# Read user input manually
while true; do
    read -p "$(input_cursor)" cleanup_choice
    
    case "$cleanup_choice" in
        1)
            export BACKUPS_CLEANUP_ACTION="one"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_ONE}"
            break
        ;;
        2)
            export BACKUPS_CLEANUP_ACTION="two"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_TWO}"
            break
        ;;
        3)
            export BACKUPS_CLEANUP_ACTION="none"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_THREE}"
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
if [ ! -n "${BACKUPS_CLEANUP_ACTION}" = "none" ]; then
    section_title "BACKUP CLEANUP DRY RUN OPTIONS" ${C_Magenta}
    example_msg "Enabling the dry run will only log possible cleanup actions without actually deleting any files."
    example_msg "These logs will be stored in the '${LEMP_DIR}/log/backup.log' file as well as printed in the Docker container '${LEMP_DIR}-backups' logs tab on Docker Desktop"
    line_break
    
    option_msg "1. Enable - Only log possible cleanup backups for testing" ${C_Magenta}
    option_msg "2. Disable - Yes cleanup backups" ${C_Magenta}
    line_break
    option_question "What would you like to do?"
    
    while true; do
        read -p "$(input_cursor)" cleanup_dry_run_choice
        
        case "$cleanup_dry_run_choice" in
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
else
    export BACKUPS_CLEANUP_DRY_RUN="1"
fi
#####################################################
# BACKUP CLEANUP USE OS TRASH
if [ ! -n "${BACKUPS_CLEANUP_ACTION}" = "none" ]; then
    section_title "BACKUP CLEANUP USE OS TRASH" ${C_Magenta}
    example_msg "You can send deleted backups to the OS Trash/Recycle Bin instead of permanently removing them."
    example_msg "This allows easier recovery but requires an available trash utility on your system."
    line_break
    
    option_msg "1. Enable - Move deleted files to the OS Trash" ${C_Magenta}
    option_msg "2. Disable - Permanently delete files" ${C_Magenta}
    line_break
    option_question "Do you want to use the OS Trash?"
    
    while true; do
        read -p "$(input_cursor)" use_os_trash_choice
        
        case "$use_os_trash_choice" in
            1)
                export BACKUPS_USE_OS_TRASH="1"
                break
            ;;
            2)
                export BACKUPS_USE_OS_TRASH="0"
                break
            ;;
            *)
                error_msg "Invalid choice, please try again."
            ;;
        esac
    done
else
    export BACKUPS_USE_OS_TRASH="0"
fi
#####################################################
# BACKUP CLEANUP REQUIRE OS TRASH
if [ ! "${BACKUPS_CLEANUP_ACTION}" = "none" ] && [ "${BACKUPS_USE_OS_TRASH}" = "1" ] ; then
    section_title "BACKUP CLEANUP REQUIRE OS TRASH" ${C_Magenta}
    example_msg "If enabled, the cleanup will abort if OS Trash support is not available."
    example_msg "If disabled, the cleanup will fall back to permanently deleting files."
    line_break
    
    option_msg "1. Require - Abort if OS Trash is not available" ${C_Magenta}
    option_msg "2. Allow fallback - Use permanent delete if OS Trash not available" ${C_Magenta}
    line_break
    option_question "Do you require OS Trash to be available?"
    
    while true; do
        read -p "$(input_cursor)" require_os_trash_choice
        
        case "$require_os_trash_choice" in
            1)
                export BACKUPS_REQUIRE_OS_TRASH="1"
                break
            ;;
            2)
                export BACKUPS_REQUIRE_OS_TRASH="0"
                break
            ;;
            *)
                error_msg "Invalid choice, please try again."
            ;;
        esac
    done
else
    export BACKUPS_REQUIRE_OS_TRASH="0"
fi
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
# CREATE CRON TEMPLATE HERE

line_break
section_title "CRON JOBS"
example_msg "Creating cron template file loaded when backups container initializes"
example_msg "Make edits here and restart: '${BACKUPS_CRONTAB_FILE}'"

if [ ! "${BACKUPS_CRON_SCHEDULE_DESC}" = "No cron backups" ]; then
    
    # User-defined backup schedule with mounted storage
    body_msg "😀 User Defined Backups (Mounted Storage)"
    body_msg "Adding \"${BACKUPS_CRON_SCHEDULE_DESC}\" to crontab..."
    body_msg "This cron job will save backups to \"${CONTAINER_BACKUPS_PATH}\""
    body_msg ""
    body_msg "👻 Ghost Backups (Unmounted Virtual Storage)"
    body_msg "Adding \"Unmounted backups every 15 minutes\" to crontab..."
    body_msg "\"$BACKUPS_CONTAINER_GHOST_BACKUPS_PATH\""
    body_msg "NOTE: Only accessible from inside the container, once docker down they disappear forever (spooky)"
    body_msg ""
    body_msg "⚙️ Testing Backups (Mounted Storage)"
    body_msg "Adding \"Backup Every 2 Minutes\" to crontab..."
    body_msg "This cron job will save backups to \"${CONTAINER_BACKUPS_PATH}\""
    body_msg "Make sure you comment out of the cron if this is working."
    
    
    # Create the crontab file
   <<EOF $BACKUPS_CRONTAB_FILE
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV=/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh
BACKUP=/${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh
LOG=/var/log/backup.log

# (USER) Mounted Backups "${BACKUPS_CRON_SCHEDULE_DESC}"
${BACKUPS_CRON_SCHEDULE} root . \${ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "\${BACKUP} cron" >> \${LOG} 2>&1

# (GHOST) Unmounted Backups "Every 30 Minutes"
*/30 * * * * root . \${ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "\${BACKUP} ghost" >> \${LOG} 2>&1

EOF
    
    
else
    
    warning_msg "You selected No cron backups"
    warning_msg "Uncomment out the lines in the template you want to use."
    # Create the crontab file template commented out
   <<EOF $BACKUPS_CRONTAB_FILE
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV=/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh
BACKUP=/${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh
LOG=/var/log/backup.log

# (USER) Mounted Backups "${BACKUPS_CRON_SCHEDULE_DESC}"
#${BACKUPS_CRON_SCHEDULE} root . \${ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "\${BACKUP} cron" >> \${LOG} 2>&1

# (GHOST) Unmounted Backups "Every 30 Minutes"
#*/30 * * * * root . \${ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "\${BACKUP} ghost" >> \${LOG} 2>&1

EOF
    
fi

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-16-env-files.sh"
