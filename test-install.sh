#!/bin/bash

# Function to check if the script is running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root."
        # ask for root pw
        read -sp "Please enter your password: " password
        echo
        # try to login as root
        if echo "$password" | sudo -S true; then
            echo "Password accepted. Running script with root privileges..."
            exec sudo "$0" "$@"
        else
            echo "Incorrect password. Exiting."
            exit 1
        fi
    fi
}


# Call the function to check for root
check_root

# From now on with root permissions
echo "Running test-install.sh as root..."

# Change *.sh files for +x
find ./ -type f -name "*.sh" -exec chmod +x {} \;

###################
# TESTING SECTION #
###################

TEST_CONF_FILE="$(pwd)/setup/config/test-setup.conf"


source $TEST_CONF_FILE


./remove.sh $TEST_CONF_FILE

mkdir $TEMP_DIR

if [ "$CHANGE_HOSTNAME" = "on" ]; then
 ./installation-scripts/change-hostname.sh $TEST_CONF_FILE
fi

if [ "$CHANGE_NETWORKSETTINGS" = "on" ]; then
 ./installation-scripts/change-networksettings.sh $TEST_CONF_FILE

fi
 
if [ "$INSTALL_NC" = "on" ]; then
 ./installation-scripts/install_nextcloud.sh $TEST_CONF_FILE

fi

if [ "$INSTALL_BACKUP" = "on" ]; then
 ./installation-scripts/install-borgbackup.sh $TEST_CONF_FILE
fi

exit 0