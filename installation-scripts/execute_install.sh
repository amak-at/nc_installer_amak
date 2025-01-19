#!/bin/bash

source $1
CONF_FILE="$1"

if [ "$START_INTALL" = "yes" ]; then
    echo "execute installation..."

    ./installation-scripts/install-dependencies.sh $CONF_FILE

    if [ "$CHANGE_HOSTNAME" = "on" ]; then
    ./installation-scripts/change-hostname.sh $CONF_FILE
    fi

    if [ "$CHANGE_NETWORKSETTINGS" = "on" ]; then
    ./installation-scripts/change-networksettings.sh $CONF_FILE

    fi

    if [ "$INSTALL_ONLYOFFICE" = "on" ]; then
    ./installation-scripts/install-onlyoffice.sh $CONF_FILE
    fi
    
    if [ "$INSTALL_NC" = "on" ]; then
    ./installation-scripts/install-nextcloud.sh $CONF_FILE
    fi

    if [ "$INSTALL_BACKUP" = "on" ]; then
    ./installation-scripts/install-borgbackup.sh $CONF_FILE
    fi

else
    echo "Nextcloud-Installationsscript (c) AMAK-AT abgebrochen"
fi

exit 0