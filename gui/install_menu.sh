#!/bin/bash

#define ENV_DIR and ENV_FILE for USER_INPUTs
ENV_DIR=$1
ENV_FILE=${ENV_DIR}/settings.txt
touch $ENV_FILE

# define Title Header
TITLE_TXT="[Nextcloud-Installer (c) Amak-AT]"


check_user_canceled(){
    # Check if the user canceled the input
    if [ $? -ne 0 ]; then
        echo "User canceled the input. Bye"
        exit 1
    fi
}

get_user_clear_input(){
    local env_variable=$1
    local prompt=$2
    local default_input=$3
    local user_input="$(whiptail --title "$TITLE_TXT" --inputbox "$prompt" 13 50 "$default_input" 3>&1 1>&2 2>&3)"

    check_user_canceled

    echo "$env_variable=$user_input" >> "$ENV_FILE"
}

if whiptail --title "$TITLE_TXT" \
--yes-button "Next" --no-button "Cancel" \
--yesno "Welcome to the Nextcloud installation Setup (c) Amak-AT!\n
In the following we will guide you to the installation process.\n \n\
Do you want to continue?" 13 50; \
then
    # User clicked Next
    whiptail --title "$TITLE_TEXT" --msgbox "First you have to choose between what configuration and parts you want to install. If you are not sure - select all and go through it." 13 50;

    # Define multipe-choice options
    OPTIONS=(
        1 "configure hostname" OFF
        2 "change network settings" OFF
        3 "installing dependencies" OFF
        4 "installing Nextcloud" OFF
    )

    # Show the multiple-choice dialog
    SELECTED_OPTIONS=$(whiptail --title "$TITLE_TEXT" --checklist \
    --notags "Select options:" 13 50 4 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

    check_user_canceled

    # Convert the selected options into an array
    SELECTED_OPTIONS=$(echo "$SELECTED_OPTIONS" | tr -d '"')
    IFS=' ' read -r -a selected_array <<< "$SELECTED_OPTIONS"

    # Process the selected options for ENV_FILE
    for option in "${selected_array[@]}"; do
        case $option in

            1)  CURRENT_HOSTNAME=$(hostname)
                get_user_clear_input "NEW_HOSTNAME" "Select a new hostname (current: $CURRENT_HOSTNAME):" $CURRENT_HOSTNAME
                ;;
            
            2)  ./gui/ip_setting.sh $ENV_FILE;;

            3) echo "You chose Option 3: installing dependencies";;
            4) echo "You chose Option 4: installing Nextcloud";;
            *) echo "unknown option: $option";;
        esac
    done

    # Process the selected options
    for option in "${selected_array[@]}"; do
        case $option in

            1) ./basic/hostname.sh $ENV_FILE;;
            
            2) ./basic/networksettings.sh $ENV_FILE;;

            3) ./dependencies/install_dependencies.sh ;;
            4) echo "You chose Option 4: installing Nextcloud";;
            *) echo "unknown option: $option";;
        esac
    done

else
    # User clicked Cancel
    echo "Bye Bye"
fi
