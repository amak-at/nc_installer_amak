#!/bin/bash

# Get the current hostname
CURRENT_HOSTNAME=$(hostname)
# Set the hostname
read -rep "Enter new hostname (current: $CURRENT_HOSTNAME) " -i "$CURRENT_HOSTNAME" NEW_HOSTNAME
echo "$NEW_HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$NEW_HOSTNAME"
echo "The hostname has been set to $NEW_HOSTNAME."

exit 0
