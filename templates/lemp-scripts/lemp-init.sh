#!/bin/sh
# Ensure environment variables are loaded
set -a # Auto-export all variables
[ -f /etc/environment ] && . /etc/environment
[ -f "/${BACKUPS_CONTAINER_NAME}/.env" ] && . "/${BACKUPS_CONTAINER_NAME}/.env"
[ -f "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh" ] && . "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a # Disable auto-export

# Make sure logs can write before first backup_log
mkdir -p "${LOG_CONTAINER_PATH}"

echo "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"

# Time
TIMESTAMP=$(get_timestamp)
LOCAL_TIME=$(get_local_time)
TODAY_DIR=$(get_today_dir)

# Ensure runtime tools exist (cron, envsubst, flock, ps) — quiet install if missing
ensure_runtime_tools() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update >/dev/null 2>&1 || true
    apt-get install -y cron gettext-base util-linux procps >/dev/null 2>&1 || true
}
# Start cron in a way that works on slim images
start_cron_daemon() {
    # kill any previous instance and stale pid files
    pkill -x cron 2>/dev/null || true
    pkill -x crond 2>/dev/null || true
    rm -f /var/run/cron.pid /var/run/crond.pid 2>/dev/null || true

    if [ -x /usr/sbin/cron ]; then
        # Use verbose logging so cron emits parse/schedule diagnostics to container logs
        /usr/sbin/cron -f -L 15 &    # Debian cron, foreground (we background it)
    elif command -v crond >/dev/null 2>&1; then
        crond -f &                   # BusyBox fallback
    else
        backup_log "❌ No cron binary found (neither /usr/sbin/cron nor crond)."
    fi
}

BACKUPS_CONTAINER_NAME_UC="$(uc_word "$BACKUPS_CONTAINER_NAME")"
backup_heading "$BACKUPS_CONTAINER_NAME_UC INIT"
backup_log "📄 Running $(basename "$0") >>>"

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
    ensure_runtime_tools
    backup_log "✨ Starting cron setup"
    printf 'BACKUPS_CONTAINER_NAME=%s\n' "${BACKUPS_CONTAINER_NAME}" >> /etc/environment
    printf 'LOG_CONTAINER_PATH=%s\n' "${LOG_CONTAINER_PATH}" >> /etc/environment

    cat /etc/environment >/tmp/debug_env.log # Debugging: Check this file to Verify variables exist

    # Ensure /etc/cron.d exists and is usable
    mkdir -p /etc/cron.d
    chown root:root /etc/cron.d 2>/dev/null || true
    chmod 0755 /etc/cron.d 2>/dev/null || true

    # If directory is empty, install a minimal probe file
    if ! ls -A /etc/cron.d >/dev/null 2>&1; then
        backup_log "⚠️ /etc/cron.d is empty; installing a probe so we can see ticks."
        cat > /etc/cron.d/probe <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * root date "+%F %T cron.d OK" >> /var/log/cron_probe.log
EOF
    fi

    # Normalize all cron.d entries: strip CRLF, expand env, enforce perms
    for f in /etc/cron.d/*; do
        [ -f "$f" ] || continue
        # Skip and warn on filenames that cron ignores (contain dots or end with ~)
        base_name=$(basename "$f")
        case "$base_name" in
            *.*|*~)
                backup_log "⚠️ Ignoring /etc/cron.d/$base_name (cron ignores names with dots or trailing ~)"
                continue
            ;;
        esac
        tmp="${f}.tmp"
        # Remove CRLF; expand env if envsubst is present
        if command -v envsubst >/dev/null 2>&1; then
            tr -d '\r' < "$f" | envsubst > "$tmp"
        else
            tr -d '\r' < "$f" > "$tmp"
        fi
        # Replace file in-place (requires the mount to be writable)
        cat "$tmp" > "$f"
        rm -f "$tmp"
        # Ensure file ends with a newline
        last_char=$(tail -c 1 "$f" 2>/dev/null || echo '')
        [ "$last_char" = "" ] || printf '\n' >> "$f"
        chmod 0644 "$f" 2>/dev/null || true
        chown root:root "$f" 2>/dev/null || true
    done

    # Debian/cron requires correct permissions on cron directories
    if [ -d /var/spool/cron/crontabs ]; then
        chown root:crontab /var/spool/cron/crontabs 2>/dev/null || true
        chmod 1730 /var/spool/cron/crontabs 2>/dev/null || true
    fi

    # Show effective cron.d entries and grep for common mistakes (missing user field)
    backup_log "🔎 Validating cron.d entries for common issues..."
    for f in /etc/cron.d/*; do
        [ -f "$f" ] || continue
        base_name=$(basename "$f")
        # Skip ignored names again
        case "$base_name" in *.*|*~) continue;; esac
        if ! awk 'BEGIN{ok=0} /^[[:space:]]*($|#)/{next} {if (NF>=7) ok=1} END{exit ok?0:1}' "$f"; then
            backup_log "❌ $f may be missing the USER field (e.g., 'root') or has too few fields"
            backup_log "   Example of correct format: '*/5 * * * * root <command>'"
        fi
    done

    # Ensure probe log exists so appends never fail
    : > /var/log/cron_probe.log 2>/dev/null || true

    backup_log "📝 Loaded /etc/cron.d entries:"
    ls -l /etc/cron.d | sed -n '1,200p'

    # Restart cron to apply changes
    backup_log "🔃 Restarting cron to apply new jobs..."
    start_cron_daemon

    backup_log "Mounted Template you can edit: ${BACKUPS_CRONTAB_FILE}"

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
sh "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh" initial &
wait $!

# Shutdown handler function
shutdown_handler() {
    backup_log "⚠️ Stopping container, running shutdown backup..."
    sh "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-backup.sh" "shutdown"
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
