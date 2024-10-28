#!/bin/bash
source $1

echo "Creating backup-script and run it..."

mkdir -p $BACKUP_DIR/daten $BACKUP_TEMP_DIR $BACKUP_RESTORE_DIR $BACKUP_LOG_DIR

./installation-scripts/borgbackup-expect.sh $BACKUP_DIR $BACKUP_PASS > /dev/null 2>&1

cat <<EOF > $BACKUP_SCRIPT_PATH
#!/bin/bash
export BORG_PASSPHRASE='$BACKUP_PASS'
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes
startTime=\$(date +%s)
currentDate=\$(date --date @"\$startTime" +"%Y%m%d_%H%M%S")
currentDateReadable=\$(date --date @"\$startTime" +"%d.%m.%Y - %H:%M:%S")
logDirectory="$BACKUP_LOG_DIR/"
logFile="\${logDirectory}/\${currentDate}.log"
backupDiscMount="$BACKUP_DIR/daten/"
localBackupDir="$BACKUP_TEMP_DIR"
borgRepository="\${backupDiscMount}/"
borgBackupDirs="$NC_DATA_DIR/ $NC_DIR/ \$localBackupDir/"
nextcloudFileDir='$NC_DIR'
webserverServiceName='apache2'
webserverUser='www-data'
nextcloudDatabase='$NC_DB_NAME'
dbUser='$NC_DB_USER'
dbPassword='$NC_DB_PASS'
fileNameBackupDb='nextcloud-db.sql'
if [ ! -d "\${logDirectory}" ]
then
    mkdir -p "\${logDirectory}"
fi
errorecho() { cat <<< "\$@" 1>&2; }
exec > >(tee -i "\${logFile}")
exec 2>&1
if [ "\$(id -u)" != "0" ]
then
    errorecho "ERROR: This script has to be run as root!"
    exit 1
fi
if [ ! -d "\${localBackupDir}" ]
then
    errorecho "ERROR: The local backup directory \${localBackupDir} does not exist!"
    exit 1
fi
echo -e "\n###### Starting backups: \${currentDateReadable} ######\n"
echo -e "collecting data..."
dpkg --get-selections > "\${localBackupDir}/software.list"
sudo -u "\${webserverUser}" php8.2 \${nextcloudFileDir}/occ maintenance:mode --on
echo "stop apache2..."
systemctl stop "\${webserverServiceName}"
echo "creating database backup..."
mysqldump --single-transaction --routines -h localhost -u "\${dbUser}" -p"\${dbPassword}" "\${nextcloudDatabase}" > "\${localBackupDir}/\${fileNameBackupDb}"
echo -e "\nBackup with borgbackup"
borg create --stats \
    \$borgRepository::"\${currentDate}" \
    \$localBackupDir \
    \$borgBackupDirs 
echo
echo "starting webserver"
systemctl start "\${webserverServiceName}"
sudo -u "\${webserverUser}" php8.2 \${nextcloudFileDir}/occ maintenance:mode --off
rm "\${localBackupDir}"/software.list
rm -r "\${localBackupDir}/\${fileNameBackupDb}"
borg prune --progress --stats \$borgRepository --keep-within=7d --keep-weekly=4 --keep-monthly=6
endTime=\$(date +%s)
endDateReadable=\$(date --date @"\$endTime" +"%d.%m.%Y - %H:%M:%S")
duration=\$((endTime-startTime))
durationSec=\$((duration % 60))
durationMin=\$(((duration / 60) % 60))
durationHour=\$((duration / 3600))
durationReadable=\$(printf "%02d Stunden %02d Minuten %02d Sekunden" \$durationHour \$durationMin \$durationSec)
echo -e "\n###### End of backups: \${endDateReadable} (\${durationReadable}) ######\n"
echo -e "Disk usage:\n"
df -h \${backupDiscMount}
EOF

chmod +x $BACKUP_SCRIPT_PATH
cd $BACKUP_ROOT_DIR
./backup.sh

(echo "$BACKUP_TIME_MINUTE $BACKUP_TIME_HOUR * * * $BACKUP_SCRIPT_PATH > /dev/null 2>&1") | crontab -

cd $STARTING_DIR

echo "Creating backup-script done."

exit 0