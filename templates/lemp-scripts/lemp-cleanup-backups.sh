#!/bin/sh
# Cleanup SQL backups per container directory using file birth/creation time (fallback to mtime)
# POSIX sh (Debian bookworm). No filename-date parsing.

# --- Load env ---------------------------------------------------------------
set -a
[ -f /etc/environment ] && . /etc/environment
[ -f "/${BACKUPS_CONTAINER_NAME}/.env" ] && . "/${BACKUPS_CONTAINER_NAME}/.env"
[ -f "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh" ] && . "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
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

# Normalize DRY_RUN to accept 1/yes/true/on ----------------------------------
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

# Additional time-group keys for advanced policies
hour_key() { date -u -d "@${1}" +%Y-%m-%dT%H; }
# Week key anchored on Sunday (use the Sunday's date as the group label)
week_key_sun() {
    # %w => day of week, 0=Sunday..6=Saturday; subtract that many days to get Sunday
    dow=$(date -u -d "@${1}" +%w)
    date -u -d "@${1} -${dow} days" +%Y-%m-%d
}
year_key() { date -u -d "@${1}" +%Y; }

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
            backup_log "(cleanup) DRY-RUN 🧪 would move to OS Trash -> $(basename "$1")"
        else
            backup_log "(cleanup) DRY-RUN 🧪 would delete -> $(basename "$1")"
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
            backup_log "(cleanup) 📂 [$GROUP] -> $(basename "$KEEP_PATH")"
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
            backup_log "(cleanup) 📂 [$GROUP] -> $(basename "$KEEP_PATH")"
        done
    fi
    
    case "${BACKUPS_CLEANUP_ACTION:-}" in
        gfs)
            # Grandfather-Father-Son retention
            # Keep: 48 hourly, 14 daily, 8 weekly (Sunday), 12 monthly, 3 yearly
            HOURS48_SECS=$((48*3600))
            DAYS14_SECS=$((14*DAY_SECS))
            WEEKS8_SECS=$((8*7*DAY_SECS))
            MONTHS12_SECS=$((365*24*3600/12*12)) # approx window guard; actual monthly grouping via keys
            YEARS3_SECS=$((3*365*DAY_SECS))
            
            # Build keep map with prefixes h_, d_, w_, m_, y_
            find "$CONTAINER_DIR" -type f -name "*.sql" -print |
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                
                # Skip today's files during keeper computation; they are auto-skipped from deletion later
                [ "$AGE" -lt "$DAY_SECS" ] && continue
                
                # Hourly (last 48h): newest per hour
                if [ "$AGE" -le "$HOURS48_SECS" ]; then
                    K="h_$(hour_key "$EPOCH")"
                    keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                fi
                # Daily (last 14d): newest per day
                if [ "$AGE" -le "$DAYS14_SECS" ]; then
                    K="d_$(day_key "$EPOCH")"
                    keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                fi
                # Weekly (last 8w): newest per Sunday
                if [ "$AGE" -le "$WEEKS8_SECS" ]; then
                    K="w_$(week_key_sun "$EPOCH")"
                    keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                fi
                # Monthly (last 12m): newest per month
                # We don't compute exact months by age; the month_key provides grouping
                K="m_$(month_key "$EPOCH")"
                keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                # Yearly (last 3y): newest per year
                K="y_$(year_key "$EPOCH")"
                keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
            done
            
            # Logs for each retention tier
            set -- "$TMPDIR"/h_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) ⏱ Keeping Latest per-hour (48h window)"
                for KFILE in "$TMPDIR"/h_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) ⏱ [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            set -- "$TMPDIR"/d_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 📅 Keeping Latest per-day (14d window)"
                for KFILE in "$TMPDIR"/d_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 📅 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            set -- "$TMPDIR"/w_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 🗓 Keeping Latest per-week (Sunday anchor, 8w window)"
                for KFILE in "$TMPDIR"/w_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 🗓 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            set -- "$TMPDIR"/m_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 🗃 Keeping Latest per-month (12m window)"
                for KFILE in "$TMPDIR"/m_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 🗃 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            set -- "$TMPDIR"/y_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 🗂 Keeping Latest per-year (3y window)"
                for KFILE in "$TMPDIR"/y_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 🗂 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            
            # Delete anything not in keep-set (excluding today's files)
            find "$CONTAINER_DIR" -type f -name "*.sql" -print |
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                [ "$AGE" -lt "$DAY_SECS" ] && continue
                
                KEEPED=0
                HK="h_$(hour_key "$EPOCH")"; DK="d_$(day_key "$EPOCH")"; WK="w_$(week_key_sun "$EPOCH")"; MK="m_$(month_key "$EPOCH")"; YK="y_$(year_key "$EPOCH")"
                for KK in "$HK" "$DK" "$WK" "$MK" "$YK"; do
                    KPATH="$(keep_map_get_path "$TMPDIR" "$KK")"
                    if [ -n "$KPATH" ] && [ "$FILE" = "$KPATH" ]; then KEEPED=1; break; fi
                done
                if [ "$KEEPED" -eq 0 ]; then
                    backup_log "(cleanup) 🗑️ Deleting -> $(basename "$FILE")"
                    backup_cleanup_log "$(basename "$FILE")"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
        ;;
        rwma)
            # Rolling Window + Monthly Anchors
            # Keep: all <7d; 1/day for days 8–30; 1/week for weeks 5–12; 1/month for months 4–24
            DAYS7_SECS=$((7*DAY_SECS))
            DAYS30_SECS_LOCAL=$((30*DAY_SECS))
            WEEKS12_SECS=$((12*7*DAY_SECS))
            MONTHS24_SECS=$((24*30*DAY_SECS)) # approx 24 months window
            
            # Build keep map with prefixes d_, w_, m_
            find "$CONTAINER_DIR" -type f -name "*.sql" -print |
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                
                # Keep all <7d by skipping from map (we'll skip deletion later)
                [ "$AGE" -lt "$DAYS7_SECS" ] && continue
                
                if [ "$AGE" -ge "$DAYS7_SECS" ] && [ "$AGE" -le "$DAYS30_SECS_LOCAL" ]; then
                    # Days 8–30 → newest per day
                    K="d_$(day_key "$EPOCH")"
                    keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                    elif [ "$AGE" -gt "$DAYS30_SECS_LOCAL" ] && [ "$AGE" -le "$WEEKS12_SECS" ]; then
                    # Weeks 5–12 → newest per Sunday
                    K="w_$(week_key_sun "$EPOCH")"
                    keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                    elif [ "$AGE" -gt "$WEEKS12_SECS" ] && [ "$AGE" -le "$MONTHS24_SECS" ]; then
                    # Months 4–24 → newest per month
                    K="m_$(month_key "$EPOCH")"
                    keep_map_maybe_update "$TMPDIR" "$K" "$EPOCH" "$FILE"
                fi
            done
            
            # Logs
            set -- "$TMPDIR"/d_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 📅 Keeping Latest per-day (days 8–30)"
                for KFILE in "$TMPDIR"/d_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 📅 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            set -- "$TMPDIR"/w_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 🗓 Keeping Latest per-week (weeks 5–12)"
                for KFILE in "$TMPDIR"/w_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 🗓 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            set -- "$TMPDIR"/m_*
            if [ -e "$1" ]; then
                backup_log "(cleanup) 🗃 Keeping Latest per-month (months 4–24)"
                for KFILE in "$TMPDIR"/m_*; do [ -f "$KFILE" ] || continue; KP="$(cut -d'|' -f2 "$KFILE")"; backup_log "(cleanup) 🗃 [$(basename "$KFILE")] -> $(basename "$KP")"; done
            fi
            
            # Deletions: keep all files <7d and today's; delete anything not in keep-set
            find "$CONTAINER_DIR" -type f -name "*.sql" -print |
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                [ "$AGE" -lt "$DAY_SECS" ] && continue   # today always safe
                [ "$AGE" -lt "$DAYS7_SECS" ] && continue  # keep all <7d
                
                KEEPED=0
                DK="d_$(day_key "$EPOCH")"; WK="w_$(week_key_sun "$EPOCH")"; MK="m_$(month_key "$EPOCH")"
                for KK in "$DK" "$WK" "$MK"; do
                    KPATH="$(keep_map_get_path "$TMPDIR" "$KK")"
                    if [ -n "$KPATH" ] && [ "$FILE" = "$KPATH" ]; then KEEPED=1; break; fi
                done
                if [ "$KEEPED" -eq 0 ]; then
                    backup_log "(cleanup) 🗑️ Deleting -> $(basename "$FILE")"
                    backup_cleanup_log "$(basename "$FILE")"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
        ;;
        one)
            # Delete everything in scope except the chosen keepers.
            # Pass 1: per-day deletions (<30d)
            printed_day=0
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
                    if [ "$printed_day" -eq 0 ]; then
                        backup_log "(cleanup) 🗑️ Deleting Non-Latest per-day"
                        printed_day=1
                    fi
                    backup_log "(cleanup) 🗑️ Deleting -> $(basename "$FILE")"
                    backup_cleanup_log "$(basename "$FILE")"
                    rm_safe "$FILE"
                    DELETED=$((DELETED + 1))
                fi
            done
            # Pass 2: per-month deletions (>=30d)
            printed_month=0
            find "$CONTAINER_DIR" -type f -name "*.sql" -print | \
            while IFS= read -r FILE; do
                EPOCH="$(file_epoch "$FILE")" || continue
                [ -n "$EPOCH" ] || continue
                AGE=$((NOW_EPOCH - EPOCH))
                [ "$AGE" -lt "$DAYS30_SECS" ] && continue  # only per-month set here
                KEY="month_$(month_key "$EPOCH")"
                KEEP="$(keep_map_get_path "$TMPDIR" "$KEY")"
                if [ -n "$KEEP" ] && [ "$FILE" != "$KEEP" ]; then
                    if [ "$printed_month" -eq 0 ]; then
                        backup_log "(cleanup) 🗑️ Deleting Non-Latest per-month"
                        printed_month=1
                    fi
                    backup_log "(cleanup) 🗑️ Deleting -> $(basename "$FILE")"
                    backup_cleanup_log "$(basename "$FILE")"
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
                    backup_log "(cleanup) 📦 Staging monthly keeper -> $(basename "$KEEP_PATH")"
                    if is_dry_run; then
                        backup_log "(cleanup) DRY-RUN 🧪 would stage -> $(basename "$KEEP_PATH")"
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
                    backup_log "(cleanup) 🗑️ Deleting (>30d) -> $(basename "$FILE")"
                    backup_cleanup_log "$(basename "$FILE")"
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
    
    backup_log "(cleanup) 📈 Summary for $CONTAINER_NAME: kept-per-day=$KEPT_DAYS, kept-per-month=$KEPT_MONTHS, deleted=$DELETED, skipped-today=$SKIPPED_TODAY, staged=$STAGED"
    rm -rf "$TMPDIR"
done

backup_section_end "(cleanup) 🎉 [$(date)] Backup cleanup completed successfully!"
