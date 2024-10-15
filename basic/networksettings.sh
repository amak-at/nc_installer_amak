#!/bin/bash



# Ask for interface

while true; do
    # Display available network interfaces
    echo "Available network interfaces:"
    ip -o -f inet addr show | awk '{print $2, $4}' | grep -v lo
    
    read -p "Please enter the desired network interface: " INTERFACE

    # Check if the interface exists
    if ! ip link show "$INTERFACE" &> /dev/null; then
        echo "The interface '$INTERFACE' does not exist. Please try again."
    else
        break #correct selected interface
    fi
done
# get current IP address and subnetprefix
CURRENT_IP=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}' | cut -d'/' -f1)
CURRENT_SUBNET_PREFIX=$(ip -o -f inet addr show ens18 | awk '{print $4}' | cut -d'/' -f2)


# Ask if IP address should be changed
read -p "Do you want to change the IP address for interface $INTERFACE? Current: $CURRENT_IP (y/n): " CHANGE_IP

if [[ "$CHANGE_IP" != "y" && "$CHANGE_IP" != "Y" ]]; then
    echo "No changes made. Exiting."
    exit 0
fi

while true; do
    # Prompt for the new IP address
    read -p "Please enter the new IP address (e.g. 192.168.0.10, current: $CURRENT_IP): " NEW_IP

    # Prompt for the subnet prefix
    read -rep "Please enter the subnet prefix (e.g., 32 for /32, current: $CURRENT_SUBNET_PREFIX): " -i "$CURRENT_SUBNET_PREFIX" SUBNET_PREFIX

    # check if new ip is equal to current ip
    if [[ "$NEW_IP" == "$CURRENT_IP" ]]; then
        echo "The new IP address is the same as the current IP address."
        break  # Exit the loop if the new IP address is the same
    else
        echo "hello"
    fi

    # Check if new IP address is available
    echo "Checking if new IP address is available..."

    if ping -c 1 -W 1 "$NEW_IP" &> /dev/null; then
        echo "The IP address $NEW_IP is already in use. Please choose another one."
    else
        echo "The IP address $NEW_IP is available."
        break  # Exit the loop if the IP address is available
    fi
done

# Ask for the gateway IP address
CURRENT_GATEWAY=$(ip route | grep "dev $INTERFACE" | awk '{print $3}' | head -n 1)
read -rep "Please enter the gateway IP address (current: $CURRENT_GATEWAY): " -i "$CURRENT_GATEWAY" GATEWAY_IP

# Check if the Gateway address is reachable
echo "Checking if gateway IP address is reachable..."

if ping -c 1 -W 1 "$GATEWAY_IP" &> /dev/null; then
  echo "Gateway with the IP $GATEWAY_IP is reachable."
else
  echo "The gateway IP address $GATEWAY_IP is not reachable. Please choose another one."
  exit 1
fi

# Ask for two DNS servers
read -p "Please enter the first DNS server: " DNS1
read -p "Please enter the second DNS server: " DNS2



# Create the network configuration
# TODO change to default 50-cloud-init.yaml
cat <<EOF > /etc/netplan/01-nc-netcnfg.yaml

network:
    ethernets:
        $INTERFACE:
            addresses:
            - $NEW_IP/$SUBNET_PREFIX
            nameservers:
                addresses:
                - $DNS1
                - $DNS2
                search: []
            routes:
            -   to: default
                via: $GATEWAY_IP
    version: 2        
EOF

# Apply network settings
# TODO change to default 50-cloud-init.yaml
sudo chmod 600 /etc/netplan/01-nc-netcnfg.yaml
sudo netplan apply


echo "The IP address $NEW_IP/$SUBNET_PREFIX has been assigned to $INTERFACE."
echo "The DNS servers $DNS1 and $DNS2 have been configured."

exit 0