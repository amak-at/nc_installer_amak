#!/bin/bash
source $1
# Set the hostname
echo "$NEW_HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$NEW_HOSTNAME"
echo "The hostname has been set to $NEW_HOSTNAME."

exit 0
