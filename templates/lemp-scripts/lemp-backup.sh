#!/bin/sh
# Ensure environment variables are loaded
set -a # Auto-export all variables
. /etc/environment
. "/${BACKUPS_CONTAINER_NAME}/.env"
. "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a # Disable auto-export

BACKUP_TYPE="$1"

# Time
TIMESTAMP=$(get_timestamp)
LOCAL_TIME=$(get_local_time)
TODAY_DIR=$(get_today_dir)


backup_log "📄 Running ${BACKUP_TYPE} $(basename "$0") >>>"

# Starting Message
if [ "$BACKUP_TYPE" = "initial" ]; then
    backup_log "(${BACKUP_TYPE}) 🚀 Initial database backup..."
    elif [ "$BACKUP_TYPE" = "cron" ] || [ "$BACKUP_TYPE" = "cron-test" ]; then
    backup_log "(${BACKUP_TYPE}) 🕒 Running cron scheduled database backup..."
    backup_log "(${BACKUP_TYPE}) 🕒 Schedule: $BACKUPS_CRON_SCHEDULE_DESC"
    elif [ "$BACKUP_TYPE" = "shutdown" ]; then
    backup_log "(${BACKUP_TYPE}) ⚠️ Shutdown database backup..."
    elif [ "$BACKUP_TYPE" = "ghost" ]; then
    backup_log "(${BACKUP_TYPE}) ⚠️ Running (Container ONLY) Ghost database backup..."
    backup_log "(${BACKUP_TYPE}) ⚠️ Once the container is stopped, these backups are lost."
else
    backup_log "(${BACKUP_TYPE}) ❌ Invalid backup type..."
    exit 1
fi

backup_log "(${BACKUP_TYPE}) 🔍 ENVIRONMENT VARIABLES CHECK"
backup_log "(${BACKUP_TYPE}) ├── \$MYSQL_HOST = $MYSQL_HOST"
backup_log "(${BACKUP_TYPE}) └── if \$MYSQL_HOST = is empty environment variables are not being set"

# Perform DUMP ALL ${DB_HOST_NAME} database's "create" backup

# Detect if the database is MariaDB or MySQL
DB_TYPE=$(mysql -h "$MYSQL_HOST" -u root -e "SELECT @@version_comment;" 2>/dev/null | awk 'NR==2 {print}')
DB_VERSION=$(mysql -h "$MYSQL_HOST" -u root -e "SELECT VERSION();" 2>/dev/null | awk 'NR==2 {print $1}')
DUMP_VERSION=$(mysqldump --version | awk '{print $5}')

backup_log "(${BACKUP_TYPE}) 🫙 Current Database: ${DB_TYPE} ${DB_VERSION}"
backup_log "(${BACKUP_TYPE}) 🐳 Docker Container's mysqldump version: ${DUMP_VERSION}"

backup_log "(${BACKUP_TYPE}) For backups \"mysqldump\" command works differently from MariaDB's or MySQL's version"

# @link https://dev.mysql.com/doc/refman/8.4/en/mysqldump.html#option_mysqldump_set-gtid-purged
if echo "$DUMP_VERSION" | grep -qi "MariaDB"; then
    backup_log "(${BACKUP_TYPE}) 🔍 Detected MariaDB's mysqldump command (Skipping option: --set-gtid-purged)"
    DUMP_OPTIONS="--add-drop-table --add-drop-database --routines --triggers --events --default-character-set=utf8mb4 --hex-blob --max-allowed-packet=1G"
else
    backup_log "(${BACKUP_TYPE}) 🔍 Detected MySQL's mysqldump command (Enabling option: --set-gtid-purged=OFF)"
    DUMP_OPTIONS="--set-gtid-purged=OFF --column-statistics=0 --add-drop-table --add-drop-database --routines --triggers --events --default-character-set=utf8mb4 --hex-blob --max-allowed-packet=1G"
fi

###################################################################
# LEMP ALL DATABASE DUMP (One .sql file for all databases)

# chmod -R 755 "/${CONTAINER_BACKUPS_PATH}"

if [ "$BACKUP_TYPE" = "ghost" ]; then
    # Setup ghost backup directory (NOT PERSISTENT - SAVED TO CONTAINER ONLY)
    FULL_DB_DUMP_PATH="${BACKUPS_CONTAINER_GHOST_BACKUPS_PATH}/${DB_HOST_NAME}"
