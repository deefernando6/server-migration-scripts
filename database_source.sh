#!/bin/bash

# Make sure to execute this script as root

die_on_fail() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >> $LOG_DIR/database_source.log
    fi
}
# Prompt for the location to save dumps on the current server
read -p "Enter the directory where you keep the database dumps: " DUMP_DIR
read -sp "Enter the mysql mysql root password of the migrated server: " DBPASS

# Prompt for the location to keep the log on the server
read -p "Enter the directory to save the log on migrated server: " LOG_DIR

#Creating the log files
mkdir -p $LOG_DIR
touch $LOG_DIR/database_source.log

#Creating the dump drectory
#mkdir -p $DUMP_DIR

#Getting the db names
DATABASES=($(ls $DUMP_DIR/*.sql | sed 's/\.sql$//' | xargs -n 1 basename))

# Sourcing the databases
for DB in "${DATABASES[@]}"; do
    echo "Creating database: $DB..."
    mysql -u root -p$DBPASS -e "CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci;"
    die_on_fail "Failed to create database: $DB"

    echo "Sourcing dump for database: $DB..."
    mysql -u root -p$DBPASS < $DUMP_DIR/${DB}.sql
    die_on_fail "Failed to source dump for database: $DB"
    echo "Database: $DB sourced successfully" >> $LOG_DIR/database_source.log
done

# Source MySQL users on Server2
#echo "Sourcing MySQL users on Server2..."
#mysql -u root -p < DUMP_DIR/mysql_user/mysql_users.sql
#die_on_fail "Failed to source MySQL users"
#echo "MySQL users sourced successfully" >> $LOG_DIR/database_source.log