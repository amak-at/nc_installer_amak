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
echo "Running install.sh as root..."

CONF_FILE_EXAMPLE="./setup/setup-example.conf"
CONF_FILE="$(pwd)/setup/setup.conf"

cp $CONF_FILE_EXAMPLE $CONF_FILE

source $CONF_FILE
mkdir $TEMP_DIR


# Change *.sh files for +x
find ./ -type f -name "*.sh" -exec chmod +x {} \;

echo "installing dialog for GUI.."
#apt-get update > /dev/null 2>&1
#apt-get install -y dialog > /dev/null 2>&1
echo "Done. Starting GUI..."

./setup/dialog/menu.sh $CONF_FILE

#clear
#./gui/install_menu.sh $ENV_DIR
#rm -R $ENV_DIR

exit 0