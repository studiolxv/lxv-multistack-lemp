#!/bin/sh
# Ensure environment variables are loaded
set -a # Auto-export all variables
[ -f /etc/environment ] && . /etc/environment
[ -f "/${BACKUPS_CONTAINER_NAME}/.env" ] && . "/${BACKUPS_CONTAINER_NAME}/.env"
[ -f "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh" ] && . "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a # Disable auto-export

# --- Auto-discover DB hosts from current env and .env (no manual config) ----
# --- Auto-discover DB hosts from current env and .env (no manual config) ----
if [ -z "${BACKUP_MULTI_HOST_DONE:-}" ]; then
    # Collect candidates (newline-separated), strip inline comments and quotes
    ENV_HOSTS=$(
        env | awk -F= '/(_DB_HOST|MYSQL_HOST|WORDPRESS_DB_HOST|WP_DB_HOST)/ {print $2}' \
        | sed 's/#.*$//' | tr -d "\"'" | awk 'NF'
    )

    FILE_HOSTS=""
    if [ -f "/${BACKUPS_CONTAINER_NAME}/.env" ]; then
        FILE_HOSTS=$(
            awk -F= '/(_DB_HOST|MYSQL_HOST|WORDPRESS_DB_HOST|WP_DB_HOST)/ {gsub(/"|\047/,"",$2); sub(/#.*/,"",$2); gsub(/^[ \t]+|[ \t]+$/,"",$2); if(length($2)) print $2}' "/${BACKUPS_CONTAINER_NAME}/.env"
        )
    fi

    # Sanitize: keep only plausible host[:port] tokens; uniq
    HOSTS=$(
        printf '%s\n' "db" $ENV_HOSTS $FILE_HOSTS \
        | sed 's/[[:space:]]\+$//' \
        | awk 'NF && $1 !~ /^#/' \
        | grep -E '^[A-Za-z0-9._-]+(:[0-9]+)?$' \
        | sort -u
    )

    # Probe which hosts are reachable via mysql (build a newline list)
    REACHABLE=""
    OLDIFS=$IFS; IFS='
'
    for H in $HOSTS; do
        [ -z "$H" ] && continue
        case "$H" in localhost|127.0.0.1|::1) continue;; esac
        TEST_SQL_OPTS="-h \"$H\" -u root --protocol=TCP --connect-timeout=3"
        [ -n "${MYSQL_ROOT_PASSWORD:-}" ] && TEST_SQL_OPTS="$TEST_SQL_OPTS -p\"$MYSQL_ROOT_PASSWORD\""
        if eval mysql $TEST_SQL_OPTS -e "SELECT 1;" >/dev/null 2>&1; then
            REACHABLE="${REACHABLE}${REACHABLE:+
}$H"
        else
            backup_log "(${BACKUP_TYPE}) ⚠️ Skipping unreachable DB host: $H"
        fi
    done
    IFS=$OLDIFS

    COUNT=$(printf '%s\n' "$REACHABLE" | awk 'NF' | wc -l | tr -d ' ')
    if [ "${COUNT:-0}" -gt 1 ]; then
        backup_log "(${BACKUP_TYPE}) 🌐 Auto-discovered DB hosts: $(printf '%s' \"$REACHABLE\" | tr '\n' ' ')"
        IFS='
'
        for H in $REACHABLE; do
            backup_heading "📡 Auto-backup host: $H"
            BACKUP_MULTI_HOST_DONE=1 MYSQL_HOST="$H" . "$0" "$BACKUP_TYPE"
        done
        IFS="$OLDIFS"
        exit 0
    elif [ "${COUNT:-0}" -eq 1 ] && [ -z "${MYSQL_HOST:-}" ]; then
        MYSQL_HOST=$(printf '%s\n' "$REACHABLE" | awk 'NF{print; exit}')
    fi
fi

if [ -z "${MYSQL_HOST:-}" ]; then
    backup_log "(init) ⚠️ MYSQL_HOST is not set; defaulting to service name 'db' (TCP)"
    MYSQL_HOST="db"
fi
MYSQL_SQL_OPTS="-h \"$MYSQL_HOST\" -u root --protocol=TCP --connect-timeout=5"
MYSQL_DUMP_OPTS="-h \"$MYSQL_HOST\" -u root --protocol=TCP"

# If a root password is provided, add it to both client option sets
if [ -n "${MYSQL_ROOT_PASSWORD:-}" ]; then
    MYSQL_SQL_OPTS="$MYSQL_SQL_OPTS -p\"$MYSQL_ROOT_PASSWORD\""
    MYSQL_DUMP_OPTS="$MYSQL_DUMP_OPTS -p\"$MYSQL_ROOT_PASSWORD\""
fi

