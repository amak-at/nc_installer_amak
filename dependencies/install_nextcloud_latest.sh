#!/bin/bash
source $1
# Download lastest nextcloud version
cd /tmp && wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
mv nextcloud $WWW_DIR/

# TODO define variables with user-input
NEXTCLOUD_DIR="$WWW_DIR/nextcloud/"
echo "NEXTCLOUD_DIR=$NEXTCLOUD_DIR" >> $1

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