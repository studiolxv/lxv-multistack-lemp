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

backup_log "#############################################################################"

backup_log "🔥 Running $(basename "$0")..."

if [ "$BACKUP_CLEANUP_ACTION" = "one" ]; then

	# Step 1: Define time variables
	THIRTY_DAYS_AGO=$(date -d "30 days ago" "+%Y-%m-%d")

	# Step 2: Keep only the latest backup of each day for the last 30 days
	backup_log "📅 Keeping only the latest backup per day for the last 30 days..."
	find /backups -type f -name "*.sql" ! -name "*$TODAY*" -mtime +1 -mtime -30 | while IFS= read -r file; do
		day=$(echo "$file" | awk -F'[_ ]' '{print substr($1,1,10)}')
		latest_backup=$(find /backups -type f -name "*$day*" | sort -r | head -n 1)
		echo "✅ Keeping latest backup for $day: $latest_backup"
		find /backups -type f -name "*$day*" ! -newer "$latest_backup" -exec rm -f {} \;
	done

	# Step 3: Keep only the latest backup per month for anything older than 30 days
	backup_log "📅 Keeping only the latest backup per month for backups older than 30 days..."
	find /backups -type f -name "*.sql" -mtime +30 | while IFS= read -r file; do
		month=$(echo "$file" | awk -F'[_ ]' '{print substr($1,1,7)}')
		latest_backup=$(find /backups -type f -name "*$month*" | sort -r | head -n 1)
		echo "✅ Keeping latest backup for $month: $latest_backup"
		find /backups -type f -name "*$month*" ! -newer "$latest_backup" -exec rm -f {} \;
	done

# END ONE
elif [ "$BACKUP_CLEANUP_ACTION" = "two" ]; then
	# Backup Cleanup 1: Find backups older than 30 days and save the latest one per month
	mkdir -p /backups/monthly-temp

	#Backup Cleanup 2: Find all backups from this month, keep only the latest, move it to /backups/monthly-temp
	find /backups -type f -name "*.sql" -mtime +30 | while IFS= read -r file; do
		month=$(echo "$file" | awk -F'[_ ]' '{print substr($1,1,7)}')
		latest_backup=$(find /backups -type f -name "*$month*" | sort -r | head -n 1)
		if [ -n "$latest_backup" ]; then
			mv "$latest_backup" /backups/monthly-temp/
		fi
	done

	# Backup Cleanup 3: Delete all backups older than 30 days (EXCEPT the ones saved in /backups/monthly)
	find /backups -type f -name "*.sql" -mtime +30 -exec rm -f {} \;

	# Backup Cleanup 4: Move monthly backups back to /backups for consistency, rm monthly-temp
	mv /backups/monthly-temp/*.sql /backups/ 2>/dev/null
	rmdir /backups/monthly-temp 2>/dev/null
# END TWO
else
	backup_log "❌ Invalid BACKUP_CLEANUP_ACTION: $BACKUP_CLEANUP_ACTION"
	exit 1
fi

backup_log "🎉 [$(date)] Backup cleanup completed successfully!"
