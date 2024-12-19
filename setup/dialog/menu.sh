#!/bin/bash

source $1

CONF_FILE="$1"

INPUT=$TEMP_DIR/menu.sh.$$
OUTPUT=$TEMP_DIR/output.sh.$$

backtitle_txt="[ Nextcloud-Installer (c) Amak-AT ]"
declare -A nextcloud_settings
declare -A nextcloud_mail_settings

declare -A backup_settings

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

function welcome_screen() {
    dialog --backtitle "$backtitle_txt" \
        --title "Willkommen!" \
        --yes-label "Weiter" \
        --msgbox "Willkommen beim Nextcloud-Installer von Amak-AT. \
        In den folgenden Schritten werden Sie durch die Installtion geleitet. Wollen Sie beginnen?" 15 50

}

function update_setup_conf() {
    local -n settings=$1
    # Update die setup.conf Datei mit den Werten aus dem assoziativen Array
    for key in "${!settings[@]}"; do
        sed -i "s|^$key=.*|$key=\"${settings[$key]}\"|" "$CONF_FILE"
    done
}

function show_hostname_settings(){
    exec 3>&1

    hostname=$(dialog --backtitle "$backtitle_txt" \
                --no-cancel \
                --ok-label "Anwenden" \
                --title "[ Gerätenamen wechseln ]" \
                --inputbox "Geben sie Ihren neuen Gerätenamen ein (aktuell: ${CURRENT_HOSTNAME})" 8 60 ${NEW_HOSTNAME}\
                2>&1 1>&3)

    exec 3>&-

    if [ "$hostname" != "$CURRENT_HOSTNAME" ]; then
        sed -i "s|^NEW_HOSTNAME=.*|NEW_HOSTNAME=\"${hostname}\"|" "$CONF_FILE"
        sed -i "s|^CHANGE_HOSTNAME=.*|CHANGE_HOSTNAME=on|" "$CONF_FILE"
    fi

    source $CONF_FILE
}

function show_network_settings(){
    exec 3>&1

    interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | awk '{print $1}'))
    
    menu_items=()
    for iface in "${interfaces[@]}"; do
        menu_items+=("$iface" "")
    done

    selected_iface=$(dialog --backtitle "$backtitle_txt" \
        --title "[ NETZWERK ]" --no-cancel \
        --menu "Wählen Sie ein Interface aus:" 15 25 6 "${menu_items[@]}" 2>&1 1>&3)

    sed -i "s|^SELECTED_INTERFACE=.*|SELECTED_INTERFACE=\"${selected_iface}\"|" "$CONF_FILE"

    source $CONF_FILE

    new_ip=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NETZWERK ]" --no-cancel \
    --inputbox "Geben Sie die neue IP-Adresse ein (aktuell: $CURRENT_IP):" 10 50 ${CURRENT_IP} 2>&1 1>&3)

    if [ "$new_ip" != "$NEW_IP_ADDR" ]; then
        sed -i "s|^NEW_IP_ADDR=.*|NEW_IP_ADDR=\"${new_ip}\"|" "$CONF_FILE"
        sed -i "s|^CHANGE_NETWORKSETTINGS=.*|CHANGE_NETWORKSETTINGS=on|" "$CONF_FILE"
    fi

    new_subnetprefix=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NETZWERK ]" --no-cancel \
    --inputbox "Geben Sie die Subnetprefix ein (aktuell: $CURRENT_IP_SUBNET_PREFIX):" 10 50 ${CURRENT_IP_SUBNET_PREFIX} 2>&1 1>&3)


    if [ "$new_subnetprefix" != "$NEW_IP_SUBNET_PREFIX" ]; then
        sed -i "s|^NEW_IP_SUBNET_PREFIX=.*|NEW_IP_SUBNET_PREFIX=\"${new_subnetprefix}\"|" "$CONF_FILE"
        sed -i "s|^CHANGE_NETWORKSETTINGS=.*|CHANGE_NETWORKSETTINGS=on|" "$CONF_FILE"
    fi

    new_gateway=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NETZWERK ]" --no-cancel \
    --inputbox "Geben Sie das Gateway ein (aktuell: $CURRENT_IP_GATEWAY):" 10 50 ${CURRENT_IP_GATEWAY} 2>&1 1>&3)

    if [ "$new_gateway" != "$NEW_IP_GATEWAY" ]; then
        sed -i "s|^NEW_IP_GATEWAY=.*|NEW_IP_GATEWAY=\"${new_gateway}\"|" "$CONF_FILE"
        sed -i "s|^CHANGE_NETWORKSETTINGS=.*|CHANGE_NETWORKSETTINGS=on|" "$CONF_FILE"
    fi

    source $CONF_FILE
    if [ "$CHANGE_NETWORKSETTINGS" == "on" ]; then
        new_dns1=$(dialog --backtitle "$backtitle_txt" \
        --title "[ NETZWERK ]" --no-cancel \
        --inputbox "Geben Sie das Gateway ein (default: $NEW_IP_DNS1):" 10 50 ${NEW_IP_DNS1} 2>&1 1>&3)

        sed -i "s|^NEW_IP_DNS1=.*|NEW_IP_DNS1=\"${new_dns1}\"|" "$CONF_FILE"

        new_dns2=$(dialog --backtitle "$backtitle_txt" \
        --title "[ NETZWERK ]" --no-cancel \
        --inputbox "Geben Sie das Gateway ein (default: $NEW_IP_DNS2):" 10 50 ${NEW_IP_DNS2} 2>&1 1>&3)

        sed -i "s|^NEW_IP_DNS2=.*|NEW_IP_DNS2=\"${new_dns2}\"|" "$CONF_FILE"
    fi

    exec 3>&-
}

