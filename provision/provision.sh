#!/usr/bin/env bash

STARTDIR=${PWD}

export DEBIAN_FRONTEND=noninteractive

file_replace() {
	echo "================================"
	echo "Updating $1 ..."
	STAT=$(stat -c%a $1)
	chmod 777 $1
	sudo sed -i.bak "s/$2/$3/" $1
	sudo rm $1.bak
	chmod ${STAT} $1
	echo "================================"
	return 0
}

#UBUNTU
echo "Updating Ubuntu 15.04 ..."
sudo apt-get -y update
echo "Upgrading Ubuntu 15.04 ..."
sudo apt-get -y upgrade

#JQ - Like sed for JSON
# See https://stedolan.github.io/jq/
# See https://josephscott.org/archives/2013/03/jq-command-line-json-processor/
echo "Installing jq ..."
sudo apt-get -y install jq

##NGINX
echo "Installing Nginx ..."
sudo apt-get -y install nginx
echo "Setting Nginx Worker Processes to 1 ..."
file_replace "/etc/nginx/nginx.conf" \
	"worker_processes 4" \
	"worker_processes 1"
echo "Getting Domain for Nginx ..."
DOMAIN=$(cat /vagrant/wplib-box.json | jq -r '.domain')
echo "Domain for Nginx is ${DOMAIN} ..."
cd /etc/nginx/
echo "Creating Nginx config file for ${DOMAIN} ..."
cp /vagrant/provision/nginx-server.conf sites-available/${DOMAIN}.conf
file_replace "sites-available/${DOMAIN}.conf" \
	"server_name {domain};" \
	"server_name ${DOMAIN};"
echo "Enabling domain ${DOMAIN} for Nginx ..."
sudo ln -s sites-available/${DOMAIN}.conf sites-enabled/${DOMAIN}.conf
echo "Restarting Nginx ..."
sudo service nginx restart

#MARIADB
echo "Installing MariaDB ..."
sudo apt-get -y install mariadb-server
# See https://gist.github.com/Mins/4602864#gistcomment-1294952
echo "Set Root Password for MariaDB [--user=root --password=vagrant]..."
sudo mysql --user=root --batch --database=mysql < /vagrant/provision/root-init.sql

#PHP
echo "Installing PHP 5.6 ..."
sudo apt-get -y install php5 php5-fpm php5-mysql
echo "Installing PHP JSON ..."
sudo apt-get -y install php5-json
echo "Restarting PHP FPM ..."
sudo service php5-fpm restart
echo "Securing PHP ..."
file_replace "/etc/php5/fpm/pool.d/www.conf" \
	";security.limit_extensions = .php .php3 .php4 .php5" \
	"security.limit_extensions=.php"

cd ${STARTDIR}

echo "Provision Complete."
