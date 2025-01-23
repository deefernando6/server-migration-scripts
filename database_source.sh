#!/bin/bash

# Make sure to execute this script as root

# Prompt for the location to save dumps on the current server
read -p "Enter the directory where you keep the database dumps: " DUMP_DIR
read -sp "Enter the mysql mysql root password of the migrated server: " DBPASS