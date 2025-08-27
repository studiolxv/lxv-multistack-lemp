#!/bin/sh
. "$PROJECT_PATH/_env-setup.sh"
# debug_file_msg "$(current_basename)"

#####################################################
# DATABASE OPTION CONFIGURATION

section_title "DATABASE CONFIGURATION"

case "$DB_IMAGE" in
*mysql* | *MySQL* | *mariadb* | *MariaDB* | *mariaDB*)
	DB_CONF_FILE="my.cnf"
	DB_CONTAINER_CONF_PATH="/etc/mysql/${DB_CONF_FILE}"
	DB_CONTAINER_DATA_PATH="/var/lib/mysql"
	;;
*percona*)
	DB_CONF_FILE="percona.cnf"
	DB_CONTAINER_CONF_PATH="/${DB_CONF_FILE}"
	DB_CONTAINER_DATA_PATH="/var/lib/mysql"
	;;
*postgres*)
	DB_CONF_FILE="postgresql.conf"
	DB_CONTAINER_CONF_PATH="/var/lib/postgresql/data/${DB_CONF_FILE}"
	DB_CONTAINER_DATA_PATH="/var/lib/postgresql/data"
	;;
*mongo*)
	DB_CONF_FILE="mongod.conf"
	DB_CONTAINER_CONF_PATH="/etc/mongod.conf"
	DB_CONTAINER_DATA_PATH="/data/db"
	;;
*redis*)
	DB_CONF_FILE="redis.conf"
	DB_CONTAINER_CONF_PATH="/etc/redis/${DB_CONF_FILE}"
	DB_CONTAINER_DATA_PATH="/data"
	;;
*)
	status_msg "No configuration file needed for $DB_IMAGE."
	DB_CONF_FILE=""
	DB_CONTAINER_CONF_PATH=""
	DB_CONTAINER_DATA_PATH=""
	;;
esac

DB_CONF_FILE_PATH="${LEMP_PATH}/${DB_DIR}/${DB_CONF_FILE}"

#####################################################
# GENERATE DATABASE CONFIGURATION FILE

# MySQL/MariaDB/Percona Configuration
if [ -n "${DB_CONF_FILE_PATH}" ]; then
	generating_msg "Creating ${DB_CONF_FILE} for $DB_IMAGE..."

	case "$DB_IMAGE" in
	*mysql* | *mariadb* | *percona*)
		cat <<EOF >"${DB_CONF_FILE_PATH}"
# MySQL Configuration
[mysqld]
host-cache-size=0
skip-name-resolve
datadir=${DB_CONTAINER_DATA_PATH}
socket=/var/run/mysqld/mysqld.sock
secure-file-priv=/var/lib/mysql-files
user=mysql
pid-file=/var/run/mysqld/mysqld.pid

!includedir /etc/mysql/conf.d/

[mysqldump]
set-gtid-purged=OFF
EOF
		;;

	*postgres*)
		cat <<EOF >"${DB_CONF_FILE_PATH}"
# PostgreSQL Configuration

listen_addresses = '*'
port = 5432

# Memory Settings
shared_buffers = 128MB
work_mem = 4MB
maintenance_work_mem = 64MB

# Logging
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql.log'
log_statement = 'mod'

# Authentication
password_encryption = scram-sha-256

# Replication
wal_level = replica
max_wal_senders = 10
EOF
		;;

	*mongo*)
		cat <<EOF >"${DB_CONF_FILE_PATH}"
# MongoDB Configuration

storage:
  dbPath: ${DB_CONTAINER_DATA_PATH}
  journal:
    enabled: true

net:
  bindIp: 0.0.0.0
  port: 27017

security:
  authorization: enabled

systemLog:
  destination: file
  path: "/var/log/mongodb/mongod.log"
  logAppend: true
EOF
		;;

	*redis*)
		cat <<EOF >"${DB_CONF_FILE_PATH}"
# Redis Configuration

bind 0.0.0.0
port 6379

# Memory Settings
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes

# Logging
loglevel notice
logfile "/var/log/redis/redis.log"
EOF
		;;
	esac


else
	status_msg "No configuration file required for $DB_IMAGE."
fi




if [ -f "$DB_CONF_FILE_PATH" ]; then
	# Set correct permissions
	chmod 600 "${DB_CONF_FILE_PATH}"
	status_msg "✅ ${DB_CONF_FILE} created at ${DB_CONF_FILE_PATH}"
else
	error_msg "Configuration file $DB_CONF_FILE_PATH does not exist. Something went wrong please delete all created files and start again."
fi


#####################################################
# EXPORTS
export DB_CONF_FILE
export DB_CONF_FILE_PATH
export DB_CONTAINER_CONF_PATH
export DB_CONTAINER_DATA_PATH

#####################################################
# CREATE LEMP STACK
sh "${SCRIPTS_PATH}/lemp/create-lemp/create-lemp-8-directory-secrets.sh"
