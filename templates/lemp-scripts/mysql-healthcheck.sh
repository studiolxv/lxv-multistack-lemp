#!/bin/sh
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_user_password)
mysqladmin ping -h localhost -u root -p"$MYSQL_ROOT_PASSWORD"
