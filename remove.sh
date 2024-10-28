#!/bin/bash
source $1

rm -R $TEMP_DIR

if [ "$INSTALL_ONLYOFFICE" = "on" ]; then
    docker kill onlyoffice-document-server
    # to prune everything in docker
    # docker system prune -a
    docker container prune <<EOF
y
EOF
    sleep 2
fi
 
if [ "$INSTALL_NC" = "on" ]; then
    sudo -u www-data crontab -r
    rm -R $NC_DATA_DIR
    rm -R $NC_DIR
    systemctl stop apache2.service
    rm -R /etc/apache2 > /dev/null

    echo "Removing NC-installed packages....."
    apt purge -y apache* php* certbot python3-certbot-apache ffmpeg > /dev/null 2>&1
    rm -R /var/lib/mysql
    apt purge -y maria* > /dev/null 2>&1
    rm -R /etc/mysql
    echo "Removing NC-installation done!"
fi

if [ "$INSTALL_BACKUP" = "on" ]; then
    crontab -r
    echo "Removing Backup-Installation..."
    rm -R $BACKUP_ROOTDIR
    rm -R $BACKUP_DIR/daten
    apt purge -y borgbackup expect > /dev/null 2>&1
    echo "Removing Backup-Installation done!"
fi

echo "autopurge starting.."
apt autopurge -y > /dev/null 2>&1
echo "autopurge done!"

echo "remove.sh finished"

exit 0