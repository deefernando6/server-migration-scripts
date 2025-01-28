#!/bin/bash

# Make sure to execute this script as root

DIRECTORIES=$(ls -d /var/www/html/OHRMStandalone/PROD/*)

for DIR in $DIRECTORIES; do
    echo "Clearing cache of the $DIR"	
    cd "$DIR/symfony/cache/" && rm -rf *
    echo "Executing php symfony cc for $DIR"
    cd "$DIR/symfony" && sudo php symfony doctrine:build-model && sudo php symfony orangehrm:publish-assets && sudo php symfony cc && sudo php symfony o:restore-theme
    #cd "$DIR/symfony" && sudo php symfony orangehrm:ScheduledTasksFailureDiagnostic	
done