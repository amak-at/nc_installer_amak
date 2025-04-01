#!/bin/bash
source $1

echo "Update system"
apt update -y > /dev/null
apt upgrade -y > /dev/null
echo "Updateing done!"

if [ "$INSTALL_NC" = "on" ]; then
    #install cron and curl
    echo "install apt-utils cron curl..."
    apt-get install -y --no-install-recommends apt-utils cron curl > /dev/null 2>&1

    #install apache2
    echo "install apache2..."
    apt-get install apache2 -y > /dev/null 2>&1

    #install php8.3
    echo "install PHP 8.3"
    apt-get install redis -y
    apt-get install -y php php-common php-redis php-apcu libapache2-mod-php php-bz2 php-gd php-mysql php-curl php-mbstring php-imagick php-zip php-common php-curl php-xml php-json php-bcmath php-xml php-intl php-gmp zip unzip wget -y > /dev/null 2>&1
    echo "PHP 8.3 done!"

    #install mariadb
    echo "install mariaDB..."
    apt-get install mariadb-server -y >/dev/null 2>&1
    echo "MariaDB install done!"

    if [ "$INSTALL_REVERSE_PROXY" = "off" ]; then
        apt install certbot python3-certbot-apache -y > /dev/null 2>&1
    fi
    
    if [ "$INSTALL_MEMORIES" = "on" ]; then
        echo "installing ffmpeg for memories app"
        apt-get install -y ffmpeg > /dev/null 2>&1
        echo "installation ffmpeg done!"
    fi
fi

if [ "$INSTALL_BACKUP" = "on" ]; then
    echo "Installing borgbackup...."
    apt-get install -y borgbackup expect > /dev/null 2>&1
    echo "Installation done."
fi

exit 0
