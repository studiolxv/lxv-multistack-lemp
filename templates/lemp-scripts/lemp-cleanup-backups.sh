#!/bin/sh
# Cleanup SQL backups per container directory using file birth/creation time (fallback to mtime)
# POSIX sh (Debian bookworm). No filename-date parsing.

# --- Load env ---------------------------------------------------------------
set -a
. /etc/environment
. "/${BACKUPS_CONTAINER_NAME}/.env"
. "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a

backup_heading "🧼 CLEANUP SQL BACKUPS"
backup_log "📄 Running ${BACKUPS_CLEANUP_ACTION} $(basename "$0") >>>"

# --- Quick Bail ---------------------------------------------------------------
if [ ! -n "${BACKUPS_CLEANUP_ACTION}" ] || [ "${BACKUPS_CLEANUP_ACTION}" = "none" ]; then
    backup_log "❌ No SQL cleanup action specified, exiting."
    exit 0
fi

# --- Defaults -------------------------------------`--------------------------
: "${BACKUPS_USE_OS_TRASH:=1}"
BACKUPS_ROOT="$BACKUPS_CONTAINER_BACKUPS_PATH"
DRY_RUN="${BACKUPS_CLEANUP_DRY_RUN:-0}"

# Normalize DRY_RUN to accept 1/yes/true/on
is_dry_run() {
    case "$(printf '%s' "$DRY_RUN" | tr '[:upper:]' '[:lower:]')" in
        1|yes|true|on) return 0 ;;
        *) return 1 ;;
    esac
}


dry_run_status() { is_dry_run && printf 'ON' || printf 'OFF'; }

# --- Time helpers -----------------------------------------------------------
NOW_EPOCH=$(date +%s)
DAY_SECS=86400
DAYS30_SECS=$((30*DAY_SECS))

# Prefer file birth time (creation) if available; otherwise use mtime.
file_epoch() {
    # GNU stat: %W = birth (−1 if unknown), %Y = mtime
    b="$(stat -c %W -- "$1" 2>/dev/null || echo -1)"
    if [ -n "$b" ] && [ "$b" -gt 0 ] 2>/dev/null; then
        printf '%s\n' "$b"
    else
        stat -c %Y -- "$1" 2>/dev/null
    fi
}

day_key() { date -u -d "@${1}" +%Y-%m-%d; }
month_key() { date -u -d "@${1}" +%Y-%m; }

# Keep-map helpers using temp files (works in POSIX sh)
# map file content: "epoch|path"
keep_map_get_path() { # $1 mapdir, $2 key
    f="$1/$2"
    if [ -f "$f" ]; then cut -d'|' -f2 -- "$f"; else printf '\n'; fi
}
keep_map_maybe_update() { # $1 mapdir, $2 key, $3 epoch, $4 path
    f="$1/$2"
    old=0
    if [ -f "$f" ]; then old="$(cut -d'|' -f1 -- "$f" 2>/dev/null || echo 0)"; fi
    if [ "$3" -gt "$old" ] 2>/dev/null; then
        printf '%s|%s\n' "$3" "$4" > "$f"
    fi
}

# --- OS Trash detection ---------------------------------------------------
TRASH_CMD=""
detect_os_trash() {
    if command -v trash >/dev/null 2>&1; then
        TRASH_CMD="trash"; return 0
    fi
    if command -v trash-put >/dev/null 2>&1; then
        TRASH_CMD="trash-put"; return 0
    fi
    if command -v gio >/dev/null 2>&1; then
        TRASH_CMD="gio"; return 0
    fi
    if command -v gvfs-trash >/dev/null 2>&1; then
        TRASH_CMD="gvfs-trash"; return 0
    fi
    if command -v kioclient5 >/dev/null 2>&1; then
        TRASH_CMD="kioclient5"; return 0
    fi
    # Windows (Git Bash/WSL/Cygwin) — use PowerShell recycle bin if available
    if command -v powershell.exe >/dev/null 2>&1; then
        TRASH_CMD="powershell"; return 0
    fi
    return 1
}

os_trash() { # $1 = path
    case "$TRASH_CMD" in
        trash)
        trash -- "$1" ;;
        trash-put)
        trash-put -- "$1" ;;
        gio)
        gio trash "$1" ;;
        gvfs-trash)
        gvfs-trash "$1" ;;
        kioclient5)
        kioclient5 moveToTrash "$1" ;;
        powershell)
            # Attempt to send to Recycle Bin via PowerShell .NET API
            powershell.exe -NoProfile -Command "\
            try { \
              Add-Type -AssemblyName Microsoft.VisualBasic; \
              $p = [System.IO.Path]::GetFullPath(\"$1\"); \
              [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($p,'OnlyErrorDialogs','SendToRecycleBin'); \
        } catch { exit 1 }" ;;
        *)
        return 1 ;;
    esac
}

