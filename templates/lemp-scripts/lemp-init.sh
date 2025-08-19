#!/bin/sh
# Ensure environment variables are loaded
set -a # Auto-export all variables
. /etc/environment
. "/${BACKUPS_CONTAINER_NAME}/.env"
. "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a # Disable auto-export

# Time
TIMESTAMP=$(get_timestamp)
LOCAL_TIME=$(get_local_time)
TODAY_DIR=$(get_today_dir)

backup_log "Running $(basename "$0") #############################################################################"

# Wait for MySQL to be ready
COUNT=0
while [ "$COUNT" -lt 30 ]; do
    if mysqladmin ping -h "$MYSQL_HOST" -u "$MYSQL_USER" --silent; then
        backup_log "✅ MySQL is ready!"
        break
    fi
    backup_log " ⏳ MySQL is not ready yet..."
    COUNT=$((COUNT + 1))
    sleep 2
done

start_cron() {
    backup_log "🕛 ADDING CRON JOBS..."
    backup_log "👻 Ghost Backups"
    backup_log "├── Adding \"Unmounted ghost backups every 15 minutes\" to crontab..."
    backup_log "└── only accessible from the container, once docker down they disappear forever"
    
    # Ensure environment variables are available to cron
    backup_log "✨ Exporting environment variables for cron..."
    EXPORT_ENV_FILE="/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
    cat /etc/environment >/tmp/debug_env.log # Debugging: Check this file to Verify variables exist
    
    # Every 15 minutes - Backups stored only in the container
    GHOST_DB_BACKUP_CRON_JOB="*/15 * * * * . ${EXPORT_ENV_FILE}; /${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh \"ghost\" >> /var/log/backup.log 2>&1"
    backup_log ""
    
    # User-defined backup schedule with mounted storage
    backup_log "😀 User Defined Backups"
    backup_log "├── Adding \"${BACKUPS_CRON_SCHEDULE_DESC}\" to crontab..."
    backup_log "└── This cron job will save backups to \"${CONTAINER_BACKUPS_PATH}\""
    
    MOUNTED_DB_BACKUP_CRON_JOB="$BACKUPS_CRON_SCHEDULE . ${EXPORT_ENV_FILE}; /${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh \"cron\" >> /var/log/backup.log 2>&1"
    
    # Preserve existing cron jobs and append new ones
    (
        # Remove old entries matching "/scripts/lemp-backup.sh"
        crontab -l 2>/dev/null | grep -v -F "/scripts/lemp-backup.sh"
        echo "$GHOST_DB_BACKUP_CRON_JOB"
        echo "$MOUNTED_DB_BACKUP_CRON_JOB"
    ) | crontab -
    
    # Restart cron to apply changes
    backup_log "🔃 Restarting cron to apply new jobs..."
    service cron restart
    
    backup_log "🔍 Showing current cron jobs:"
    crontab -l
}

# Start cron for scheduled backups
backup_log "🕒 Starting cron..."
if ! command -v cron >/dev/null 2>&1; then
    backup_log "❌ Cron not found! Installing..."
    apt-get update && apt-get install -y cron
    start_cron
else
    start_cron
fi

# Run initial backup
sh /${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh "initial"
wait $!

# Shutdown handler function
shutdown_handler() {
    backup_log "⚠️ Stopping container, running shutdown backup..."
    ${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh "shutdown"
    backup_log "✅ Final backup complete. Exiting container."
    exit 0 # Ensure clean exit
}

# Set trap for SIGTERM and SIGINT
trap shutdown_handler TERM INT

# Run main process
while true; do
    sleep 1 &
    wait $!
done
