#!/bin/bash
source $1

cd $TEMP_DIR
wget https://download.onlyoffice.com/docs/docs-install.sh
bash docs-install.sh -dp $OF_PORT <<EOF
y
EOF
sleep 5
docker exec onlyoffice-document-server sudo documentserver-jwt-status.sh > ./JWT.txt

OF_JWT=$(grep "JWT secret" JWT.txt | awk -F ' -  ' '{print $2}')

sed -i "s|^OF_JWT=.*|OF_JWT=$OF_JWT|" "$1"

exit 0