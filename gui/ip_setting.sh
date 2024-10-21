#!/bin/bash

ENV_FILE=$1
source $ENV_FILE

check_user_canceled(){
    # Check if the user canceled the input
    if [ $? -ne 0 ]; then
        echo "User canceled the input. Bye"
        exit 1
    fi
}

#TODO Fix IP validation
is_valid_ip() {
    local ip=$1
    # Prüfe, ob die IP-Adresse dem Format x.x.x.x entspricht (jede Zahl 0-255).
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Stelle sicher, dass jede Zahl im gültigen Bereich liegt (0-255).
        for octet in $(echo "$ip" | tr '.' ' '); do
            if ((octet < 0 || octet > 255)); then
                echo "Invalid IP address: $ip"
                return 1
            fi
        done
        return 0
    else
        return 1
    fi
}

#TODO fix subnet validaition
is_valid_subnet_prefix() {
    local prefix=$1

    if [[ "$prefix" =~ ^[0-9]+$ ]] && [ "$prefix" -ge 0 ] && [ "$prefix" -le 32 ]; then
        return 0 # gültig
    else
        return 1 # ungültig
    fi
}

get_user_radio_input(){
    INTERFACE_OPTIONS=()
    while IFS= read -r line; do
        iface=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')
        INTERFACE_OPTIONS+=("$iface" "$iface: $ip" OFF)  # Interface und IP hinzufügen
    done < <(ip -o -f inet addr show | awk '{print $2, $4}' | grep -v lo)

    local -n radio_options=INTERFACE_OPTIONS

    local radio_option_count=$(( ${#radio_options[@]} / 3 ))

    local user_input="$(whiptail --title "$TITLE_TXT" --radiolist --notags \
    "Select an Interface" 13 50 $radio_option_count "${radio_options[@]}" 3>&1 1>&2 2>&3)"

    check_user_canceled

    echo "SELECTED_INTERFACE=$user_input" >> "$ENV_FILE"
}

get_user_subnet_input(){
    local env_variable="IP_SUBNET" 
    local prompt="Please enter the subnet prefix (e.g., 32 for /32, current: $CURRENT_SUBNET_PREFIX):" 
    local default_input=$CURRENT_SUBNET_PREFIX
    local user_input_prefix="$(whiptail --title "$TITLE_TXT" --inputbox "$prompt" 13 50 "$default_input" 3>&1 1>&2 2>&3)"

    #while true; do
    #     Überprüfe, ob das eingegebene Subnetzpräfix gültig ist
    #    if ! is_valid_subnet_prefix "$user_input_prefix"; then
    #        user_input_prefix="$(whiptail --title "$TITLE_TXT" --inputbox "Invalid subnet prefix. Please enter a number between 0 and 32." 13 50 "$user_input_prefix" 3>&1 1>&2)"
    #        check_user_canceled
    #        continue
    #    fi
    #    break # verlasse die Schleife, wenn das Subnetzpräfix gültig ist
    #done
    check_user_canceled

    echo "$env_variable=$user_input" >> "$ENV_FILE"
}

get_user_ip_input(){
    local env_variable="IP_ADDR"
    local prompt="Please enter the new IP address (e.g. 192.168.0.10, current: $CURRENT_IP):"
    local default_input=$CURRENT_IP
    local user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "$prompt" 13 50 "$default_input" 3>&1 1>&2 2>&3)"

    while true; do

        #if ! is_valid_ip "$user_input_ip"; then
        #    user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "Invalid IP address. Please enter a valid IP address." 13 50 "$user_input_ip" 3>&1 1>&2)"
        #    check_user_canceled
        #    continue # gehe zur nächsten Iteration der Schleife
        #fi

        if ping -c 1 -W 1 "$user_input_ip" &> /dev/null; then
            user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "The IP address $user_input_ip is already in use. Please choose another one." 13 50 "$user_input_ip" 3>&1 1>&2 2>&3)"
            check_user_canceled
        else
            break # exit while loop - IP address is available
        fi
    done

    check_user_canceled

    echo "$env_variable=$user_input_ip" >> "$ENV_FILE"
}

get_user_gateway_ip_input(){
    local env_variable="IP_GATEWAY" 
    local prompt="Please enter the gateway IP address (current: $CURRENT_GATEWAY):"
    local default_input=$CURRENT_GATEWAY
    local user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "$prompt" 13 50 "$default_input" 3>&1 1>&2 2>&3)"

    while true; do

        #if ! is_valid_ip "$user_input_ip"; then
        #    user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "Invalid IP address. Please enter a valid IP address." 13 50 "$user_input_ip" 3>&1 1>&2)"
        #    check_user_canceled
        #    continue # gehe zur nächsten Iteration der Schleife
        #fi

        if ping -c 1 -W 1 "$user_input_ip" &> /dev/null; then
            break # exit while loop - IP address is available
        else
            user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "The gateway IP address $user_input_ip is not reachable. Please choose another one." 13 50 "$user_input_ip" 3>&1 1>&2 2>&3)"
            check_user_canceled
        fi
    done

    check_user_canceled

    echo "$env_variable=$user_input_ip" >> "$ENV_FILE"
}

get_user_dns_ip(){
    local env_variable=$1
    local prompt=$2
    local default_input=$3
    local user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "$prompt" 13 50 "$default_input" 3>&1 1>&2 2>&3)"

    #while true; do
    #    if ! is_valid_ip "$user_input_ip"; then
    #        user_input_ip="$(whiptail --title "$TITLE_TXT" --inputbox "Invalid IP address. Please enter a valid IP address." 13 50 "$user_input_ip" 3>&1 1>&2)"
    #        check_user_canceled
    #    else
    #        break
    #    fi
    #done
    check_user_canceled

    echo "$env_variable=$user_input_ip" >> "$ENV_FILE"
}



get_user_radio_input

source "$ENV_FILE"
CURRENT_IP=$(ip -o -f inet addr show $SELECTED_INTERFACE | awk '{print $4}' | cut -d'/' -f1)
CURRENT_SUBNET_PREFIX=$(ip -o -f inet addr show ens18 | awk '{print $4}' | cut -d'/' -f2)
CURRENT_GATEWAY=$(ip route | grep "dev $SELECTED_INTERFACE" | awk '{print $3}' | head -n 1)

if whiptail --title "$TITLE_TXT" --yesno "Do you want to change the current IP-Address\
    (current: $CURRENT_IP/$CURRENT_SUBNET_PREFIX)?" 13 50; then
    # User wants to change IP
    get_user_ip_input
    get_user_subnet_input
else
    # User does not want to change IP
    echo "IP_ADDR=$CURRENT_IP" >> "$ENV_FILE"
    echo "IP_SUBNET=$CURRENT_SUBNET_PREFIX" >> "$ENV_FILE"
fi
    get_user_gateway_ip_input
    get_user_dns_ip "DNS1" "Please enter the primary DNS server:" "8.8.8.8"
    get_user_dns_ip "DNS2" "Please enter the secondary DNS server:" "1.1.1.1"

exit 0