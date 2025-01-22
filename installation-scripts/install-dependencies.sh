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
    echo "install PHP 8.2 ..."
    apt-get install software-properties-common -y > /dev/null 2>&1
    add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
    apt-get update > /dev/null 2>&1
    apt-get install -y php8.2 libapache2-mod-php8.2 php8.2-zip php8.2-xml php8.2-mbstring php8.2-gd php8.2-curl php8.2-imagick > /dev/null 2>&1
    apt-get install -y libmagickcore-6.q16-6-extra php8.2-intl php8.2-bcmath php8.2-gmp php8.2-cli php8.2-mysql php8.2-zip php8.2-gd  php8.2-mbstring php8.2-curl > /dev/null 2>&1
    apt-get install -y php8.2-xml php-pear unzip nano php8.2-apcu redis-server ufw php8.2-redis php8.2-smbclient php8.2-ldap php8.2-bz2 > /dev/null 2>&1
    echo "PHP 8.2 done!"

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