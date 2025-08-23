#!/bin/sh
# Ensure environment variables are loaded
set -a # Auto-export all variables
. /etc/environment
. "/${BACKUPS_CONTAINER_NAME}/.env"
. "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a # Disable auto-export

# To run this script, you need to be in the same directory as the script
# sh ./scripts/lemp-ghost-backup-restore.sh

# Time
TIMESTAMP=$(get_timestamp)
LOCAL_TIME=$(get_local_time)
TODAY_DIR=$(get_today_dir)

backup_heading "⤵️ Running $(basename "$0")"

# Define backup directory
BACKUP_DIR="/${CONTAINER_GHOST_BACKUPS_PATH}"

# Ensure the directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# List available backups
echo "📂 Available backups:"
BACKUPS=$(ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null)

# Check if any backups exist
if [ -z "$BACKUPS" ]; then
    echo "❌ No backup files found in $BACKUP_DIR"
    exit 1
fi

# Display backup options manually (Fix for non-interactive shell)
echo "Select a backup file by typing its number:"
i=1
for BACKUP_FILE in $BACKUPS; do
    echo "$i) $BACKUP_FILE"
    i=$((i + 1))
done

read -p "Enter the number of the backup file: " BACKUP_NUMBER
i=1
for BACKUP_FILE in $BACKUPS; do
    if [ "$i" -eq "$BACKUP_NUMBER" ]; then
        echo "✅ Selected: $BACKUP_FILE"
        break
    fi
    i=$((i + 1))
done

if [ -z "$BACKUP_FILE" ]; then
    echo "❌ Invalid selection, exiting."
    exit 1
fi

# Confirm restoration
echo "⚠️ WARNING: This will replace the current database with the selected backup!"
echo -n "🔄 Proceed? (yes/no): "
read CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "🚫 Operation canceled."
    exit 0
fi

# Read MySQL root password from secrets file
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_user_password)

# Drop all existing databases (excluding system DBs) - FIXED LOOP
echo "🛑 Dropping all databases (except system ones)..."
DATABASES=$(mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "^(Database|mysql|information_schema|performance_schema|sys)$")

echo "$DATABASES" | while read -r db; do
    echo "🗑️ Dropping database: $db"
    mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE \`$db\`;"
done

# Restore selected backup
echo "♻️ Restoring $BACKUP_FILE..."
mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" <"$BACKUP_FILE"

echo "🎉 Database restoration complete!"