detect_os_trash || true

rm_safe() {
    if is_dry_run; then
        if [ "$BACKUPS_USE_OS_TRASH" = "1" ] && [ -n "$TRASH_CMD" ]; then
            backup_cleanup_file_log "(cleanup) DRY-RUN 🧪 would move to OS Trash -> $(basename "$1")"
        else
            backup_cleanup_file_log "(cleanup) DRY-RUN 🧪 would delete -> $(basename "$1")"
        fi
        return 0
    fi
    if [ "$BACKUPS_USE_OS_TRASH" = "1" ] && [ -n "$TRASH_CMD" ]; then
        os_trash "$1" 2>/dev/null || rm -f -- "$1"
    else
        rm -f -- "$1"
    fi
}

if is_dry_run; then
    backup_heading "CLEANUP DRY-RUN"
    backup_log "(cleanup) No files will be deleted (effective DRY_RUN=$(dry_run_status))"
else
    backup_heading "CLEANUP ACTIVE"
    backup_log "(cleanup) Files will be permanently deleted (effective DRY_RUN=$(dry_run_status))"
fi

if [ "$BACKUPS_USE_OS_TRASH" = "1" ]; then
    if [ -n "$TRASH_CMD" ]; then
        backup_log "(cleanup) 🧺 OS Trash: ON via $TRASH_CMD"
    else
        backup_log "(cleanup) ⚠️ OS Trash requested but unavailable — falling back to permanent delete"
        backup_log "(cleanup)    Tip: macOS → 'brew install trash' | Linux → 'gio trash' or 'trash-cli' | Windows → PowerShell available via Git Bash/WSL"
    fi
else
    backup_log "(cleanup) 🧺 OS Trash: OFF (permanent delete)"
