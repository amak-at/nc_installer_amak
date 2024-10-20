#!/bin/bash

# Define variables
CONF_FILE="/etc/apache2/sites-available/nextcloud.conf"
DOMAIN="cloud.amak.at"  # Replace with your actual domain

# Create new Apache configuration file for Nextcloud
echo "Creating Apache configuration file for Nextcloud..."

cat <<EOF > $CONF_FILE
<VirtualHost *:80>
    ServerAdmin master@localhost
    DocumentRoot /var/www/nextcloud
    #ServerName $DOMAIN

    <Directory /var/www/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        SetEnv HOME /var/www/nextcloud
        SetEnv HTTP_HOME /var/www/nextcloud
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined

    <IfModule mod_headers.c>
            Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
    </IfModule>

</VirtualHost>
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

# Restart Apache to apply changes
echo "Restarting Apache..."
systemctl restart apache2

echo "Nextcloud Apache configuration created successfully."

# prepare data folder
mkdir /home/data/
chown -R www-data:www-data /home/data/
chown -R www-data:www-data /var/www/nextcloud/
chmod -R 755 /var/www/nextcloud/

exit 0
