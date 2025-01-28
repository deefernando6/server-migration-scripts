#!/bin/bash

# Make sure to execute this script as root

DIRECTORIES=$(ls -d /home/dheegayu/server-migration/PROD/*)

for DIR in "${DIRECTORIES[@]}"; do
    rm -rf "$DIR/symfony/cache/*"
    cd "$DIR/symfony" && php symfony cc
done