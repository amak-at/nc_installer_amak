#!/bin/bash
# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run as root!"
   exit 1
fi

rm -R /home/data/nc-admin
rm -R /var/www/nextcloud
apt purge apache2 php* mariadb* -y