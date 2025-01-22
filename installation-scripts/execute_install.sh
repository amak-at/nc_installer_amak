#!/bin/bash

source $1
CONF_FILE="$1"

docker_installed=0

if [ "$START_INTALL" = "yes" ]; then
    echo "execute installation..."

    ./installation-scripts/install-dependencies.sh $CONF_FILE

    if [ "$CHANGE_HOSTNAME" = "on" ]; then
        ./installation-scripts/change-hostname.sh $CONF_FILE
    fi

    if [ "$CHANGE_NETWORKSETTINGS" = "on" ]; then
        ./installation-scripts/change-networksettings.sh $CONF_FILE
    fi

    if [ "$INSTALL_REVERSE_PROXY" = "on" ] && [ "$REVERSE_PROXY_IP" = "$NEW_IP_ADDR" ] ; then
        ./installation-scripts/install-docker.sh $CONF_FILE
        docker_installed=1
        ./installation-scripts/install-reverseproxy.sh $CONF_FILE
    fi

    if [ "$INSTALL_ONLYOFFICE" = "on" ]; then
        if [ "$docker_installed" = "0" ]; then
            ./installation-scripts/install-docker.sh $CONF_FILE
        fi
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