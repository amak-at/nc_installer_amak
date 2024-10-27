#!/bin/bash
source $1

#install cron and curl
echo "install apt-utils cron curl..."
apt-get install -y --no-install-recommends apt-utils cron curl > /dev/null 2>&1

#install apache2
echo "install apache2..."
apt install apache2 -y > /dev/null 2>&1

#install php8.3
echo "install PHP 8.2 ..."
apt install software-properties-common -y > /dev/null 2>&1
add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
apt update > /dev/null 2>&1
apt install -y php8.2 libapache2-mod-php8.2 php8.2-zip php8.2-xml php8.2-mbstring php8.2-gd php8.2-curl php8.2-imagick > /dev/null 2>&1
apt install -y libmagickcore-6.q16-6-extra php8.2-intl php8.2-bcmath php8.2-gmp php8.2-cli php8.2-mysql php8.2-zip php8.2-gd  php8.2-mbstring php8.2-curl > /dev/null 2>&1
apt install -y php8.2-xml php-pear unzip nano php8.2-apcu redis-server ufw php8.2-redis php8.2-smbclient php8.2-ldap php8.2-bz2 > /dev/null 2>&1
echo "PHP 8.2 done!"

#isntall mariadb
echo "install mariaDB..."
apt install mariadb-server -y >/dev/null 2>&1
echo "MariaDB install done!"


if [ "$USE_REVERSE_PROXY" = "off"]; then
    apt install certbot python3-certbot-apache -y > /dev/null 2>&1
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
echo "unzip Nextcloud..."
unzip latest.zip >/dev/null
echo "unzipping done!"

mv nextcloud $NC_BASE/

mkdir $NC_DATA_DIR
chown -R www-data:www-data $NC_DATA_DIR
chown -R www-data:www-data $NC_DIR
chmod -R 755 $NC_DIR

#define autoconfig for skipping First setup Screen
echo "creating $NC_AUTOCONFIG_FILE..."
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

echo "$NC_AUTOCONFIG_FILE done!"

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
echo "Configure Nextcloud...."

echo "Sending init request to Nextcloud..."
curl "http://localhost:$NC_PORT"

cd $NC_DIR

#default start settings
sudo -u www-data php8.2 occ maintenance:repair --include-expensive
sudo -u www-data php8.2 occ db:add-missing-indices
sudo -u www-data php8.2 occ config:system:set maintenance_window_start --type=integer --value=1
sudo -u www-data php8.2 occ config:system:set default_phone_region --value="AT"

#chronjob
sudo -u www-data php8.2 occ background:cron
(echo "*/5  *  *  *  * php8.2 -f $NC_DIR/cron.php") | crontab -u www-data -

#setting memchache redis
sudo -u www-data php8.2 occ config:system:set memcache.local --type=string --value="\OC\Memcache\Redis"
sudo -u www-data php8.2 occ config:system:set memcache.locking --type=string --value="\OC\Memcache\Redis"
sudo -u www-data php8.2 occ config:system:set redis host --value=localhost
sudo -u www-data php8.2 occ config:system:set redis port --value=6379
sudo -u www-data php8.2 occ config:system:set redis dbindex --value=0
sudo -u www-data php8.2 occ config:system:set redis password --value=
sudo -u www-data php8.2 occ config:system:set redis timeout --value=1.5

#trusted domains
sudo -u www-data php8.2 occ config:system:set trusted_domains 0 --value=localhost
sudo -u www-data php8.2 occ config:system:set trusted_domains 1 --value=$NC_FQDN

# trusted proxies
if [ "$USE_REVERSE_PROXY" = "on" ]; then
    sudo -u www-data php8.2 occ config:system:set trusted_proxies 1 --value=$REVERSE_PROXY_IP
fi

#set E-Mail for NC
sudo -u www-data php8.2 occ config:system:set mail_from_address --value=$NC_FROM_EMAIL_ADDRESS
sudo -u www-data php8.2 occ config:system:set mail_smtpmode --value=smpt
sudo -u www-data php8.2 occ config:system:set mail_senmailmode --value=smpt
sudo -u www-data php8.2 occ config:system:set mail_domain --value=$NC_EMAIL_DOMAIN
sudo -u www-data php8.2 occ config:system:set mail_smpthost --value=$NC_SMPT_HOST
sudo -u www-data php8.2 occ config:system:set mail_smptport --value=$NC_SMPT_PORT
sudo -u www-data php8.2 occ config:system:set mail_smptauth --value=1
sudo -u www-data php8.2 occ config:system:set mail_smptname --value=$NC_EMAIL_ADDRESS
sudo -u www-data php8.2 occ config:system:set mail_smptpassword --value=$NC_EMAIL_PASSWORD


# theming
sudo -u www-data php8.2 occ theming:config name "$NC_NAME"
sudo -u www-data php8.2 occ theming:config slogan "$NC_SLOGAN"
sudo -u www-data php8.2 occ theming:config url "https://$NC_FQDN"


# installing default apps
sudo -u www-data php8.2 occ app:install calendar
sudo -u www-data php8.2 occ app:install contacts
sudo -u www-data php8.2 occ app:install mail
sudo -u www-data php8.2 occ app:install passwords
sudo -u www-data php8.2 occ app:install groupfolders

# memories app
sudo apt install -y ffmpeg > /dev/null 2>&1
sudo -u www-data php8.2 occ app:install memories
sudo -u www-data php8.2 occ app:install previewgenerator
sudo -u www-data php8.2 occ app:enable recognize

sudo -u www-data php8.2 occ config:system:set enabledPreviewProviders 0 --value=OC\\Preview\\Image
sudo -u www-data php8.2 occ config:system:set enabledPreviewProviders 1 --value=OC\\Preview\\HEIC
sudo -u www-data php8.2 occ config:system:set enabledPreviewProviders 2 --value=OC\\Preview\\TIFF
sudo -u www-data php8.2 occ config:system:set enabledPreviewProviders 3 --value=OC\\Preview\\Movie

sudo -u www-data php8.2 occ maintenance:repair --include-expensive
sudo -u www-data php8.2 occ memories:index --force 
sudo -u www-data php8.2 occ db:add-missing-indices


#disabled - takes to long for testing
# sudo -u www-data php8.2 occ memories:places-setup


# spreed = talk app
sudo -u www-data php8.2 occ app:install spreed

# onlyoffice
sudo -u www-data php8.2 occ app:install onlyoffice

echo "Finished configuring Nextcloud."
echo "Restart Apache..."
systemctl reload apache2.service
echo "Done restarting."
cd $STARTING_DIR

exit 0