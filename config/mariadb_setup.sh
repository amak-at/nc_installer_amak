#!/bin/bash
source $1

# Secure MariaDB Installation
echo "Securing MariaDB installation..."
mysql_secure_installation <<EOF

y
n
y
y
y
y
EOF

# Wait for MariaDB to start
sleep 5

# Open SQL dialog and execute commands
echo "Creating database and user..."
mysql -e "CREATE DATABASE $DB_NAME;"
mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

echo "Database and user created successfully."
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"

exit 0
