#!/bin/sh
# Cleanup SQL backups per container directory using file birth/creation time (fallback to mtime)
# POSIX sh (Debian bookworm). No filename-date parsing.

# --- Load env ---------------------------------------------------------------
set -a
. /etc/environment
. "/${BACKUPS_CONTAINER_NAME}/.env"
. "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a

# --- Defaults ---------------------------------------------------------------
: "${BACKUPS_CONTAINER_BACKUPS_PATH:=/latest-backups/backups}"
BACKUPS_ROOT="$BACKUPS_CONTAINER_BACKUPS_PATH"
DRY_RUN="${BACKUPS_DRY_RUN:-0}"

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

day_key() { date -u -d "@$1" +%Y-%m-%d; }
month_key() { date -u -d "@$1" +%Y-%m; }

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

rm_safe() {
    if [ "$DRY_RUN" = "1" ]; then
        backup_log "DRY-RUN 🧪 would delete: $1"
    else
        rm -f -- "$1"
    fi
}

# --- Start ------------------------------------------------------------------
backup_log "(cleanup) 🧼 Scanning -> $BACKUPS_ROOT (per container subfolder)"

# Walk each container directory one-by-one
for CONTAINER_DIR in "$BACKUPS_ROOT"/*; do
    [ -d "$CONTAINER_DIR" ] || continue
    CONTAINER_NAME=$(basename "$CONTAINER_DIR")
    backup_log "🔎 Container: $CONTAINER_NAME"
    
    KEPT_DAYS=0
    KEPT_MONTHS=0
    DELETED=0
    STAGED=0
    SKIPPED_TODAY=0
    [ "$DRY_RUN" = "1" ] && backup_log "DRY-RUN 🧪 No files will be deleted."
    
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
    for KFILE in "$TMPDIR"/day_* "$TMPDIR"/month_*; do
        [ -f "$KFILE" ] || continue
        KEY="$(basename "$KFILE")"
        GROUP="${KEY#*_}"
        KEEP_PATH="$(cut -d'|' -f2 "$KFILE")"
        case "$KEY" in
            day_*)   KEPT_DAYS=$((KEPT_DAYS + 1));   backup_cleanup_file_log "✅ Keeping latest backup for $GROUP (per-day): $KEEP_PATH" ;;
            month_*) KEPT_MONTHS=$((KEPT_MONTHS + 1)); backup_cleanup_file_log "✅ Keeping latest backup for $GROUP (per-month): $KEEP_PATH" ;;
            *)       backup_cleanup_file_log "✅ Keeping latest backup for $GROUP: $KEEP_PATH" ;;
        esac
    done
    
    case "${BACKUPS_CLEANUP_ACTION:-}" in
        one)
            # Delete everything in scope except the chosen keepers.
            find "$CONTAINER_DIR" -type f -name "*.sql" -print | \
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                
                if [ "$AGE" -lt "$DAY_SECS" ]; then
                    continue
                fi
                
                if [ "$AGE" -lt "$DAYS30_SECS" ]; then
                    KEY="day_$(day_key "$EPOCH")"
                else
                    KEY="month_$(month_key "$EPOCH")"
                fi
                
                KEEP="$(keep_map_get_path "$TMPDIR" "$KEY")"
                if [ -n "$KEEP" ] && [ "$FILE" != "$KEEP" ]; then
                    if [ "$AGE" -lt "$DAYS30_SECS" ]; then
                        backup_cleanup_file_log "🗑️ Deleting (per-day set) -> $FILE"
                    else
                        backup_cleanup_file_log "🗑️ Deleting (per-month set) -> $FILE"
                    fi
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
                    backup_cleanup_file_log "📦 Staging monthly keeper -> $KEEP_PATH"
                    mv -f -- "$KEEP_PATH" "$STAGE"/ 2>/dev/null || true
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
                    backup_cleanup_file_log "🗑️ Deleting (>30d) -> $FILE"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
            
            # Move back and remove stage
            mv "$STAGE"/*.sql "$CONTAINER_DIR"/ 2>/dev/null || true
            rmdir "$STAGE" 2>/dev/null || true
        ;;
        *)
            backup_log "❌ Invalid or empty BACKUPS_CLEANUP_ACTION: ${BACKUPS_CLEANUP_ACTION:-<unset>}"
            rm -rf "$TMPDIR"
            exit 1
        ;;
    esac
    
    backup_log "📈 Summary for $CONTAINER_NAME: kept-per-day=$KEPT_DAYS, kept-per-month=$KEPT_MONTHS, deleted=$DELETED, skipped-today=$SKIPPED_TODAY, staged=$STAGED"
    rm -rf "$TMPDIR"
done

backup_log "🎉 [$(date)] Backup cleanup completed successfully!"
