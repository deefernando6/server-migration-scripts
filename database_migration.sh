# Make sure to execute this script as root


#!/bin/bash

# Prompt for the location to save dumps on the current server
read -p "Enter the directory to save database dumps on current server: " DUMP_DIR

#prompt for the server details
read -p "Enter the IP address of the migrating server: " SERVER_IP
read -sp "Enter the root password of the migrated server: " SERVER_PASS

#prompt for the location to save dumps on migrated server
read -p "Enter the directory to save database dumps on migrated server: " SOURCE_DIR
