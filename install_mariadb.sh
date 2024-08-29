#!/bin/bash
echo "TESTED ON: mariadb  Ver 15.1 Distrib 10.11.8-MariaDB"
# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Prompt for the database name
read -p "Enter the database name: " DB_NAME

# Prompt for the username
read -p "Enter the username: " DB_USER

# Prompt for remote connection permission
read -p "Allow remote connection? (y/n): " ALLOW_REMOTE

# Install MariaDB
sudo apt update
sudo apt install -y mariadb-server

# Start and configure MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb.service

# Perform secure installation
if [ "$ALLOW_REMOTE" = "y" ]; then
    sudo mysql_secure_installation <<EOF

${ROOT_PASSWORD}
n
n
y
n
y
y
EOF
else
    sudo mysql_secure_installation <<EOF

${ROOT_PASSWORD}
n
n
y
y
y
y
EOF
fi


#Enter current password for root (enter for none):
#Switch to unix_socket authentication [Y/n] n
#Change the root password? [Y/n] n
#Remove anonymous users? [Y/n] y
#Disallow root login remotely? [Y/n]
#Remove test database and access to it? [Y/n] y
#Reload privilege tables now? [Y/n] y


# Generate a random password
DB_PASSWORD=$(generate_password)
ROOT_PASSWORD=$(generate_password)

# Create the database and user
if [ "$ALLOW_REMOTE" = "y" ]; then
    # Allow remote connection
    sudo mysql -e "CREATE DATABASE ${DB_NAME};"
    sudo mysql -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    sudo sed -i "s/bind-address\s*=.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
    sudo systemctl restart mariadb
    DB_HOST=$(hostname -I | awk '{print $1}')
else
    # Local connection only
    sudo mysql -e "CREATE DATABASE ${DB_NAME};"
    sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
    sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
    sudo mysql -e "FLUSH PRIVILEGES;"
    DB_HOST="localhost"
fi


# Output connection details
echo "Host: ${DB_HOST}"
echo "Port: 3306"
echo "***** sudo mysql -u ${DB_USER} -p **********************************"
echo "User: ${DB_USER}"
echo "Password for ${DB_USER}: ${DB_PASSWORD}"
echo "Database: ${DB_NAME}"
echo "***** sudo mysql -u root -p **********************************"
echo "Root MYSQL Password : ${ROOT_PASSWORD}"
