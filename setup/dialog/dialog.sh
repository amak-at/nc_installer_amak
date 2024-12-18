#!/bin/bash

source $1

CONF_FILE="$1"

INPUT=$TEMP_DIR/menu.sh.$$
OUTPUT=$TEMP_DIR/output.sh.$$

backtitle_txt="[ Nextcloud-Installer by Amak-AT ]"
declare -A nextcloud_settings
declare -A backup_settings

#trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM


# init stepcounter
current_step=1

function welcome_screen() {
    dialog --backtitle "$backtitle_txt" \
        --title "Willkommen!" \
        --yes-label "Weiter" \
        --no-label "Beenden" \
        --yesno "Willkommen beim Nextcloud-Installer von Amak-AT. In den folgenden Schritten werden Sie durch die Installtion geleitet. Wollen Sie beginnen?" 15 50


    if [ $? -ne 0 ]; then
        exit 0
    fi
    #skip step 2 (disk mounting)  
    current_step=3
}

function disk_management() {
  # Liste der Platten abrufen
  disks=$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep -E 'disk|part' | awk '{print $1 " " $2}')
  
  # Auswahlmenü für Platten
  selected_disk=$(dialog --title "Festplatten-Verwaltung" \
    --menu "Wähle eine Platte aus, um sie zu verwalten:" 20 50 10 $disks 2>&1 >/dev/tty)

  if [ $? -ne 0 ]; then
    current_step=1
    return
  fi

  # Optionen für die ausgewählte Platte anzeigen
  action=$(dialog --title "Aktion auswählen" \
    --menu "Was möchten Sie mit $selected_disk machen?" 15 50 5 \
    1 "Einbinden" \
    2 "Formatieren (EXT4)" \
    3 "Automatisches Mounten einstellen" 2>&1 >/dev/tty)

  case $action in
    1) # Einbinden
      mount_point=$(dialog --inputbox "Geben Sie den Mount-Pfad ein (z. B. /mnt/disk):" 10 50 2>&1 >/dev/tty)
      mkdir -p "$mount_point"
      mount "/dev/$selected_disk" "$mount_point"
      dialog --msgbox "Festplatte wurde in $mount_point eingebunden." 10 50
      ;;
    2) # Formatieren
      mkfs.ext4 "/dev/$selected_disk"
      dialog --msgbox "Festplatte wurde als EXT4 formatiert." 10 50
      ;;
    3) # Automatisches Mounten
      mount_point=$(dialog --inputbox "Geben Sie den Mount-Pfad ein (z. B. /mnt/disk):" 10 50 2>&1 >/dev/tty)
      mkdir -p "$mount_point"
      echo "/dev/$selected_disk $mount_point ext4 defaults 0 0" >> /etc/fstab
      dialog --msgbox "Automatisches Mounten wurde eingerichtet." 10 50
      ;;
  esac
  current_step=3
}

function change_hostname() {

  set +e

  dialog --backtitle "$backtitle_txt" \
    --title "Hostname ändern" \
    --yes-label "Ja" \
    --no-label "Zurück" \
    --extra-button --extra-label "Nein"\
    --yesno "Wollen Sie den Hostnamen (derzeitig $CURRENT_HOSTNAME) ändern?" 10 50

  choice=$?

  set -e

  case $choice in
    0) # Ja wurde gedrückt
        hostname=$(dialog --backtitle "$backtitle_txt" \
            --title "Hostname ändern" \
            --no-cancel \
            --inputbox "Geben Sie den neuen Hostnamen ein:" 10 50 "$CURRENT_HOSTNAME" 2>&1 >/dev/tty )

        if [ "$hostname" != "$CURRENT_HOSTNAME" ]; then
            sed -i "s|^NEW_HOSTNAME=.*|NEW_HOSTNAME=\"${hostname}\"|" "$CONF_FILE"
            sed -i "s|^CHANGE_HOSTNAME=.*|CHANGE_HOSTNAME=on|" "$CONF_FILE"
        fi
        current_step=4
    ;;
    1) #zurück wurde gedrückt
        current_step=1
    ;;
    3) # nein wurde gedrückt
        current_step=4
    ;;
  esac
}

function change_ip_address() {
  interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | awk '{print $1}' | tr '\n' ' ')
  
  selected_interface=$(dialog --title "Netzwerk-Schnittstellen" \
    --menu "Wählen Sie ein Interface aus:" 15 50 5 $interfaces 2>&1 >/dev/tty)

  if [ $? -ne 0 ]; then
    current_step=3 # Zurück zum Hostnamen ändern
    return
  fi

  new_ip=$(dialog --inputbox "Geben Sie die neue IP-Adresse ein (z. B. 192.168.1.100):" 10 50 2>&1 >/dev/tty)
  new_gateway=$(dialog --inputbox "Geben Sie das Gateway ein (z. B. 192.168.1.1):" 10 50 2>&1 >/dev/tty)

  dialog --msgbox "Die IP-Adresse wurde auf $new_ip und das Gateway auf $new_gateway geändert." 10 50 \
    --and-widget \
    --yes-label "Fertig" \
    --no-label "Zurück"

  if [ $? -ne 0 ]; then
    current_step=3 # Zurück zum Hostnamen ändern
  else
    current_step=5 # Abschluss
  fi
}

function process_flow() {
  while true; do
    case $current_step in
      1) welcome_screen ;;
      2) disk_management ;;
      3) change_hostname ;;
      4) change_ip_address ;;
      5)
        dialog --title "Abschluss" \
          --msgbox "Alle Schritte sind abgeschlossen. Vielen Dank!" 10 50
        break
        ;;
      *)
        echo "DEBUG: Unbekannter Zustand im Prozessfluss: $current_step" >> debug.log
        break
        ;;
    esac
  done
}

process_flow

# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT

exit 0