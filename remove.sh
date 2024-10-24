#!/bin/bash
source $1

# Check if the script is run as root
sudo -u www-data crontab -r
crontab -r

rm -R /tmp/latest*
rm -R $TEMP_DIR
rm -R $NC_DATA_DIR
rm -R $NC_DIR
rm -R $BACKUP_ROOTDIR
rm -R $BACKUP_DIR/daten
systemctl stop apache2.service
rm -R /etc/apache2
apt purge -y apache* php* mariadb* borgbackup certbot python3-certbot-apache


exit 0