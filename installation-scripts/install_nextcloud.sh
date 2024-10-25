#!/bin/bash
source $1

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

if [ "$USE_REVERSE_PROXY" = "off"]; then
    apt install certbot python3-certbot-apache -y
fi

# Secure MariaDB Installation
echo "Securing MariaDB installation..."
mysql_secure_installation <<EOF

y
n
y
y
y
y
EOF

# Wait for MariaDB to start
sleep 5

# Open SQL dialog and execute commands
echo "Creating database and user..."
mysql -e "CREATE DATABASE $NC_DB_NAME;"
mysql -e "CREATE USER '$NC_DB_USER'@'localhost' IDENTIFIED BY '$NC_DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $NC_DB_NAME.* TO '$NC_DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Database and user created successfully."


# PHP configuring
echo "Configure PHP..."
PHP_CONFIG_FILE="/etc/php/8.2/apache2/php.ini"

# Get the system's current timezone
OS_TIMEZONE=$(timedatectl show --property=Timezone --value)

# Definiere die Einstellungen als assoziatives Array
declare -A SETTINGS=(
    ["memory_limit"]="4096M"
    ["upload_max_filesize"]="20G"
    ["post_max_size"]="20G"
    ["date.timezone"]="$OS_TIMEZONE"
    ["output_buffering"]="Off"
    ["opcache.enable"]="1"
    ["opcache.enable_cli"]="1"
    ["opcache.interned_strings_buffer"]="64"
    ["opcache.max_accelerated_files"]="10000"
    ["opcache.memory_consumption"]="1024"
    ["opcache.save_comments"]="1"
    ["opcache.revalidate_freq"]="1"
)

for KEY in "${!SETTINGS[@]}"; do
    VALUE=${SETTINGS[$KEY]}

    # Prüfe auf exakte Übereinstimmung (mit optionalem Kommentarzeichen und Leerzeichen)
    if grep -Eq "^[;#]?\s*${KEY}\s*=" "$PHP_CONFIG_FILE"; then
        # Ersetze nur exakte Übereinstimmungen
        sed -i "s|^[;#]\?\s*${KEY}\s*=.*|${KEY} = ${VALUE}|" "$PHP_CONFIG_FILE"
    else
        # Wenn der Eintrag nicht existiert, füge ihn am Ende der Datei hinzu
        echo "${KEY} = ${VALUE}" >> "$PHP_CONFIG_FILE"
    fi
done

echo "PHP configuration complete."

# Download lastest nextcloud version
echo "Install Nextcloud..."

cd /tmp && wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
mv nextcloud $NC_BASE/

mkdir $NC_DATA_DIR
chown -R www-data:www-data $NC_DATA_DIR
chown -R www-data:www-data $NC_DIR
chmod -R 755 $NC_DIR

#define autoconfig for skipping First setup Screen
cat <<EOF > $NC_AUTOCONFIG_FILE
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql",
  "dbname"        => "$NC_DB_NAME",
  "dbuser"        => "$NC_DB_USER",
  "dbpass"        => "$NC_DB_PASS",
  "dbhost"        => "localhost",
  "dbtableprefix" => "oc_",
  "adminlogin"    => "$NC_ADMIN_USER",
  "adminpass"     => "$NC_ADMIN_USER_PASS",
  "directory"     => "$NC_DATA_DIR",
);
EOF

chown www-data:www-data $NC_AUTOCONFIG_FILE

echo "Finished installing Nextcloud."

# Configure Apache
echo "Creating Apache configuration file for Nextcloud..."

cat <<EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:$NC_PORT>
    ServerAdmin master@localhost
    DocumentRoot $NC_DIR
    ServerName $NC_FQDN

    <Directory $NC_DIR/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        SetEnv HOME $NC_DIR
        SetEnv HTTP_HOME $NC_DIR
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <IfModule mod_headers.c>
            Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </IfModule>

</VirtualHost>
EOF

cat <<EOF > /etc/apache2/ports.conf
Listen $NC_PORT

<IfModule ssl_module>
        Listen 443
</IfModule>

<IfModule mod_gnutls.c>
        Listen 443
</IfModule>
EOF

# Enable the new site and required Apache modules
echo "Enabling Nextcloud site and required modules..."
a2ensite nextcloud.conf
a2dissite 000-default.conf
a2enmod rewrite
a2enmod headers
a2enmod env
a2enmod dir
a2enmod mime

echo "Enabeling done."

if [ "$USE_REVERSE_PROXY" = "off" ]; then
    echo "No reverse Proxy in use. Create certificate.."
    certbot --apache -m $CERTBOT_EMAIL -d $NC_FQDN
    echo "Certificate for $NC_FQDN created."
fi

# Restart Apache to apply changes
echo "Restarting Apache..."
systemctl restart apache2

echo "Nextcloud Apache configuration created successfully."

# Configure Nextcloud
echo "Configure Nextcloud"

curl "http://localhost:$NC_PORT"

cd $NC_DIR
sudo -u www-data php8.2 occ maintenance:repair --include-expensive
sudo -u www-data php8.2 occ db:add-missing-indices
sudo -u www-data php8.2 occ config:system:set maintenance_window_start --type=integer --value=1
sudo -u www-data php8.2 occ config:system:set default_phone_region --value="AT"
sudo -u www-data php8.2 occ background:cron
sudo -u www-data php8.2 occ config:system:set memcache.local --type=string --value="\OC\Memcache\Redis"
sudo -u www-data php8.2 occ config:system:set memcache.locking --type=string --value="\OC\Memcache\Redis"
sudo -u www-data php8.2 occ config:system:set redis host --value=localhost
sudo -u www-data php8.2 occ config:system:set redis port --value=6379
sudo -u www-data php8.2 occ config:system:set redis dbindex --value=0
sudo -u www-data php8.2 occ config:system:set redis password --value=
sudo -u www-data php8.2 occ config:system:set redis timeout --value=1.5
sudo -u www-data php8.2 occ config:system:set trusted_domains 0 --value=localhost
sudo -u www-data php8.2 occ config:system:set trusted_domains 1 --value=$NC_FQDN

if [ "$USE_REVERSE_PROXY" = "on" ]; then
    sudo -u www-data php8.2 occ config:system:set trusted_proxies 0 --value=$REVERSE_PROXY_IP
fi


(echo "*/5  *  *  *  * php8.2 -f $NC_DIR/cron.php") | crontab -u www-data -

echo "Finished configuring Nextcloud."
echo "Restart Apache..."
systemctl reload apache2.service
echo "Done restarting."
cd $STARTING_DIR

exit 0