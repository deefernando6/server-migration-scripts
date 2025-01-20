#!/bin/bash

# Function to check if the last command was successful
die_on_fail() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Prompt for server details and credentials
read -p "Enter the IP address of Server1: " SERVER1_IP
read -p "Enter the username for Server1: " SERVER1_USER
read -sp "Enter the password for Server1: " SERVER1_PASS
echo
read -p "Enter the SSH port for Server1: " SERVER1_PORT
echo
read -p "Enter the IP address of Server2: " SERVER2_IP
read -p "Enter the username for Server2: " SERVER2_USER
read -sp "Enter the password for Server2: " SERVER2_PASS
echo
read -p "Enter the SSH port for Server2: " SERVER2_PORT
echo

# Prompt for directory paths
read -p "Enter the directory location on Server1: " SERVER1_DIR
read -p "Enter the destination directory location on Server2: " SERVER2_DIR

# Prompt for the location to save dumps on Server1
read -p "Enter the directory to save database dumps on Server1: " DUMP_DIR

# Prompt for the location to save dumps on Server2
read -p "Enter the directory to store database dumps on Server2: " SERVER2_DUMP_DIR

# Login credentials for SSH and MySQL
SSH_SERVER1="sshpass -p $SERVER1_PASS ssh -p $SERVER1_PORT $SERVER1_USER@$SERVER1_IP"
SSH_SERVER2="sshpass -p $SERVER2_PASS ssh -p $SERVER2_PORT $SERVER2_USER@$SERVER2_IP"

# Step 1: Take dumps of all MariaDB databases on Server1
echo "Fetching database list from Server1 ($SERVER1_IP)..."
DATABASES=$($SSH_SERVER1 "mysql -e 'SHOW DATABASES;' | grep -v Database | grep -v information_schema | grep -v performance_schema")
die_on_fail "Failed to fetch database list from Server1"

echo "Starting database dumps on Server1 ($SERVER1_IP)..."
for DB in $DATABASES; do
    echo "Taking dump of database: $DB..."
    $SSH_SERVER1 "mysqldump -h localhost -u root -ppassword --triggers --routines --events --hex-blob $DB | sed 's/\`$DB\`\.//g' > $DUMP_DIR/${DB}_dump.sql"
    die_on_fail "Failed to take dump of database: $DB"
    echo "Dump of database: $DB completed successfully"
done

# Export MySQL users
echo "Exporting MySQL users from Server1..."
$SSH_SERVER1 "mysql -u root -ppassword -e 'SELECT CONCAT(\"CREATE USER '\", user, \"'@'\", host, \"' IDENTIFIED BY PASSWORD '\", authentication_string, \"';\") FROM mysql.user;' > $DUMP_DIR/mysql_users.sql"
die_on_fail "Failed to export MySQL users"
echo "MySQL users exported successfully"

# Step 2: Transfer all dumps to Server2
echo "Transferring all dumps to Server2 ($SERVER2_IP)..."
for DB in $DATABASES; do
    echo "Transferring dump for database: $DB..."
    sshpass -p $SERVER1_PASS scp -P $SERVER1_PORT $SERVER1_USER@$SERVER1_IP:$DUMP_DIR/${DB}_dump.sql $SERVER2_USER@$SERVER2_IP:$SERVER2_DUMP_DIR/
    die_on_fail "Failed to transfer dump for database: $DB"
    echo "Dump of database: $DB transferred successfully"
done

# Transfer MySQL users dump
echo "Transferring MySQL users dump..."
sshpass -p $SERVER1_PASS scp -P $SERVER1_PORT $SERVER1_USER@$SERVER1_IP:$DUMP_DIR/mysql_users.sql $SERVER2_USER@$SERVER2_IP:$SERVER2_DUMP_DIR/
die_on_fail "Failed to transfer MySQL users dump"
echo "MySQL users dump transferred successfully"

# Step 3: Source all databases on Server2
echo "Starting to source databases on Server2..."
for DB in $DATABASES; do
    echo "Creating database: $DB..."
    $SSH_SERVER2 "mysql -e 'CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci;'"
    die_on_fail "Failed to create database: $DB"

    echo "Sourcing dump for database: $DB..."
    $SSH_SERVER2 "mysql $DB < $SERVER2_DUMP_DIR/${DB}_dump.sql"
    die_on_fail "Failed to source dump for database: $DB"
    echo "Database: $DB sourced successfully"
done

# Step 4: Rsync directories from Server1 to Server2
echo "Starting rsync of directories from Server1 ($SERVER1_IP) to Server2 ($SERVER2_IP)..."
DIRECTORIES=$($SSH_SERVER1 "ls -d $SERVER1_DIR/*/")
die_on_fail "Failed to list directories on Server1"

for DIR in $DIRECTORIES; do
    BASENAME=$(basename "$DIR")
    echo "Syncing directory: $BASENAME..."
    sshpass -p $SERVER1_PASS rsync -avz --append --progress -e "ssh -p $SERVER1_PORT" $SERVER1_USER@$SERVER1_IP:$DIR $SERVER2_USER@$SERVER2_IP:$SERVER2_DIR/
    die_on_fail "Failed to sync directory: $BASENAME"
    echo "Directory: $BASENAME synced successfully"
done

echo "Script execution completed successfully!"