#!/bin/bash
source $1

# Create new Apache configuration file for Nextcloud
echo "Creating Apache configuration file for Nextcloud..."

cat <<EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:$NC_PORT>
    ServerAdmin master@localhost
    DocumentRoot $WWW_DIR/nextcloud
    #ServerName $FQ_DOMAIN

    <Directory $WWW_DIR/nextcloud/>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        SetEnv HOME $WWW_DIR/nextcloud
        SetEnv HTTP_HOME $WWW_DIR/nextcloud
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

# Restart Apache to apply changes
echo "Restarting Apache..."
systemctl restart apache2

echo "Nextcloud Apache configuration created successfully."

exit 0
