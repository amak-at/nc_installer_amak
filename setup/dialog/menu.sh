#!/bin/bash

source $1

CONF_FILE="$1"

INPUT=$TEMP_DIR/menu.sh.$$
OUTPUT=$TEMP_DIR/output.sh.$$

backtitle_txt="[Nextcloud-Installer (c) Amak-AT]"
declare -A nextcloud_settings
declare -A backup_settings

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

function display_output() {
    local height=${1-16}
    local width=${2-50}
    local title=${3-$backtitle_txt}

    dialog --backtitle ${backtitle_txt} \
    --title "${title}" \
    --msgbox "${msgbox}" --clear --msgbox "$(<$OUTPUT)" ${height} ${width}
}

function update_setup_conf() {
    local -n settings=$1
    # Update die setup.conf Datei mit den Werten aus dem assoziativen Array
    for key in "${!settings[@]}"; do
        sed -i "s|^$key=.*|$key=\"${settings[$key]}\"|" "$CONF_FILE"
    done
}

#show_msgbx  "Welcome to the Nextcloud installation Setup \(c\) Amak-AT! In the following we will guide you to the installation process." 16 50

function show_components(){
    exec 3>&1

    VALUES=$(dialog --clear --backtitle "$backtitle_txt" --title "[ C H O O S E -  C O M P O N E N T S ]" \
    --checklist "Choose the components to install / proceed" 25 50 4 \
    1 "change hostname" $CHANGE_HOSTNAME \
    2 "change network settings" $CHANGE_NETWORKSETTINGS \
    3 "install nextcloud" $INSTALL_NC \
    4 "install backup solution" $INSTALL_BACKUP \
    2>&1 1>&3)

    exec 3>&-

    sed -i "s|^CHANGE_HOSTNAME=.*|CHANGE_HOSTNAME=off|" "$CONF_FILE"
    sed -i "s|^CHANGE_NETWORKSETTINGS=.*|CHANGE_NETWORKSETTINGS=off|" "$CONF_FILE"
    sed -i "s|^INSTALL_NC=.*|INSTALL_NC=off|" "$CONF_FILE"
    sed -i "s|^INSTALL_BACKUP=.*|INSTALL_BACKUP=off|" "$CONF_FILE"

    if [ -n "$VALUES" ]; then
        for choice in $VALUES; do
            case $choice in
                1)sed -i "s|^CHANGE_HOSTNAME=.*|CHANGE_HOSTNAME=on|" "$CONF_FILE";;
                2)sed -i "s|^CHANGE_NETWORKSETTINGS=.*|CHANGE_NETWORKSETTINGS=on|" "$CONF_FILE";;
                3)sed -i "s|^INSTALL_NC=.*|INSTALL_NC=on|" "$CONF_FILE";;
                4)sed -i "s|^INSTALL_BACKUP=.*|INSTALL_BACKUP=on|" "$CONF_FILE";;
            esac
        done
    fi
    
    source $CONF_FILE 
}

function show_hostname_settings(){
    exec 3>&1

    hostname=$(dialog --backtitle "$backtitle_txt" \
                --cancel-label "Cancel" \
                --ok-label "Submit" \
                --title "[ H O S T N A M E]" \
                --inputbox "Insert your new hostname (current: ${CURRENT_HOSTNAME})" 8 60 ${NEW_HOSTNAME}\
                2>&1 1>&3)

    exec 3>&-

    sed -i "s|^NEW_HOSTNAME=.*|NEW_HOSTNAME=\"${hostname}\"|" "$CONF_FILE"
    source $CONF_FILE
}

function show_network_settings(){
    echo "test"
}

