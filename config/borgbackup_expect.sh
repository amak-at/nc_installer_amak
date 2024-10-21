#!/usr/bin/expect -f

set backup_dir [lindex $argv 0]
set backup_pw [lindex $argv 1]

spawn borg init -e repokey-blake2 $backup_dir/daten/
expect "Enter passphrase:" 
send "$backup_pw\r"
expect "Enter passphrase again:" 
send "$backup_pw\r"
expect "Do you want to continue? (y/n):"
send "y\r"
interact

exit 0