#!/bin/sh
# Ensure environment variables are loaded
set -a # Auto-export all variables
. /etc/environment
. "/${BACKUPS_CONTAINER_NAME}/.env"
. "/${BACKUPS_CONTAINER_NAME}/scripts/lemp-env.sh"
set +a # Disable auto-export

# Time
TIMESTAMP=$(get_timestamp)
LOCAL_TIME=$(get_local_time)
TODAY_DIR=$(get_today_dir)

backup_log "#############################################################################"

echo "🔥 Running $(basename "$0")..." |

	# Get list of WordPress databases (excluding system DBs)
	DATABASES=$(mysql -h "$MYSQL_HOST" -u root \
		-e "SHOW DATABASES;" | grep -Ev "(Database|mysql|information_schema|performance_schema|sys)")

## 📌 START WORDPRESS DATABASE FIXES ##

####################################################################
# Optimize Tables - Defragment tables for faster queries

backup_log "🛠 Optimizing WordPress tables..."
for DB in $DATABASES; do
	mysql -h "$MYSQL_HOST" -u root \
		-e "USE $DB; OPTIMIZE TABLE wp_options, wp_posts, wp_postmeta, wp_comments, wp_commentmeta, wp_termmeta, wp_terms, wp_term_taxonomy, wp_usermeta, wp_users;"
done
backup_log "✅ WordPress table optimization complete."

####################################################################
# Repair Corrupted Tables - Fixes common WordPress database issues

backup_log "🔧 Repairing potential WordPress database corruption..."
for DB in $DATABASES; do
	mysqlcheck -h "$MYSQL_HOST" -u root \
		--auto-repair --databases "$DB"
done
backup_log "✅ WordPress table repair complete."

####################################################################
# Cleanup Orphaned Metadata - Removes leftover post/comment metadata

backup_log "🧹 Cleaning up orphaned WordPress metadata..."
for DB in $DATABASES; do
	mysql -h "$MYSQL_HOST" -u root \
		-e "
        DELETE pm FROM $DB.wp_postmeta pm LEFT JOIN $DB.wp_posts p ON pm.post_id = p.ID WHERE p.ID IS NULL;
        DELETE cm FROM $DB.wp_commentmeta cm LEFT JOIN $DB.wp_comments c ON cm.comment_id = c.comment_ID WHERE c.comment_ID IS NULL;
    "
done
backup_log "✅ Orphaned metadata cleanup complete."

####################################################################
# Delete WordPress Transients - Clears expired cached options

backup_log "🗑 Removing expired WordPress transients..."
for DB in $DATABASES; do
	mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "
        DELETE FROM $DB.wp_options WHERE option_name LIKE ('_transient_%') AND option_value < NOW() - INTERVAL 3 DAY;
    "
done
backup_log "✅ Expired transients removed."

####################################################################
# Fix Auto-Increment Issues - Ensures proper ID sequencing

backup_log "🔢 Checking auto-increment consistency..."
for DB in $DATABASES; do
	mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "
        ALTER TABLE $DB.wp_posts AUTO_INCREMENT = 1;
        ALTER TABLE $DB.wp_comments AUTO_INCREMENT = 1;
        ALTER TABLE $DB.wp_users AUTO_INCREMENT = 1;
        ALTER TABLE $DB.wp_options AUTO_INCREMENT = 1;
    "
done
backup_log "✅ Auto-increment values reset."

####################################################################
# ✅ 6️⃣ Cleanup Spam Comments - Deletes spam flagged comments

backup_log "🛑 Removing spam comments..."
for DB in $DATABASES; do
	mysql -h "$MYSQL_HOST" -u root -p"$MYSQL_ROOT_PASSWORD" -e "DELETE FROM $DB.wp_comments WHERE comment_approved = 'spam';"
done
backup_log "✅ Spam comments removed."
