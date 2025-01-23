#!/bin/bash

# Make sure to execute this script as root

die_on_fail() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
    fi
}
# Prompt for the location to save dumps on the current server
read -p "Enter the directory where you keep the database dumps: " DUMP_DIR
read -sp "Enter the mysql mysql root password of the migrated server: " DBPASS

#Getting the db names
DATABASES=($($DUMP_DIR/basename -s .sql *.sql))

# Sourcing the databases
for DB in $DATABASES; do
    echo "Creating database: $DB..."
    mysql -h $SERVER_IP -u root -p-e 'CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci;'
    die_on_fail "Failed to create database: $DB"

    echo "Sourcing dump for database: $DB..."
    mysql -h $SERVER_IP -u root -p$DB < $DUMP_DIR/${DB}_dump.sql
    die_on_fail "Failed to source dump for database: $DB"
    echo "Database: $DB sourced successfully"
done

# Source MySQL users on Server2
echo "Sourcing MySQL users on Server2..."
mysql -h $SERVER_IP -u root -p < DUMP_DIR/mysql_user/mysql_users.sql
die_on_fail "Failed to source MySQL users"
echo "MySQL users sourced successfully"