#!/bin/bash

# Make sure to execute this script as root

# Prompt for the location to save dumps on the current server
read -p "Enter the directory to save database dumps on current server: " DUMP_DIR

# Prompt for the server details
read -p "Enter the local IP address of the migrating server: " SERVER_IP
read -sp "Enter the root password of the migrated server: " SERVER_PASS

# Prompt for the location to save dumps on migrated server
read -p "Enter the directory to save database dumps on migrated server: " MIGRATE_DIR


# Take dumps of all MariaDB databases on the current server
echo "Fetching database list from the current server"
DATABASES=$(mysql -e 'SHOW DATABASES;' | grep -v Database | grep -v information_schema | grep -v performance_schema)
die_on_fail "Failed to fetch database list from the current server"

# Taking the mysql dumps 
echo "Starting database dumps on the current server"
for DB in $DATABASES; do
    echo "Taking dump of database: $DB..."
    mysqldump -h localhost --triggers --routines --events --hex-blob $DB | sed 's/\`$DB\`\.//g' > $DUMP_DIR/${DB}_dump.sql
    die_on_fail "Failed to take dump of database: $DB"
    echo "Dump of database: $DB completed successfully"
done

#Exporting MySQL users
echo "Exporting MySQL users from the current server..."
"mysql -e 'SELECT CONCAT(\"CREATE USER '\", user, \"'@'\", host, \"' IDENTIFIED BY PASSWORD '\", authentication_string, \"';\") FROM mysql.user;' > $DUMP_DIR/mysql_users.sql"
die_on_fail "Failed to export MySQL users"
echo "MySQL users exported successfully"

#Tranferring all the mysql dumps and the mysql users to the migration server.
echo "Transferring MySQL users dump..."
sshpass -p $SERVER_PASSrsync -av -o --append --progress -e "ssh -p 2112" $DUMP_DIR/ root@$SERVER_IP:$MIGRATE_DIR/
die_on_fail "Failed to transfer MySQL users dump"
echo "MySQL users dump transferred successfully"

