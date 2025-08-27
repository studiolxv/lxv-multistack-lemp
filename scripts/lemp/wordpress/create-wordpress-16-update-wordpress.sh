#!/bin/sh
. "./_env-setup.sh"
. $WORDPRESS_ENV_FILE

# debug_file_msg "$(current_basename)"

# --- WP CLI automated setup for a fresh container/database ---
# Requires env vars to be set by your stack scripts:
#   $WORDPRESS_SERVICE_CONTAINER_NAME (the container to exec into) -> abbreviated later to $WP_CSN
#   $WORDPRESS_DB_HOST, $WORDPRESS_DB_NAME, $WORDPRESS_DB_USER, $WORDPRESS_DB_PASSWORD
#   $WP_URL, $WP_TITLE, $WP_ADMIN_USER, $WP_ADMIN_PASSWORD, $WP_ADMIN_EMAIL
#   (optional) WORDPRESS_TABLE_PREFIX (default: wp_)

: "${WORDPRESS_TABLE_PREFIX:=wp_}"  # NOTE: this only affects this script's runtime; does not alter templates

# Sanity checks (do not hard-code defaults)
[ -n "${WORDPRESS_SERVICE_CONTAINER_NAME:-}" ] || _die "WORDPRESS_SERVICE_CONTAINER_NAME is not set."
WP_CSN="${WORDPRESS_SERVICE_CONTAINER_NAME}"
[ -n "${WORDPRESS_DB_HOST:-}" ] || _die "WORDPRESS_DB_HOST is not set."
[ -n "${WORDPRESS_DB_NAME:-}" ] || _die "WORDPRESS_DB_NAME is not set."
[ -n "${WORDPRESS_DB_USER:-}" ] || _die "WORDPRESS_DB_USER is not set."
[ -n "${WORDPRESS_DB_PASSWORD:-}" ] || _die "WORDPRESS_DB_PASSWORD is not set."
[ -n "${WORDPRESS_URL:-}" ] || _die "WORDPRESS_URL is not set."
[ -n "${WORDPRESS_TITLE:-}" ] || _die "WORDPRESS_TITLE is not set."
[ -n "${WORDPRESS_ADMIN_USER:-}" ] || _die "WORDPRESS_ADMIN_USER is not set."
[ -n "${WORDPRESS_ADMIN_USER_PASSWORD:-}" ] || _die "WORDPRESS_ADMIN_USER_PASSWORD is not set."
[ -n "${WORDPRESS_ADMIN_USER_EMAIL:-}" ] || _die "WORDPRESS_ADMIN_USER_EMAIL is not set."

body_msg "🐳 Preparing WordPress in container: ${WP_CSN}"

# Ensure the WP container is running
if ! docker ps --format '{{.Names}}' | grep -Fxq "$WP_CSN"; then
  _die "WordPress container '$WP_CSN' is not running."
else
  body_msg "WordPress container '$WP_CSN' is running."
fi

DB_WAIT_SECS=${DB_WAIT_SECS:-90}
body_msg "⏳ Waiting for DB @ ${WORDPRESS_DB_HOST} (up to ${DB_WAIT_SECS}s) …"

# First, verify the hostname is resolvable from INSIDE the container
if ! docker exec "$WP_CSN" sh -lc "command -v getent >/dev/null 2>&1 && getent hosts '${WORDPRESS_DB_HOST%%:*}' >/dev/null 2>&1 || ping -c1 -W1 '${WORDPRESS_DB_HOST%%:*}' >/dev/null 2>&1"; then
  warning_msg "⚠️ Hostname '${WORDPRESS_DB_HOST}' is not resolvable/reachable from container '$WP_CSN'. Are the WP and DB services on the same Docker network?"
  docker exec "$WP_CSN" sh -lc "command -v getent >/dev/null 2>&1 && getent hosts '${WORDPRESS_DB_HOST%%:*}' || true"
  _die "Database host (${WORDPRESS_DB_HOST}) not resolvable from container ($WP_CSN)."
else
  body_msg "✅ Database host (${WORDPRESS_DB_HOST}) is resolvable from container ($WP_CSN)."
fi

# Parse optional host:port (default port 3306)
DBH="${WORDPRESS_DB_HOST}"
DBHOST="${DBH%%:*}"
DBPORT="${DBH##*:}"
[ "$DBPORT" = "$DBHOST" ] && DBPORT=3306

end=$(( $(date +%s) + DB_WAIT_SECS ))
while :; do
  # Probe from INSIDE the WP container so service names resolve; pass host/user/pass/port via env
  if docker exec \
       -e H="$DBHOST" -e U="$WORDPRESS_DB_USER" -e PW="$WORDPRESS_DB_PASSWORD" -e PT="$DBPORT" \
       "$WP_CSN" sh -lc '
        if command -v nc >/dev/null 2>&1; then
            nc -z -w2 "$H" "$PT" >/dev/null 2>&1
        elif command -v mysqladmin >/dev/null 2>&1; then
            mysqladmin --protocol=TCP --connect-timeout=2 -h "$H" -P "$PT" -u "$U" -p"$PW" ping >/dev/null 2>&1
        else
            PHPBIN=php; command -v php >/dev/null 2>&1 || PHPBIN=/usr/local/bin/php;
            "$PHPBIN" -r '\''exit(@fsockopen(getenv("H"),(int)getenv("PT"),$e,$t,2)?0:1);'\''
        fi
     '; then
    break
  fi
  [ $(date +%s) -ge $end ] && _die "Database not reachable from container ${WP_CSN}: ${WORDPRESS_DB_HOST}"
  sleep 2
