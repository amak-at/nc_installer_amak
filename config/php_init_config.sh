#!/bin/bash

CONFIG_FILE="/etc/php/8.2/apache2/php.ini"

# Get the system's current timezone
OS_TIMEZONE=$(timedatectl show --property=Timezone --value)

# Definiere die Einstellungen als assoziatives Array
declare -A SETTINGS=(
    ["memory_limit"]="4096M"
    ["upload_max_filesize"]="20G"
    ["post_max_size"]="20G"
    ["date.timezone"]="$OS_TIMEZONE"
    ["output_buffering"]="Off"
    ["opcache.enable"]="1"
    ["opcache.enable_cli"]="1"
    ["opcache.interned_strings_buffer"]="64"
    ["opcache.max_accelerated_files"]="10000"
    ["opcache.memory_consumption"]="1024"
    ["opcache.save_comments"]="1"
    ["opcache.revalidate_freq"]="1"
)

for KEY in "${!SETTINGS[@]}"; do
    VALUE=${SETTINGS[$KEY]}

    # Prüfe auf exakte Übereinstimmung (mit optionalem Kommentarzeichen und Leerzeichen)
    if grep -Eq "^[;#]?\s*${KEY}\s*=" "$CONFIG_FILE"; then
        # Ersetze nur exakte Übereinstimmungen
        sed -i "s|^[;#]\?\s*${KEY}\s*=.*|${KEY} = ${VALUE}|" "$CONFIG_FILE"
    else
        # Wenn der Eintrag nicht existiert, füge ihn am Ende der Datei hinzu
        echo "${KEY} = ${VALUE}" >> "$CONFIG_FILE"
    fi
done

echo "PHP configuration complete."