# Normalize container paths to absolute (avoid /root/<relative> surprises under cron)
case "$BACKUPS_CONTAINER_BACKUPS_PATH" in
    /*) : ;;
    *) BACKUPS_CONTAINER_BACKUPS_PATH="/$BACKUPS_CONTAINER_BACKUPS_PATH" ;;
esac
case "$BACKUPS_CONTAINER_GHOST_BACKUPS_PATH" in
    /*) : ;;
    *) BACKUPS_CONTAINER_GHOST_BACKUPS_PATH="/$BACKUPS_CONTAINER_GHOST_BACKUPS_PATH" ;;
esac

BACKUP_TYPE="$1"

# Time
TIMESTAMP=$(get_timestamp)
LOCAL_TIME=$(get_local_time)
TODAY_DIR=$(get_today_dir)

# Log
BACKUP_TYPE_UC="$(uc_word "$BACKUP_TYPE")"
backup_heading "⤵️ ${BACKUP_TYPE_UC} BACKUP"
backup_log "📄 Running $(basename "$0") >>>"

# Starting Message
if [ "$BACKUP_TYPE" = "initial" ]; then
    backup_log "(${BACKUP_TYPE}) 🚀 Initial database backup..."
    elif [ "$BACKUP_TYPE" = "cron" ]; then
    backup_log "(${BACKUP_TYPE}) 🕒 Running cron scheduled database backup..."
    backup_log "(${BACKUP_TYPE}) 🕒 Schedule: $BACKUPS_CRON_SCHEDULE_DESC"
    elif [ "$BACKUP_TYPE" = "shutdown" ]; then
    backup_log "(${BACKUP_TYPE}) ⚠️ Shutdown database backup..."
    elif [ "$BACKUP_TYPE" = "ghost" ]; then
    backup_log "(${BACKUP_TYPE}) ⚠️ Running (Unmounted Ghost database backup..."
    backup_log "(${BACKUP_TYPE}) ⚠️ Once the container is stopped, these backups are lost."
else
    backup_log "(${BACKUP_TYPE}) 👽 Unknown custom backup type detected"
fi

backup_log "(${BACKUP_TYPE}) 🔍 ENVIRONMENT VARIABLES CHECK"
backup_log "(${BACKUP_TYPE}) ├── \$MYSQL_HOST = $MYSQL_HOST"
backup_log "(${BACKUP_TYPE}) └── if \$MYSQL_HOST is empty, environment variables are not being set"
backup_log "(${BACKUP_TYPE}) ├── BACKUPS_CONTAINER_BACKUPS_PATH = $BACKUPS_CONTAINER_BACKUPS_PATH"
backup_log "(${BACKUP_TYPE}) └── BACKUPS_CONTAINER_GHOST_BACKUPS_PATH = $BACKUPS_CONTAINER_GHOST_BACKUPS_PATH"

if ! eval mysql $MYSQL_SQL_OPTS -e "SELECT 1;" >/dev/null 2>&1; then
    backup_log "(${BACKUP_TYPE}) ❗ MySQL connectivity check failed (host=$MYSQL_HOST, tcp). Check credentials/password and host network."
fi

# Perform DUMP ALL ${DB_HOST_NAME} database's "create" backup

# Detect if the database is MariaDB or MySQL
DB_TYPE=$(eval mysql $MYSQL_SQL_OPTS -e "SELECT @@version_comment;" 2>/dev/null | awk 'NR==2 {print}')
DB_VERSION=$(eval mysql $MYSQL_SQL_OPTS -e "SELECT VERSION();" 2>/dev/null | awk 'NR==2 {print $1}')
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

eval mysqldump $MYSQL_DUMP_OPTS \
${DUMP_OPTIONS} --all-databases >"$CREATE_ALL_BACKUPS_FILE"

if [ -s "$CREATE_ALL_BACKUPS_FILE" ]; then
    backup_log "(${BACKUP_TYPE}) ✅ Full Backup success for: $DB_HOST_NAME"
    backup_log "(${BACKUP_TYPE}) 📦 -> $CREATE_ALL_BACKUPS_FILE"
	backup_manifest "$CREATE_ALL_BACKUPS_FILE"
else
    backup_log "(${BACKUP_TYPE}) ❌ Full Backup failed for: $DB_HOST_NAME"
    backup_log "(${BACKUP_TYPE}) 📦 -> $CREATE_ALL_BACKUPS_FILE"
    rm -f "$CREATE_ALL_BACKUPS_FILE"
fi

####################################################################
# DUMP EACH LEMP DATABASE (separate .sql files)

# Get list of databases, excluding system DBs (simple & reliable)
DATABASES=$(mysql --protocol=TCP -h "$MYSQL_HOST" -u root ${MYSQL_ROOT_PASSWORD:+-p"$MYSQL_ROOT_PASSWORD"} \
  -N -s -e "SHOW DATABASES;" 2>/dev/null | awk '!/^(mysql|information_schema|performance_schema|sys)$/')

backup_log "(${BACKUP_TYPE}) 📂 Found databases: $DATABASES"

# Loop through databases and dump each separately
for DB in $DATABASES; do
    backup_log "(${BACKUP_TYPE}) ➜ Dumping DB: $DB"

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

    eval mysqldump $MYSQL_DUMP_OPTS \
    ${DUMP_OPTIONS} --databases "$DB" >"$DB_BACKUPS_FILE"

    # Check if the backup was successful
    if [ -s "$DB_BACKUPS_FILE" ]; then
        backup_log "(${BACKUP_TYPE}) ✅ Backup success for: $DB"
        backup_log "(${BACKUP_TYPE}) 📦 -> $DB_BACKUPS_FILE"
		backup_manifest "$DB_BACKUPS_FILE"
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