done

# Small helper to run wp inside the container (non-interactive)
dock_exec_wp_cli(){ c="${1:-$WP_CSN}"; shift; docker exec "$c" sh -lc "wp $1 --allow-root"; }
dock_exec(){ c="${1:-$WP_CSN}"; shift; docker exec "$c" sh -lc "$1"; }

# Ensure wp-cli is present in the container
if ! dock_exec "$WP_CSN" 'command -v wp >/dev/null 2>&1'; then
  _die "wp-cli not found inside ${WP_CSN}. Install wp-cli in the image or sidecar."
fi

# Path inside container (official image uses /var/www/html)
WP_C_PATH="${WORDPRESS_CONTAINER_PATH:-/var/www/html}"

# Ensure WordPress core files are present at WP_C_PATH (bind mount should provide them) — wait for mounts to appear
WP_CORE_WAIT_SECS=${WP_CORE_WAIT_SECS:-60}
body_msg "⏳ Waiting for main WordPress core files at ${WP_C_PATH} (up to ${WP_CORE_WAIT_SECS}s) …"
end=$(( $(date +%s) + WP_CORE_WAIT_SECS ))
while :; do
  if \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-admin/widgets.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-content/index.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-includes/version.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-includes/wp-diff.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-activate.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/index.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-cron.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-settings.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-load.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-login.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-config-sample.php" && \
    dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-admin/includes/upgrade.php"; then
    body_msg "✅ WordPress core files detected at ${WP_C_PATH} (version.php, wp-settings.php, wp-load.php, wp-config-sample.php, upgrade.php)"
    break
  fi
  [ $(date +%s) -ge $end ] && {
    warning_msg "Core files not visible yet in container. Directory listing and mount info:";
    docker exec "$WP_CSN" sh -lc "ls -la ${WP_C_PATH} || true; echo; echo '--- /proc/mounts entries for path ---'; grep '${WP_C_PATH}' /proc/mounts || true";
    _die "WordPress core files not found at ${WP_C_PATH} after waiting ${WP_CORE_WAIT_SECS}s.";
  }
  sleep 2
done

# Generate wp-config.php if missing (skip-check so DB doesn't need to have tables yet)
if ! dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-config.php"; then
  body_msg "🧩 Creating wp-config.php"
  dock_exec_wp_cli "$WP_CSN" "config create --path='${WP_C_PATH}' \
    --dbname='${WORDPRESS_DB_NAME}' \
    --dbuser='${WORDPRESS_DB_USER}' \
    --dbpass='${WORDPRESS_DB_PASSWORD}' \
    --dbhost='${WORDPRESS_DB_HOST}' \
    --dbprefix='${WORDPRESS_TABLE_PREFIX}' \
    --skip-check"
  # Harden salts
  dock_exec_wp_cli "$WP_CSN" "config shuffle-salts --path='${WP_C_PATH}'"
  # Verify wp-config was created successfully
  if ! dock_exec "$WP_CSN" "test -f ${WP_C_PATH}/wp-config.php"; then
    _die "wp-config.php was not created at ${WP_C_PATH}."
  fi
fi

# Install core if not installed
if ! dock_exec_wp_cli "$WP_CSN" "core is-installed --path='${WP_C_PATH}'" >/dev/null 2>&1; then
  body_msg "📦 Installing WordPress core with your LXV Multistack LEMP user configurations"
  dock_exec_wp_cli "$WP_CSN" "core install --path='${WP_C_PATH}' \
    --url='${WORDPRESS_URL}' \
    --title='${WORDPRESS_TITLE}' \
    --admin_user='${WORDPRESS_ADMIN_USER}' \
    --admin_password='${WORDPRESS_ADMIN_USER_PASSWORD}' \
    --admin_email='${WORDPRESS_ADMIN_USER_EMAIL}' \
    --skip-email"
  # Nice defaults
  dock_exec_wp_cli "$WP_CSN" "rewrite structure '/%postname%/' --hard --path='${WP_C_PATH}'"
  dock_exec_wp_cli "$WP_CSN" "option update blogdescription '' --path='${WP_C_PATH}'"
  # Verify install created tables
  if ! dock_exec_wp_cli "$WP_CSN" "core is-installed --path='${WP_C_PATH}'" >/dev/null 2>&1; then
    _die "WordPress core install did not complete; database tables not detected."
  fi
else
  body_msg "✅ WordPress already installed; updating core settings"
  dock_exec_wp_cli "$WP_CSN" "option update home '${WORDPRESS_URL}' --path='${WP_C_PATH}'"
  dock_exec_wp_cli "$WP_CSN" "option update siteurl '${WORDPRESS_URL}' --path='${WP_C_PATH}'"
fi

# Continue with the next step in your flow
sh ${SCRIPTS_PATH}/lemp/wordpress/create-wordpress-17-complete.sh