function show_nextcloud_settings(){
    exec 3>&1

    VALUES=$(dialog --ok-label "Submit" \
            --cancel-label "Cancel" \
            --backtitle "$backtitle_txt" \
            --title "[ N E X T C L O U D ]" \
            --form "Nextcloud settings"\
            20 60 0 \
            "Nextcloud Directories"         1 1     ""                          1 25 0 0 \
            "Base directory:"               2 1     "$NC_BASE"                  2 25 35 0 \
            "Data directory:"               3 1     "$NC_DATA_DIR"              3 25 35 0 \
            ""                              4 1     ""                          4 25 0 0 \
            "Nextcloud Database"            5 1     ""                          5 25 0 0 \
            "Database name:"                6 1     "$NC_DB_NAME"               6 25 35 0 \
            "Database user:"                7 1     "$NC_DB_USER"               7 25 35 0 \
            "Database password:"            8 1     "$NC_DB_PASS"               8 25 35 0 \
            ""                              9 1     ""                          9 25 0 0 \
            "Nextcloud Admin User"          10 1    ""                          10 25 0 0 \
            "Admin user:"                   11 1    "$NC_ADMIN_USER"            11 25 35 0 \
            "Admin password:"               12 1    "$NC_ADMIN_USER_PASS"       12 25 35 0 \
    2>&1 1>&3)

    exec 3>&-

    IFS=$'\n' read -d '' -r -a values_array <<< "$VALUES"

    nextcloud_settings=(
        [NC_BASE]="${values_array[0]}"
        [NC_DATA_DIR]="${values_array[1]}"
        [NC_DB_NAME]="${values_array[2]}"
        [NC_DB_USER]="${values_array[3]}"
        [NC_DB_PASS]="${values_array[4]}"
        [NC_ADMIN_USER]="${values_array[5]}"
        [NC_ADMIN_USER_PASS]="${values_array[6]}"
    )

    update_setup_conf nextcloud_settings
    source $CONF_FILE    
}

function show_backup_settings(){
    exec 3>&1

    VALUES=$(dialog --ok-label "Submit" \
            --cancel-label "Cancel" \
            --backtitle "$backtitle_txt" \
            --title "[ B A C K U P ]" \
            --form "Nextcloud settings"\
            20 60 0 \
            "Nextcloud Directories"         1 1    ""                           1 25 0 0  \
            "Destination directory:"        2 1    "$BACKUP_DIR"                2 25 35 0 \
            "Management directory:"         3 1    "$BACKUP_ROOT_DIR"           3 25 35 0 \
            ""                              4 1    ""                           4 25 0 0  \
            "Backup password:"              5 1    "$BACKUP_PASS"               5 25 35 0 \
            ""                              6 1    ""                           6 25 0 0  \
            "Timesettings for daily Backup" 7 1    ""                           7 25 0 0  \
            "Backup hour (0-23):"           8 1    "$BACKUP_TIME_HOUR"          8 25 35 0 \
            "Backup minute (0-59):"         9 1    "$BACKUP_TIME_MINUTE"        9 25 35 0 \
    2>&1 1>&3)

    exec 3>&-

    IFS=$'\n' read -d '' -r -a values_array <<< "$VALUES"

    backup_settings=(
        [BACKUP_DIR]="${values_array[0]}"
        [BACKUP_ROOT_DIR]="${values_array[1]}"
        [BACKUP_PASS]="${values_array[2]}"
        [BACKUP_TIME_HOUR]="${values_array[3]}"
        [BACKUP_TIME_MINUTE]="${values_array[4]}"
    )

    update_setup_conf backup_settings
    source $CONF_FILE 
}

function show_reset_settings(){
    echo "test"
}

while true
do
    ## display main menu ##
    dialog --clear --no-cancel --backtitle "$backtitle_txt" --title "[ M A I N  -  M E N U ]" \
    --menu "You can use the UP/DOWN arrow keys, the first \n\
    letter of the choice as a hot key, or the \n\
    number keys 1-9 to choose an option.\n\
    Choose the TASK" 25 50 4 \
    components "Choose components to install" \
    hostname "hostname settings" \
    network "network settings" \
    nextcloud "nextcloud settings" \
    backup "backup settings" \
    reset "reset settings" \
    Exit "Exit" 2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decision
    case $menuitem in
        components) show_components;;
        hostname) show_hostname_settings;;
        network) show_network_settings;;
        nextcloud) show_nextcloud_settings;;
        backup) show_backup_settings;;
        reset) show_reset_settings;;
        Exit) echo "Bye"; break;;
    esac

done

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT

exit 0