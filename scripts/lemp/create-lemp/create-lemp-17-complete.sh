#!/bin/sh
# create-lemp-17-complete.sh — bring the stack up and finish DB init
# Load env and helpers
. "${PROJECT_PATH}/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# START LEMP CONTAINER
sleep 3
# Load project .env (so docker-compose has all vars)
. "${LEMP_ENV_FILE}"

# Restart Traefik (optional; ignore errors if not present)
cd "${PROJECT_PATH}" || exit 1
(docker restart multistack-traefik >/dev/null 2>&1 || true)

# Start the LEMP stack
cd "${LEMP_PATH}" || exit 1
status_msg "Starting LEMP stack…"
docker-compose up -d
line_break

#####################################################
# DATABASE POST-INIT

# Ensure we have the root secret file path and contents
if [ -z "${DB_ROOT_USER_PASSWORD_FILE:-}" ] || [ ! -f "${DB_ROOT_USER_PASSWORD_FILE}" ]; then
    warning_msg "DB_ROOT_USER_PASSWORD_FILE not set or file missing: ${DB_ROOT_USER_PASSWORD_FILE:-<unset>}"
    exit 1
fi
MYSQL_ROOT_PASSWORD="$(cat "${DB_ROOT_USER_PASSWORD_FILE}" 2>/dev/null)"

# Create a client-only my.cnf inside the DB container for convenience (uses secret at runtime)
docker exec -i "${DB_HOST_NAME}" sh -lc '
PASS="$(cat /run/secrets/db_root_user_password 2>/dev/null || printf "")"
mkdir -p /root
umask 177
cat > /root/.my.cnf <<EOF
[client]
user=root
password=${PASS}
socket=/var/run/mysqld/mysqld.sock
EOF
chmod 600 /root/.my.cnf
'

# Wait for DB to report healthy (max ~60s)
status_msg "Waiting for database container to become healthy…"
i=0
while :; do
    health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "${DB_HOST_NAME}" 2>/dev/null || true)
    [ "${health}" = "healthy" ] && break
    i=$((i+1))
    if [ ${i} -ge 30 ]; then
        warning_msg "Database did not reach healthy state in time; will attempt initialization anyway."
        break
    fi
    sleep 2
done

# ---- Phase A: handle insecure bootstrap (no root password, socket auth) ----
status_msg "Phase A: ensuring root@localhost has a password (socket connection)…"
# Use socket connection (omit -h) to cover initialize-insecure cases. Ignore errors if already set.
docker exec -i "${DB_HOST_NAME}" sh -lc "\
mysql -uroot --protocol=SOCKET -S /var/run/mysqld/mysqld.sock <<SQL
CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
SQL
" >/dev/null 2>&1 || true

# ---- Phase B: finish over TCP with password ----
status_msg "Phase B: applying DB, remote root/grants over TCP (127.0.0.1)…"
if ! docker exec -i "${DB_HOST_NAME}" sh -lc "mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' -h127.0.0.1 -e 'SELECT 1' >/dev/null 2>&1"; then
    warning_msg "Root authentication over TCP failed; attempting to create network user via socket…"
    docker exec -i "${DB_HOST_NAME}" sh -lc "\
mysql -uroot --protocol=SOCKET -S /var/run/mysqld/mysqld.sock <<SQL
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
    " >/dev/null 2>&1 || true
    # retry TCP ping
    if docker exec -i "${DB_HOST_NAME}" sh -lc "mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' -h127.0.0.1 -e 'SELECT 1' >/dev/null 2>&1"; then
        success_msg "Root authentication over TCP is now working."
    else
        warning_msg "Root TCP authentication still failing. Check MySQL auth plugins and user@host entries."
    fi
fi

docker exec -i "${DB_HOST_NAME}" sh -lc "\
mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' -h127.0.0.1 <<SQL
-- Create project database if it doesn't exist
CREATE DATABASE IF NOT EXISTS \`${LEMP_CONTAINER_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Allow root from Docker network (for phpMyAdmin/tests). Consider replacing with a dedicated app user.
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
" >/dev/null 2>&1 || warning_msg "MySQL post-initialization may have partially failed. Check container logs."


#####################################################
# WAIT TIL DB SERVICE CONTAINER READY

# Wait for the WordPress service container to be healthy or running
if ! wait_for_container_ready "$DB_HOST_NAME" 180 2; then
    warning_msg "${C_Yellow}Timed out waiting for '$DB_HOST_NAME' to be healthy.${C_Reset} Proceeding anyway."
fi

if ! wait_for_container_ready "$PHPMYADMIN_CONTAINER_NAME" 180 2; then
    warning_msg "${C_Yellow}Timed out waiting for '$PHPMYADMIN_CONTAINER_NAME' to be healthy.${C_Reset} Proceeding anyway."
fi
sleep 2
PMA_USER="pma"
PMA_DB="phpmyadmin"
PMA_PASS="strong-pma-password"

# Create DB + user + grants by piping SQL from host into mysql inside the DB container
cat <<SQL | docker exec -i "${DB_HOST_NAME}" sh -lc "mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' -h127.0.0.1"
CREATE DATABASE IF NOT EXISTS \`${PMA_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${PMA_USER}'@'%' IDENTIFIED BY '${PMA_PASS}';
GRANT ALL PRIVILEGES ON \`${PMA_DB}\`.* TO '${PMA_USER}'@'%';
FLUSH PRIVILEGES;
SQL

# Load phpMyAdmin’s configuration storage schema:
# stream the SQL file out of the phpMyAdmin container and pipe it into mysql in the DB container
if docker exec "${PHPMYADMIN_CONTAINER_NAME}" test -f /var/www/html/sql/create_tables.sql; then
    docker exec "${PHPMYADMIN_CONTAINER_NAME}" cat /var/www/html/sql/create_tables.sql \
    | docker exec -i "${DB_HOST_NAME}" sh -lc "mysql -uroot -p'${MYSQL_ROOT_PASSWORD}' -h127.0.0.1 '${PMA_DB}'" || \
    warning_msg "Failed to import phpMyAdmin schema into '${PMA_DB}'."
else
    warning_msg "phpMyAdmin schema file not found in container '${PHPMYADMIN_CONTAINER_NAME}'. Skipping import."
fi

#####################################################
# LEMP: SUCCESS MESSAGE

heading "SUCCESS"
success_msg "🎉 ${C_Green}LEMP Stack \"${NEW_STACK_NAME}\" successfully set up."

lemp_started_message "${LEMP_SERVER_DOMAIN_NAME}"
lemp_host_file_trusted_cert_message

line_break

sh "${SCRIPTS_PATH}/multistack/manage-multistack.sh" "${NEW_STACK_NAME}"
