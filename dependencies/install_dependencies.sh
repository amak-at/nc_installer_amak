#!/bin/bash

#update system
apt update && apt upgrade -y

#install cron and curl
apt-get install -y --no-install-recommends apt-utils cron curl

#install apache2
apt install apache2 -y

#install php8.3
apt install software-properties-common -y
add-apt-repository ppa:ondrej/php -y
apt update
apt install php8.2 libapache2-mod-php8.2 php8.2-zip php8.2-xml php8.2-mbstring php8.2-gd php8.2-curl php8.2-imagick libmagickcore-6.q16-6-extra php8.2-intl php8.2-bcmath php8.2-gmp php8.2-cli php8.2-mysql php8.2-zip php8.2-gd  php8.2-mbstring php8.2-curl php8.2-xml php-pear unzip nano php8.2-apcu redis-server ufw php8.2-redis php8.2-smbclient php8.2-ldap php8.2-bz2 -y
#isntall mariadb
apt install mariadb-server -y
