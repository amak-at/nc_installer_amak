#!/bin/bash
source $1

# Create the network configuration
# TODO change to default 50-cloud-init.yaml
cat <<EOF > /etc/netplan/01-nc-netcnfg.yaml

network:
    ethernets:
        $SELECTED_INTERFACE:
            addresses:
            - $NEW_IP_ADDR/$NEW_IP_SUBNET_PREFIX
            nameservers:
                addresses:
                - $NEW_IP_DNS1
                - $NEW_IP_DNS2
                search: []
            routes:
            -   to: default
                via: $NEW_IP_GATEWAY
    version: 2        
EOF

# Apply network settings
# TODO change to default 50-cloud-init.yaml
sudo chmod 600 /etc/netplan/01-nc-netcnfg.yaml
sudo netplan apply


echo "The IP address $NEW_IP_ADDR/$NEW_IP_SUBNET_PREFIX has been assigned to $SELECTED_INTERFACE."
echo "The DNS servers $NEW_IP_DNS1 and $NEW_IP_DNS2 have been configured."

exit 0