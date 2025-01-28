#!/bin/bash

die_on_fail() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >> $LOG_DIR/database_migration.log
    fi
}

# Specify the file name
file="db-list1.txt"

# Initialize an empty array
DATABASES=()

# Read the file line by line and store each line in the array
while IFS= read -r line; do
    DATABASES+=("$line")
done < "$file"

#read -p "Enter the directory to save database dumps on current server: " DUMP_DIR
#read -sp "Enter the mysql root password of the migrated server: " DBPASS
## Prompt for the server details
#read -p "Enter the local IP address of the migrating server: " SERVER_IP
#read -sp "Enter the root user password of the migrated server: " SERVER_PASS
#
## Prompt for the location to save dumps on migrated server
#read -p "Enter the directory to save database dumps on migrated server: " MIGRATE_DIR
#
## Prompt for the location to keep the log on the server
#read -p "Enter the directory to save the log on migrated server: " LOG_DIR

# Taking the mysql dumps 
echo "Starting database dumps on the current server"
for DB in "${DATABASES[@]}"; do
    touch /data/backup-migration/${DB}.sql
    echo "Taking dump of database: $DB..."
    mysqldump -h localhost -u root -pE9kuFO3jrVpQ --triggers --routines --events --hex-blob $DB | sed 's/\`$DB\`\.//g' > /data/backup-migration/${DB}.sql
    die_on_fail "Failed to take dump of database: $DB"
    echo "Dump of database: $DB completed successfully" >> /home/dheegayu/scripts/database_migration.log
done

#Creating the directory to save the mysql user dump
#mkdir -p $DUMP_DIR/mysql_user
#touch $DUMP_DIR/mysql_user/mysql_users.sql
#
##Exporting MySQL users
#echo "Exporting MySQL users from the current server..."
#"mysql -u root -p -e "SELECT * FROM mysql.user;" > $DUMP_DIR/mysql_user/mysql_users.sql"
#die_on_fail "Failed to export MySQL users"
#echo "MySQL users exported successfully" >> $LOG_DIR/database_migration.log

#Tranferring all the mysql dumps and the mysql users to the migration server.
#echo "Transferring MySQL users dump..."
#rsync -av -o --append --progress -e "ssh -i /root/.ssh/id_rsa -p 2112" /data/backup-migration/ root@192.168.100.100:/data/backup-migration/
#die_on_fail "Failed to transfer MySQL users dump"
#echo "MySQL users dump transferred successfully" >> /home/dheegayu/scripts/database_migration.log