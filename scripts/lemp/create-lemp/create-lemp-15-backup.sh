#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# BACKUP SCHEDULE COMMAND
DB_HOST_NAME_UC="$(uc_word "$DB_HOST_NAME")"
heading "${DB_HOST_NAME_UC} BACKUPS"

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
warning_msg "NOTE: This will only run if your Docker '${LEMP_DIR}-backups' container is running for the length of time specified in the cron schedule."

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
            error_msg "Invalid choice, or you clicked enter out of bounds"
            body_msg "Defaulting to: Every 3 hours"
            line_break
            export BACKUPS_CRON_SCHEDULE_DESC="Every 3 hours"
            export BACKUPS_CRON_SCHEDULE="0 */3 * * *"
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

BACKUPS_CLEANUP_SCRIPT_DESC_GFS="(GFS) Grandfather-Father-Son — keep last 48 hourly, 14 daily, 8 weekly (Sundays), 12 monthly (1st of month), and 3 yearly (Jan 1) backups"
option_msg "3. ${BACKUPS_CLEANUP_SCRIPT_DESC_GFS}" ${C_Magenta}

BACKUPS_CLEANUP_SCRIPT_DESC_RWMA="(RWMA) Rolling window + monthly anchors — keep last 7 days, 1 per day: days 8–30, 1 per week: weeks 5–12, & 1 per month: months 4–24"
option_msg "4. ${BACKUPS_CLEANUP_SCRIPT_DESC_RWMA}" ${C_Magenta}

BACKUPS_CLEANUP_SCRIPT_DESC_NONE="None"
option_msg "5. ${BACKUPS_CLEANUP_SCRIPT_DESC_NONE}" ${C_Magenta}

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
            export BACKUPS_CLEANUP_ACTION="gfs"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_GFS}"
            break
        ;;
        4)
            export BACKUPS_CLEANUP_ACTION="rwma"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_RWMA}"
            break
        ;;
        5)
            export BACKUPS_CLEANUP_ACTION="none"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_NONE}"
            break
        ;;
        *)
            error_msg "Invalid choice, or you clicked enter out of bounds"
            body_msg "Defaulting to: none"
            line_break
            export BACKUPS_CLEANUP_ACTION="none"
            export BACKUPS_CLEANUP_SCRIPT_DESC="${BACKUPS_CLEANUP_SCRIPT_DESC_NONE}"
            break
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
if [ "${BACKUPS_CLEANUP_ACTION}" = "none" ]; then
    section_title "BACKUP CLEANUP DRY RUN OPTIONS" ${C_Magenta}
    example_msg "Enabling the dry run will only log possible cleanup actions without actually deleting any files."
    example_msg "These logs will be stored in the '${LEMP_DIR}/log/backup_*.log' file as well as printed in the Docker container '${LEMP_DIR}-backups' logs tab on Docker Desktop"
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
                error_msg "Invalid choice, or you clicked enter out of bounds"
                body_msg "Defaulting to: Enable - Only log possible cleanup backups for testing"
                line_break
                
                export BACKUPS_CLEANUP_DRY_RUN="1"
            ;;
        esac
    done
else
    export BACKUPS_CLEANUP_DRY_RUN="1"
fi
#####################################################
# BACKUP CLEANUP USE OS TRASH
if [ "${BACKUPS_CLEANUP_ACTION}" = "none" ]; then
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
                error_msg "Invalid choice, or you clicked enter out of bounds"
                body_msg "Defaulting to: Enable - Move deleted files to the OS Trash"
                line_break
                
                export BACKUPS_USE_OS_TRASH="1"
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
                error_msg "Invalid choice, or you clicked enter out of bounds"
                body_msg "Defaulting to: Allow fallback - Use permanent delete if OS Trash not available"
                line_break
                
                export BACKUPS_REQUIRE_OS_TRASH="1"
            ;;
        esac
    done
else
    export BACKUPS_REQUIRE_OS_TRASH="0"
fi
#####################################################
# EXPLAIN BACKUP LOG
line_break
section_title "BACKUP LOG & MANIFEST"
body_msg "Backup_*.log files will be located on your host machine ${LEMP_PATH}/log/*"
example_msg "Use the backup_manifest.log for a full complete list of all files created and their checksums"
example_msg "to check the file for corruption run on macos \"% shasum -a 256 path/to/file\" and compare checksum value from manifest"

#####################################################
# CREATE CRON TEMPLATE HERE

line_break
section_title "CRON JOBS"
example_msg "Creating cron template file loaded when backups container initializes"
example_msg "Make edits here and restart: '${BACKUPS_CRONTAB_FILE}'"

CONTAINER_CRON_ENV=/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh
CONTAINER_CRON_BACKUP=/${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh
CONTAINER_CRON_LOG=${LOG_CONTAINER_PATH}/backups/backup_cron_console.log
CONTAINER_CRON_TEST_LOG=${LOG_CONTAINER_PATH}/backups/backup_cron_test.log

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
    body_msg "⚙️ Testing Cron"
    body_msg "Adding \"Backup Every 2 Minutes\" to crontab..."
    body_msg "This cron job will add probe lines to \"backup_cron_test.log\""
    body_msg "Make sure you comment out of the cron if this is working."
    
    # Create the crontab file
   cat > "$BACKUPS_CRONTAB_FILE" <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# (USER) Mounted Backups "${BACKUPS_CRON_SCHEDULE_DESC}"
${BACKUPS_CRON_SCHEDULE} root . ${CONTAINER_CRON_ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "${CONTAINER_CRON_BACKUP} cron" >> ${CONTAINER_CRON_LOG} 2>&1

# (GHOST) Unmounted Backups "Every 30 Minutes"
*/30 * * * * root . ${CONTAINER_CRON_ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "${CONTAINER_CRON_BACKUP} ghost" >> ${CONTAINER_CRON_LOG} 2>&1

# (CRON TEST) Testing the cron - comment when working "Every 1 Minute"
* * * * * root /bin/date "+\%F \%T cron.d OK" >> ${CONTAINER_CRON_TEST_LOG} 2>&1

EOF
    
    
else
    
    warning_msg "You selected No cron backups"
    warning_msg "Uncomment out the lines in the template you want to use."
    # Create the crontab file template commented out
   cat > "$BACKUPS_CRONTAB_FILE" <<EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# (USER) Mounted Backups "${BACKUPS_CRON_SCHEDULE_DESC}"
#${BACKUPS_CRON_SCHEDULE} root . ${CONTAINER_CRON_ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "${CONTAINER_CRON_BACKUP} cron" >> ${CONTAINER_CRON_LOG} 2>&1

# (GHOST) Unmounted Backups "Every 30 Minutes"
#*/30 * * * * root . ${CONTAINER_CRON_ENV}; flock -n /tmp/lemp-backup.lock /bin/sh -lc "${CONTAINER_CRON_BACKUP} ghost" >> ${CONTAINER_CRON_LOG} 2>&1

# (CRON TEST) Testing the cron - comment when working "Every 1 Minute"
* * * * * root /bin/date "+\%F \%T cron.d OK" >> ${CONTAINER_CRON_TEST_LOG} 2>&1

EOF
    
fi

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-16-env-files.sh"
