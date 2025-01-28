#!/bin/bash

die_on_fail() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >> $LOG_DIR/database_migration.log
    fi
}

# Specify the file name
file="db-list.txt"

# Initialize an empty array
DATABASES=()

# Read the file line by line and store each line in the array
while IFS= read -r line; do
    DATABASES+=("$line")
done < "$file"


echo "Starting database dumps on the current server"
for DB in "${DATABASES[@]}"; do
    mysql -u root -pE9kuFO3jrVpQ -e "CREATE DATABASE $DB CHARACTER SET utf8 COLLATE utf8_general_ci;"
done
