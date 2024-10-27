#!/bin/bash
source $1

# Check if the script is run as root

#clear crontab
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

echo "Removing installed packages....."
apt purge -y apache* php* borgbackup certbot python3-certbot-apache ffmpeg > /dev/null 2>&1
apt purge -y maria*

echo "Removing done!"


exit 0