function show_nextcloud_settings(){
    exec 3>&1

    dialog --backtitle "$backtitle_txt" \
        --title "[ NEXTCLOUD KONFIGURIEREN ]" \
        --yes-label "Weiter" \
        --msgbox "Als erstes wähle ein Installationsort für deine Nextcloud aus. \nEs wird \"/var/www\" empfohlen." 10 50

    base_dir=$(dialog --backtitle "$backtitle_txt" \
        --title "[ NEXTCLOUD Installationsverzeichnis ]" \
        --nocancel \
        --dselect "$NC_BASE" 10 50 \
        2>&1 1>&3)

    sed -i "s|^NC_BASE=.*|NC_BASE=\"${base_dir}\"|" "$CONF_FILE"

    dialog --backtitle "$backtitle_txt" \
        --title "[ NEXTCLOUD KONFIGURIEREN ]" \
        --yes-label "Weiter" \
        --msgbox "Als nächstes wähle den Ordner für deine Nextcloud Datein aus. \nEs wird ein Pfad empfohlen, welcher möglichst viel Speicherplatz bietet. \nZum Beispiel: \"/mnt/sdb/data\". \nEin nicht vorhandener Ordner wird später automatisch erstellt." 15 50

    data_dir=$(dialog --backtitle "$backtitle_txt" \
        --title "[ NEXTCLOUD Installationsverzeichnis ]" \
        --nocancel \
        --dselect "$NC_DATA_DIR" 10 50 \
        2>&1 1>&3)

    sed -i "s|^NC_DATA_DIR=.*|NC_DATA_DIR=\"${data_dir}\"|" "$CONF_FILE"

    new_nc_name=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NEXTCLOUD Name ]" --no-cancel \
    --inputbox "Wie soll deine Nextcloud heißen? (standard: $NC_NAME):" 10 50 ${NC_NAME} 2>&1 1>&3)

    if [ "$new_nc_name" != "$NC_NAME" ]; then
        sed -i "s|^NC_NAME=.*|NC_NAME=\"${new_nc_name}\"|" "$CONF_FILE"
        sed -i "s|^NC_ADAPT_THEMING=.*|NC_ADAPT_THEMING=on|" "$CONF_FILE"
    fi

    new_nc_slogan=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NEXTCLOUD Name ]" --no-cancel \
    --inputbox "Welchen Slogan möchtest du deiner Nextcloud geben?" 10 50 ${NC_SLOGAN} 2>&1 1>&3)

    if [ "$new_nc_slogan" != "$NC_SLOGAN" ]; then
        sed -i "s|^NC_SLOGAN=.*|NC_SLOGAN=\"${new_nc_slogan}\"|" "$CONF_FILE"
        sed -i "s|^NC_ADAPT_THEMING=.*|NC_ADAPT_THEMING=on|" "$CONF_FILE"
    fi

    new_fqdn_port=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NEXTCLOUD Domainname ]" --no-cancel \
    --inputbox "Unter welchen vollen Domainnamen soll deine Nextcloud erreichbar sein?" 10 50 "nextcloud.meinedomain.com" 2>&1 1>&3)

    sed -i "s|^NC_FQDN=.*|NC_FQDN=\"${new_fqdn_port}\"|" "$CONF_FILE"

    new_nc_port=$(dialog --backtitle "$backtitle_txt" \
    --title "[ NEXTCLOUD Port ]" --no-cancel \
    --inputbox "Unter welchen Port soll deine Nextcloud erreichbar sein?" 10 50 ${NC_PORT} 2>&1 1>&3)

    sed -i "s|^NC_PORT=.*|NC_PORT=\"${new_nc_port}\"|" "$CONF_FILE"


    dialog --backtitle "$backtitle_txt" \
    --title "[ NEXTCLOUD E-Mail ]" \
    --yesno "Möchtest du deiner Nextcloud einen E-Mail Account zuweisen?" 10 30

    activate_mail=$?

    if [ $activate_mail == 0 ]; then
        mail_settings=$(dialog --ok-label "Anwenden" \
                --nocancel \
                --backtitle "$backtitle_txt" \
                --title "[ NEXTCLOUD E-Mail Einstellungen ]" \
                --form "Mit dieser E-Mail kommuniziert deine Nextcloud."\
                20 60 0 \
                "SMPT Host"               2 1     "$NC_SMPT_HOST"                  2 25 35 0 \
                "SMPT Port (std: 465)"               3 1     "$NC_SMPT_PORT"              3 25 35 0 \
                ""                              4 1     ""                          4 25 0 0 \
                "E-Mail Domain"            5 1     "$NC_EMAIL_DOMAIN"                          5 25 35 0 \
                "E-Mail Adresse"                6 1     "$NC_FROM_EMAIL_ADDRESS"               6 25 35 0 \
                "E-Mail Passwort"                7 1     "$NC_EMAIL_PASSWORD"               7 25 35 0 \
                "Hinweis: adresse@domain"            8 1     ""               8 25 0 0 \
        2>&1 1>&3)

        IFS=$'\n' read -d '' -r -a values_array <<< "$mail_settings"

        nextcloud_mail_settings=(
            [NC_SMPT_HOST]="${values_array[0]}"
            [NC_SMPT_PORT]="${values_array[1]}"
            [NC_EMAIL_DOMAIN]="${values_array[2]}"
            [NC_FROM_EMAIL_ADDRESS]="${values_array[3]}"
            [NC_EMAIL_PASSWORD]="${values_array[4]}"
        )
        update_setup_conf nextcloud_mail_settings
        sed -i "s|^NC_SETUP_EMAIL=.*|NC_SETUP_EMAIL=on|" "$CONF_FILE"
    else
        sed -i "s|^NC_SETUP_EMAIL=.*|NC_SETUP_EMAIL=off|" "$CONF_FILE"
    fi


    VALUES=$(dialog --ok-label "Anwenden" \
            --nocancel \
            --backtitle "$backtitle_txt" \
            --title "[ NEXTCLOUD Benutzer ]" \
            --form "Benutzereinstellungen für deine Nextcloud"\
            20 60 0 \
            "Nextcloud Datenbank"            1 1     ""                          1 25 0 0 \
            "Datenbankname:"                2 1     "$NC_DB_NAME"               2 25 35 0 \
            "Benutzer:"                3 1     "$NC_DB_USER"               3 25 35 0 \
            "Passwort:"            4 1     "$NC_DB_PASS"               4 25 35 0 \
            ""                              5 1     ""                          5 25 0 0 \
            "Nextcloud Admin"          6 1    ""                          6 25 0 0 \
            "Benutzername:"                   7 1    "$NC_ADMIN_USER"            7 25 35 0 \
            "Passwort:"               8 1    "$NC_ADMIN_USER_PASS"       8 25 35 0 \
    2>&1 1>&3)


    IFS=$'\n' read -d '' -r -a values_array <<< "$VALUES"

    nextcloud_settings=(
        [NC_DB_NAME]="${values_array[0]}"
        [NC_DB_USER]="${values_array[1]}"
        [NC_DB_PASS]="${values_array[2]}"
        [NC_ADMIN_USER]="${values_array[3]}"
        [NC_ADMIN_USER_PASS]="${values_array[4]}"
    )

    update_setup_conf nextcloud_settings


    dialog --backtitle "$backtitle_txt" \
    --title "[ NEXTCLOUD Standard-Apps ]" \
    --yesno "Möchtest du Standard-Apps gleich mit installieren (empfohlen)?" 10 50

    install_apps=$?

    if [ $install_apps == 0 ]; then
        sed -i "s|^INSTALL_DEFAULT_APPS=.*|INSTALL_DEFAULT_APPS=on|" "$CONF_FILE"

        choices=$(dialog --ok-label "Anwenden" \
            --nocancel \
            --backtitle "$backtitle_txt" \
            --title "[ NEXTCLOUD Benutzer ]" \
            --checklist "Welche Apps möchtest du installieren?\nMit [Space] an- und abwählen." 20 55 8 \
            1 "Kalender" on \
            2 "Kontaktverwaltung" on \
            3 "Web-Mail" on \
            4 "Passwortsafe" on \
            5 "Fotoverwaltung (wie Google Fotos)" on \
            6 "Text-, Video- und Sprachchat" on \
            7 "Dokumenten Editor (wie Microsoft Office)" on \
            8 "Gruppenordner Verwaltung" on \
            2>&1 1>&3)

            for choice in $choices; do
                case $choice in
                    1) sed -i "s|^INSTALL_CALENDAR=.*|INSTALL_CALENDAR=on|" "$CONF_FILE" ;;
                    2) sed -i "s|^INSTALL_CONTACTS=.*|INSTALL_CONTACTS=on|" "$CONF_FILE" ;;
                    3) sed -i "s|^INSTALL_MAIL=.*|INSTALL_MAIL=on|" "$CONF_FILE" ;;
                    4) sed -i "s|^INSTALL_PASSWORDS=.*|INSTALL_PASSWORDS=on|" "$CONF_FILE" ;;
                    5) sed -i "s|^INSTALL_MEMORIES=.*|INSTALL_MEMORIES=on|" "$CONF_FILE" ;;
                    6) sed -i "s|^INSTALL_TALK=.*|INSTALL_TALK=on|" "$CONF_FILE" ;;
                    7) sed -i "s|^INSTALL_ONLYOFFICE=.*|INSTALL_ONLYOFFICE=on|" "$CONF_FILE" ;;
                    8) sed -i "s|^ISNTALL_GROUPFOLDERS=.*|ISNTALL_GROUPFOLDERS=on|" "$CONF_FILE" ;;
                esac
            done
    fi

    exec 3>&-

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

welcome_screen

while true
do
    ## display main menu ##
    dialog --clear --no-cancel --backtitle "$backtitle_txt" --title "[ HAUPTMENU ]" \
    --menu "Wählen Sie etwas aus..." 15 50 4 \
    "Festplatten" "Festplatten verwalten" \
    "Gerätenamen" "Gerätenamen wechseln" \
    "Netzwerk" "Netzwerk einstellen" \
    "Nextcloud" "Nextcloud konfigurieren" \
    "Backup" "Backup einrichten" \
    "Zurücksetzen" "Einstellungen zurücksetzen" \
    "Verlassen" "Installtion beenden" 2>"${INPUT}"

    menuitem=$(<"${INPUT}")

    # make decision
    case $menuitem in
        Festplatten )
         ;;
        Gerätenamen )
         show_hostname_settings;;
        Netzwerk )
         show_network_settings;;
        Nextcloud )
         show_nextcloud_settings;;
        Backup )
         show_backup_settings;;
        Zurücksetzen )
         show_reset_settings;;
        Verlassen )
         echo "bye"; break;;
        *)
         echo "Bye"; break;;
    esac

done

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT

exit 0