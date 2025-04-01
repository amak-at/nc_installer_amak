#!/bin/bash
source $1
NC_OCC="sudo -u www-data php ${NC_DIR}/occ"

# Secure MariaDB Installation
#echo "Securing MariaDB installation..."
#mysql_secure_installation <<EOF
#
#y
#n
#y
#y
#y
#y
#EOF

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
PHP_CONFIG_FILE="/etc/php/8.3/apache2/php.ini"

# Get the system's current timezone
OS_TIMEZONE=$(timedatectl show --property=Timezone --value)

# Definiere die Einstellungen als assoziatives Array
declare -A SETTINGS=(
    ["memory_limit"]="8192M"
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

cd $TEMP_DIR && wget https://download.nextcloud.com/server/releases/latest.zip
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
    # ServerAdmin master@localhost
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

#default start settings
$NC_OCC maintenance:repair --include-expensive
$NC_OCC db:add-missing-indices
$NC_OCC config:system:set maintenance_window_start --type=integer --value=1
$NC_OCC config:system:set default_phone_region --value="AT"

#chronjob
$NC_OCC background:cron
(echo "*/5  *  *  *  * php8.2 -f $NC_DIR/cron.php") | crontab -u www-data -

#setting memchache redis
$NC_OCC config:system:set memcache.local --type=string --value="\OC\Memcache\Redis"
$NC_OCC config:system:set memcache.locking --type=string --value="\OC\Memcache\Redis"
$NC_OCC config:system:set redis host --value=localhost
$NC_OCC config:system:set redis port --value=6379
$NC_OCC config:system:set redis dbindex --value=0
$NC_OCC config:system:set redis password --value=
$NC_OCC config:system:set redis timeout --value=1.5

#trusted domains
$NC_OCC config:system:set trusted_domains 0 --value=localhost
$NC_OCC config:system:set trusted_domains 1 --value=$NC_FQDN
$NC_OCC config:system:set trusted_domains 2 --value=192.168.0.*


# trusted proxies
if [ "$USE_REVERSE_PROXY" = "on" ]; then
    $NC_OCC config:system:set trusted_proxies 1 --value=$REVERSE_PROXY_IP
fi

#set E-Mail for NC
    if [ "$NC_SETUP_EMAIL" = "on" ]; then
    $NC_OCC config:system:set mail_from_address --value=$NC_FROM_EMAIL_ADDRESS
    $NC_OCC config:system:set mail_smtpmode --value=smpt
    $NC_OCC config:system:set mail_senmailmode --value=smpt
    $NC_OCC config:system:set mail_domain --value=$NC_EMAIL_DOMAIN
    $NC_OCC config:system:set mail_smpthost --value=$NC_SMPT_HOST
    $NC_OCC config:system:set mail_smptport --value=$NC_SMPT_PORT
    $NC_OCC config:system:set mail_smptauth --value=1
    $NC_OCC config:system:set mail_smptname --value=$NC_EMAIL_ADDRESS
    $NC_OCC config:system:set mail_smptpassword --value=$NC_EMAIL_PASSWORD
fi

# theming
if [ "$NC_ADAPT_THEMING" = "on" ]; then
    $NC_OCC theming:config name "$NC_NAME"
    $NC_OCC theming:config slogan "$NC_SLOGAN"
    $NC_OCC theming:config url "https://$NC_FQDN"
fi

# installing default apps
if [ "$INSTALL_DEFAULT_APPS" = "on" ]; then
    if [ "$INSTALL_CALENDAR" = "on" ]; then
        $NC_OCC app:install calendar
    fi

    if [ "$INSTALL_CONTACTS" = "on" ]; then
        $NC_OCC app:install contacts
    fi

    if [ "$INSTALL_MAIL" = "on" ]; then
        $NC_OCC app:install mail
    fi

    if [ "$INSTALL_PASSWORDS" = "on" ]; then
        $NC_OCC app:install passwords
    fi

    if [ "$INSTALL_GROUPFOLDERS" = "on" ]; then
        $NC_OCC app:install groupfolders
    fi

    # memories app
    if [ "$INSTALL_MEMORIES" = "on" ]; then
        $NC_OCC app:install memories
        $NC_OCC app:install previewgenerator
        $NC_OCC app:enable recognize

        $NC_OCC config:system:set enabledPreviewProviders 0 --value=OC\\Preview\\Image
        $NC_OCC config:system:set enabledPreviewProviders 1 --value=OC\\Preview\\HEIC
        $NC_OCC config:system:set enabledPreviewProviders 2 --value=OC\\Preview\\TIFF
        $NC_OCC config:system:set enabledPreviewProviders 3 --value=OC\\Preview\\Movie

        $NC_OCC memories:index --force 
        $NC_OCC db:add-missing-indices

        #disabled - takes to long for testing
        # $NC_OCC memories:places-setup
    fi

    # spreed = talk app
    if [ "$INSTALL_TALK" = "on" ]; then
        $NC_OCC app:install spreed
    fi

    if [ "$INSTALL_ONLYOFFICE" = "on" ]; then
        # onlyoffice
        $NC_OCC app:install onlyoffice
        $NC_OCC config:app:set onlyoffice DocumentServerUrl --value=http://localhost:$OF_PORT
        # $NC_OCC config:app:set onlyoffice DocumentServerUrl --value=https://$OF_FQDN
        $NC_OCC config:app:set onlyoffice jwt_secret --value=$OF_JWT
        $NC_OCC config:system:set onlyoffice wt_secret --value=$OF_JWT
        $NC_OCC config:system:set onlyoffice jwt_header --value=Authorization
    fi
fi

$NC_OCC maintenance:repair --include-expensive
$NC_OCC db:add-missing-indices

echo "Finished configuring Nextcloud."
echo "Restart Apache..."
systemctl reload apache2.service
echo "Done restarting."

echo "removing first nextloud.log"
rm $NC_DATA_DIR/nextcloud.log
echo "removing done.."

cd $STARTING_DIR

exit 0
