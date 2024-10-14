# Display available network interfaces
echo "Available network interfaces:"
ip -o link show | awk -F': ' '{print $2}' | grep -v lo

# Ask for user input
read -p "Please enter the desired network interface: " INTERFACE

# Check if the interface exists
if ! ip link show "$INTERFACE" &> /dev/null; then
    echo "The interface '$INTERFACE' does not exist. Please try again."
    exit 1
fi

read -p "Please enter the new IP address: " NEW_IP
read -p "Please enter the subnet prefix (e.g., 24 for /24): " SUBNET_PREFIX

# Check if the IP address is available
if ping -c 1 -W 1 "$NEW_IP" &> /dev/null; then
  echo "The IP address $NEW_IP is already in use. Please choose another one."
  exit 1
else
  echo "The IP address $NEW_IP is available."
fi

# Ask for the gateway IP address
read -p "Please enter the gateway IP address: " GATEWAY_IP

# Ask for two DNS servers
read -p "Please enter the first DNS server: " DNS1
read -p "Please enter the second DNS server: " DNS2

# Add the hostname to /etc/hosts
if ! grep -q "$NEW_HOSTNAME" /etc/hosts; then
  echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
fi

# Create the network configuration
cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses: [$NEW_IP/$SUBNET_PREFIX]
      gateway4: $GATEWAY_IP
      nameservers:
        addresses: [$DNS1, $DNS2]
EOF

# Apply network settings
netplan apply


echo "The IP address $NEW_IP/$SUBNET_PREFIX has been assigned to $INTERFACE."
echo "The DNS servers $DNS1 and $DNS2 have been configured."

exit 0