else
    # Setup backup directory (PERSISTENT - SAVED TO LOCAL MACHINE)
    FULL_DB_DUMP_PATH="${BACKUPS_CONTAINER_BACKUPS_PATH}/${DB_HOST_NAME}"
fi

mkdir -p "$FULL_DB_DUMP_PATH"

CREATE_ALL_BACKUPS_FILE="${FULL_DB_DUMP_PATH}/${TIMESTAMP}_${DB_HOST_NAME}_create_all_db_${BACKUP_TYPE}.sql"

backup_log "(${BACKUP_TYPE}) 📦 Backing up all container databases for: ${DB_HOST_NAME}"

mysqldump -h "$MYSQL_HOST" -u root \
${DUMP_OPTIONS} --all-databases >"$CREATE_ALL_BACKUPS_FILE"

if [ -s "$CREATE_ALL_BACKUPS_FILE" ]; then
    backup_log "(${BACKUP_TYPE}) ✅ Full Backup success for: $DB_HOST_NAME"
    backup_log "(${BACKUP_TYPE}) 📦 -> $CREATE_ALL_BACKUPS_FILE"
else
    backup_log "(${BACKUP_TYPE}) ❌ Full Backup failed for: $DB_HOST_NAME"
    backup_log "(${BACKUP_TYPE}) 📦 -> $CREATE_ALL_BACKUPS_FILE"
    rm -f "$CREATE_ALL_BACKUPS_FILE"
fi

####################################################################
# DUMP EACH LEMP DATABASE (separate .sql files)

backup_log "(${BACKUP_TYPE}) ⤵️ Dumping all databases in the container..."

# Get list of databases, excluding system DBs
DATABASES=$(mysql -h "$MYSQL_HOST" -u root \
-e "SHOW DATABASES;" | awk 'NR>1 && !/^(mysql|information_schema|performance_schema|sys)$/' || true)

backup_log "(${BACKUP_TYPE}) 📂 Found databases: $DATABASES"

# Loop through databases and dump each separately
for DB in $DATABASES; do
    
    # Setup backup directory
    if [ "$BACKUP_TYPE" = "ghost" ]; then
        # Setup ghost backup directory (NOT PERSISTENT - SAVED TO CONTAINER ONLY)
        DB_DUMP_PATH="${BACKUPS_CONTAINER_GHOST_BACKUPS_PATH}/${DB}"
    else
        # Setup backup directory (PERSISTENT - SAVED TO LOCAL MACHINE)
        DB_DUMP_PATH="${BACKUPS_CONTAINER_BACKUPS_PATH}/${DB}"
    fi
    
    mkdir -p "$DB_DUMP_PATH"
    
    DB_BACKUPS_FILE="${DB_DUMP_PATH}/${TIMESTAMP}_${DB}_create_db_${BACKUP_TYPE}.sql"
    
    mysqldump -h "$MYSQL_HOST" -u root \
    ${DUMP_OPTIONS} --databases "$DB" >"$DB_BACKUPS_FILE"
    
    # Check if the backup was successful
    if [ -s "$DB_BACKUPS_FILE" ]; then
        backup_log "(${BACKUP_TYPE}) ✅ Backup success for: $DB"
        backup_log "(${BACKUP_TYPE}) 📦 -> $DB_BACKUPS_FILE"
    else
        backup_log "(${BACKUP_TYPE}) ❌ Backup failed for: $DB"
        backup_log "(${BACKUP_TYPE}) 📦 -> $DB_BACKUPS_FILE"
        rm -f "$DB_BACKUPS_FILE"
    fi
done

backup_log "(${BACKUP_TYPE}) 🎉 All databases have been backed up individually."

####################################################################
# RUN CLEANUP SCRIPT (Cleans up mounted "/backups" directory)

CLEANUP_SCRIPT_FILE="/${BACKUPS_CONTAINER_NAME}/scripts/$BACKUPS_CLEANUP_SCRIPT_FILE"
# Cleanup old backups if script exists
if [ -f "${CLEANUP_SCRIPT_FILE}" ]; then
    sh "${CLEANUP_SCRIPT_FILE}"
else
    backup_log "(${BACKUP_TYPE}:cleanup) 🧼 No cleanup script found: $CLEANUP_SCRIPT_FILE"
fi
