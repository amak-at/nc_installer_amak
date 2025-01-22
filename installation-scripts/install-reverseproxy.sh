#!/bin/bash
source $1

mkdir /root/nginxproxymanager
cp $STARTING_DIR/setup/config/nginx-compose.yml /root/nginxproxymanager/docker-compose.yml
cd /root/nginxproxymanager
docker compose up -d
sleep 3

cd $STARTING_DIR

exit 0