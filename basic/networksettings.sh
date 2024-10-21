#!/bin/bash
source $1

# Create the network configuration
# TODO change to default 50-cloud-init.yaml
cat <<EOF > /etc/netplan/01-nc-netcnfg.yaml

network:
    ethernets:
        $SELECTED_INTERFACE:
            addresses:
            - $IP_ADDR/$IP_SUBNET
            nameservers:
                addresses:
                - $DNS1
                - $DNS2
                search: []
            routes:
            -   to: default
                via: $IP_GATEWAY
    version: 2        
EOF

# Apply network settings
# TODO change to default 50-cloud-init.yaml
sudo chmod 600 /etc/netplan/01-nc-netcnfg.yaml
sudo netplan apply


echo "The IP address $IP_ADDR/$IP_SUBNET has been assigned to $INTERFACE."
echo "The DNS servers $DNS1 and $DNS2 have been configured."

exit 0