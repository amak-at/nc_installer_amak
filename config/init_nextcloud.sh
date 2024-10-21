#!/bin/bash
source $1
curl http://$IP_ADDR:$NC_PORT

echo "you can visit your nextcloud now unter http://${IP_ADDR}:${NC_PORT} with"
echo "username: ${NC_ADMIN}"
echo "passwort: ${NC_ADMIN_PASS}"

exit 0