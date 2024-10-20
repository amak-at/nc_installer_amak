#!/bin/bash

# Download lastest nextcloud version
cd /tmp && wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
mv nextcloud /var/www/

# TODO define variables with user-input
DATA_DIR="/home/data"
NEXTCLOUD_DIR="/var/www/nextcloud/"
DB_NAME="nextcloud"
DB_USER="nextclouduser"
DB_PASS="asdf1234"
NC_ADMIN="nc-admin"
NC_ADMIN_PASS="nc-admin-pass"

mkdir $DATA_DIR
chown -R www-data:www-data $DATA_DIR
chown -R www-data:www-data $NEXTCLOUD_DIR
chmod -R 755 $NEXTCLOUD_DIR

#define autoconfig for skipping First setup Screen
AUTO_CONF_FILE="${NEXTCLOUD_DIR}/config/autoconfig.php"

cat <<EOF > $AUTO_CONF_FILE
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql",
  "dbname"        => "$DB_NAME",
  "dbuser"        => "$DB_USER",
  "dbpass"        => "$DB_PASS",
  "dbhost"        => "localhost",
  "dbtableprefix" => "",
  "adminlogin"    => "$NC_ADMIN",
  "adminpass"     => "$NC_ADMIN_PASS",
  "directory"     => "$DATA_DIR",
);
EOF

chown www-data:www-data $AUTO_CONF_FILE

exit 0