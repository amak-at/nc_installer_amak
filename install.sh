#!/bin/bash
# define temp-directory for installtion
ENV_DIR="/tmp/nc-installer"

# Function to check if the script is running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Please enter your password."
        exec sudo "$0" "$@"  # Re-execute the script with sudo
        exit 1
    fi
}

# Call the function to check for root
check_root

# From now on with root permissions

# Change *.sh files for +x
find ./ -type f -name "*.sh" -exec chmod +x {} \;
mkdir $ENV_DIR

./gui/install_menu.sh $ENV_DIR
#rm -R $ENV_DIR

exit 0