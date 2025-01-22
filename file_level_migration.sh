#!/bin/bash

# Make sure to execute this script as root

# Prompt for the server details
read -p "Enter the local IP address of the migrating server: " SERVER_IP
read -sp "Enter the root password of the migrated server: " SERVER_PASS