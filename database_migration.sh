#!/bin/bash

# Make sure to execute this script as root

die_on_fail() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >> $LOG_DIR/database_migration.log
    fi
}
# Prompt for the location to save dumps on the current server
read -p "Enter the directory to save database dumps on current server: " DUMP_DIR
read -sp "Enter the mysql mysql root password of the migrated server: " DBPASS
# Prompt for the server details
read -p "Enter the local IP address of the migrating server: " SERVER_IP
read -sp "Enter the root user password of the migrated server: " SERVER_PASS

# Prompt for the location to save dumps on migrated server
read -p "Enter the directory to save database dumps on migrated server: " MIGRATE_DIR

# Prompt for the location to keep the log on the server
read -p "Enter the directory to save the log on migrated server: " LOG_DIR

#Creating the log files
touch $LOG_DIR/database_migration.log

# Take dumps of all MariaDB databases on the current server
echo "Fetching database list from the current server"
DATABASES=$(mysql -e 'SHOW DATABASES;' | grep -v Database | grep -v information_schema | grep -v performance_schema)
die_on_fail "Failed to fetch database list from the current server"

# Taking the mysql dumps 
echo "Starting database dumps on the current server"
for DB in $DATABASES; do
    echo "Taking dump of database: $DB..."
    mysqldump -h localhost -u root -p$DBPASS --triggers --routines --events --hex-blob $DB | sed 's/\`$DB\`\.//g' > $DUMP_DIR/${DB}_dump.sql
    die_on_fail "Failed to take dump of database: $DB"
    echo "Dump of database: $DB completed successfully" >> $LOG_DIR/database_migration.log
done

#Creating the directory to save the mysql user dump
mkdir -p $DUMP_DIR/mysql_user
touch $DUMP_DIR/mysql_user/mysql_users.sql

#Exporting MySQL users
echo "Exporting MySQL users from the current server..."
"mysql -e -h localhost -u root -p$DBPASS 'SELECT CONCAT(\"CREATE USER '\", user, \"'@'\", host, \"' IDENTIFIED BY PASSWORD '\", authentication_string, \"';\") FROM mysql.user;' > $DUMP_DIR/mysql_user/mysql_users.sql"
die_on_fail "Failed to export MySQL users"
echo "MySQL users exported successfully" >> $LOG_DIR/database_migration.log

#Tranferring all the mysql dumps and the mysql users to the migration server.
echo "Transferring MySQL users dump..."
sshpass -p $SERVER_PASS rsync -av -o --append --progress -e "ssh -p 2112" $DUMP_DIR/ root@$SERVER_IP:$DUMP_DIR/
die_on_fail "Failed to transfer MySQL users dump"
echo "MySQL users dump transferred successfully" >> $LOG_DIR/database_migration.log

#Creating the databases and sourcing the databases in the migration server

#echo "Starting to source databases on migration server..."
#for DB in $DATABASES; do
#    echo "Creating database: $DB..."
#    mysql -h $SERVER_IP -u root -p-e 'CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci;'
#    die_on_fail "Failed to create database: $DB"
#
#    echo "Sourcing dump for database: $DB..."
#    mysql -h $SERVER_IP -u root -p$DB < $DUMP_DIR/${DB}_dump.sql
#    die_on_fail "Failed to source dump for database: $DB"
#    echo "Database: $DB sourced successfully"
#done
#
## Source MySQL users on Server2
#echo "Sourcing MySQL users on Server2..."
#mysql -h $SERVER_IP -u root -p < DUMP_DIR/mysql_users.sql
#die_on_fail "Failed to source MySQL users"
#echo "MySQL users sourced successfully"