fi
# --- Start ------------------------------------------------------------------
# Walk each container directory one-by-one
for CONTAINER_DIR in "$BACKUPS_ROOT"/*; do
    [ -d "$CONTAINER_DIR" ] || continue
    CONTAINER_NAME=$(basename "$CONTAINER_DIR")
    CONTAINER_NAME_UPPER=$(echo "$CONTAINER_NAME" | tr '[:lower:]' '[:upper:]')
    backup_heading "(cleanup) $CONTAINER_NAME_UPPER BACKUP SQL"
    
    KEPT_DAYS=0
    KEPT_MONTHS=0
    DELETED=0
    STAGED=0
    SKIPPED_TODAY=0
    
    
    TMPDIR="$(mktemp -d)"
    # First pass: compute keepers (per-day within last 30d, per-month for >30d)
    find "$CONTAINER_DIR" -type f -name "*.sql" -print | \
    while IFS= read -r FILE; do
        EPOCH="$(file_epoch "$FILE")" || continue
        [ -n "$EPOCH" ] || continue
        AGE=$((NOW_EPOCH - EPOCH))
        
        # Skip today's files to avoid fighting with in-progress backups
        if [ "$AGE" -lt "$DAY_SECS" ]; then
            SKIPPED_TODAY=$((SKIPPED_TODAY + 1))
            continue
        fi
        
        if [ "$AGE" -lt "$DAYS30_SECS" ]; then
            K="day_$(day_key "$EPOCH")"
            keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
        else
            K="month_$(month_key "$EPOCH")"
            keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
        fi
    done
    
    # Log keep decisions
    # Print a single heading and then list per-day keepers
    set -- "$TMPDIR"/day_*
    if [ -e "$1" ]; then
        backup_log "(cleanup) 📂 Keeping Latest per-day"
        backup_log ""
        for KFILE in "$TMPDIR"/day_*; do
            [ -f "$KFILE" ] || continue
            KEY="$(basename "$KFILE")"
            GROUP="${KEY#*_}"
            KEEP_PATH="$(cut -d'|' -f2 "$KFILE")"
            KEPT_DAYS=$((KEPT_DAYS + 1))
            backup_cleanup_file_log "(cleanup) 📂 [$GROUP] -> $(basename "$KEEP_PATH")"
        done
    fi
    # Print a single heading and then list per-month keepers
    set -- "$TMPDIR"/month_*
    if [ -e "$1" ]; then
        backup_log "(cleanup) 📂 Keeping Latest per-month"
        for KFILE in "$TMPDIR"/month_*; do
            [ -f "$KFILE" ] || continue
            KEY="$(basename "$KFILE")"
            GROUP="${KEY#*_}"
            KEEP_PATH="$(cut -d'|' -f2 "$KFILE")"
            KEPT_MONTHS=$((KEPT_MONTHS + 1))
            backup_cleanup_file_log "(cleanup) 📂 [$GROUP] -> $(basename "$KEEP_PATH")"
        done
    fi
    
    case "${BACKUPS_CLEANUP_ACTION:-}" in
        one)
            # Delete everything in scope except the chosen keepers.
            # Pass 1: per-day deletions (<30d)
            backup_log "(cleanup) 🗑️ Deleting Non-Latest per-day"
            find "$CONTAINER_DIR" -type f -name "*.sql" -print | \
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                [ "$AGE" -lt "$DAY_SECS" ] && continue  # skip today's files
                [ "$AGE" -ge "$DAYS30_SECS" ] && continue  # only per-day set here
                KEY="day_$(day_key "$EPOCH")"
                KEEP="$(keep_map_get_path "$TMPDIR" "$KEY")"
                if [ -n "$KEEP" ] && [ "$FILE" != "$KEEP" ]; then
                    backup_cleanup_file_log "(cleanup) 🗑️ Deleting -> $(basename "$FILE")"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
            # Pass 2: per-month deletions (>=30d)
            backup_log "(cleanup) 🗑️ Deleting Non-Latest per-month"
            find "$CONTAINER_DIR" -type f -name "*.sql" -print | \
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                [ "$AGE" -lt "$DAYS30_SECS" ] && continue  # only per-month set here
                KEY="month_$(month_key "$EPOCH")"
                KEEP="$(keep_map_get_path "$TMPDIR" "$KEY")"
                if [ -n "$KEEP" ] && [ "$FILE" != "$KEEP" ]; then
                    backup_cleanup_file_log "(cleanup) 🗑️ Deleting -> $(basename "$FILE")"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
        ;;
        two)
            # Stage latest-per-month (>30d) then delete the rest >30d, then move staged back.
            STAGE="$CONTAINER_DIR/monthly-temp"
            mkdir -p "$STAGE"
            
            # Move keepers for months
            for KFILE in "$TMPDIR"/month_*; do
                [ -f "$KFILE" ] || continue
                KEEP_PATH="$(cut -d'|' -f2 "$KFILE")"
                if [ -n "$KEEP_PATH" ] && [ -f "$KEEP_PATH" ]; then
                    backup_cleanup_file_log "(cleanup) 📦 Staging monthly keeper -> $(basename "$KEEP_PATH")"
                    if is_dry_run; then
                        backup_cleanup_file_log "(cleanup) DRY-RUN 🧪 would stage -> $(basename "$KEEP_PATH")"
                    else
                        mv -f -- "$KEEP_PATH" "$STAGE"/ 2>/dev/null || true
                    fi
                    STAGED=$((STAGED + 1))
                fi
            done
            
            # Delete all >30d that are NOT in stage
            find "$CONTAINER_DIR" -type f -name "*.sql" -print | \
            while IFS= read -r FILE; do
                case "$FILE" in
                    "$STAGE"/*) continue ;;
                esac
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                if [ "$AGE" -ge "$DAYS30_SECS" ]; then
                    backup_cleanup_file_log "(cleanup) 🗑️ Deleting (>30d) -> $(basename "$FILE")"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
            
            if is_dry_run; then
                backup_log "(cleanup) DRY-RUN 🧪 would move staged keepers back"
            else
                mv "$STAGE"/*.sql "$CONTAINER_DIR"/ 2>/dev/null || true
            fi
            if is_dry_run; then
                backup_log "(cleanup) DRY-RUN 🧪 would remove stage directory"
            else
                rmdir "$STAGE" 2>/dev/null || true
            fi
        ;;
        *)
            backup_log "(cleanup) ❌ Invalid or empty BACKUPS_CLEANUP_ACTION: ${BACKUPS_CLEANUP_ACTION:-<unset>}"
            rm -rf "$TMPDIR"
            exit 1
        ;;
    esac
    
    backup_cleanup_file_log "(cleanup) 📈 Summary for $CONTAINER_NAME: kept-per-day=$KEPT_DAYS, kept-per-month=$KEPT_MONTHS, deleted=$DELETED, skipped-today=$SKIPPED_TODAY, staged=$STAGED"
    rm -rf "$TMPDIR"
done

backup_section_end "(cleanup) 🎉 [$(date)] Backup cleanup completed successfully!"
