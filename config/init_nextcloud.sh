#!/bin/bash
source $1
#curl http://$IP_ADDR:$NC_PORT

CURRENT_DIR=$(pwd)
CONFIG_PHP=$NEXTCLOUD_DIR/config/config.php

cd $NEXTCLOUD_DIR
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

(crontab -u www-data -l 2>/dev/null; echo "*/5  *  *  *  * php -f /var/www/nextcloud/cron.php") | crontab -u www-data -


systemctl reload apache2.service
cd $CURRENT_DIR
#echo "you can visit your nextcloud now unter http://${IP_ADDR}:${NC_PORT} with"
#echo "username: ${NC_ADMIN}"
#echo "passwort: ${NC_ADMIN_PASS}"

exit 0