#!/bin/bash

source $1

CONF_FILE="$1"

INPUT=$TEMP_DIR/menu.sh.$$
OUTPUT=$TEMP_DIR/output.sh.$$

backtitle_txt="[ Nextcloud-Installer (c) Amak-AT ]"
declare -A nextcloud_settings
declare -A backup_settings

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

#while true
#do
dialog --backtitle "$backtitle_txt"  --msgbox "Test" 5 40 \
--and-widget --yesno "mein Yes No" 5 30 \
--and-widget --msbox "Submit" 5 20
#done


# if temp files found, delete em
[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT

exit 0