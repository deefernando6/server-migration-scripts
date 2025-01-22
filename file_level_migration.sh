#!/bin/bash

# Make sure to execute this script as root

# Prompt for the server details
read -p "Enter the local IP address of the migrating server: " SERVER_IP
read -sp "Enter the root password of the migrated server: " SERVER_PASS


echo "Starting rsync of codebases from the current server to the migration server"

# Getting all the codebases list from the current server to migration server
DIRECTORIES=$(ls -d /var/www/html/OHRMStandalone/PROD/*/)

# Syncing the directories from current server to migration
for DIR in $DIRECTORIES; do
    BASENAME=$(basename "$DIR")
    echo "Syncing directory: $BASENAME..."
    sshpass -p $SERVER_PASS rsync -av -o --append --progress -e "ssh -p 2112" $DIR/ root@$SERVER_IP:/var/www/html/OHRMStandalone/PROD/
    die_on_fail "Failed to sync directory: $BASENAME"
    echo "Directory: $BASENAME synced successfully"
done

#Syncing the nginx vhosts from the current server to the migration server
sshpass -p $SERVER_PASS rsync -av -o --append --progress -e "ssh -p 2112" /etc/nginx/vhosts/ root@$SERVER_IP:/etc/nginx/