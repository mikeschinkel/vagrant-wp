#!/usr/bin/env bash

source /provision/includes.sh

STARTDIR=${PWD}

#UBUNTU
echo "Updating Ubuntu 15.04 ..."
sudo apt-get -y update
echo "Upgrading Ubuntu 15.04 ..."
sudo apt-get -y upgrade

echo "Remove Uncomplicated Firewall ..."
sudo apt-get -y remove ufw

echo "Using Google's DNS ..."
sudo rm /etc/resolv.conf
sudo cp /provision/resolve.conf /etc/resolv.conf

#JQ - Like sed for JSON
# See https://stedolan.github.io/jq/
# See https://josephscott.org/archives/2013/03/jq-command-line-json-processor/
echo "Installing jq ..."
sudo apt-get -y install jq

echo "Adding 192.168.99.99 to the Hosts file ..."
sudo sed -i '$a 192.168.99.99 wplib.box' /etc/hosts

echo "Adding ALL:ALL to the Hosts.Allow file ..."
sudo sed -i '$a ALL:ALL' /etc/hosts.allow

##NGINX
echo "Installing Nginx ..."
sudo rm -Rf /etc/nginx/*
sudo apt-get -y install nginx
echo "Setting Nginx Worker Processes to 1 ..."
file_replace "/etc/nginx/nginx.conf" \
	"worker_processes 4" \
	"worker_processes 1"
echo "Domain for Nginx is ${DOMAIN} ..."

echo "Creating Nginx config files ..."

for filepath in /provision/sites/*.conf; do
	DOMAIN=$(basename "${filepath}" .conf)
	echo "Enabling domain ${DOMAIN} for Nginx ..."
	cp ${filepath} /etc/nginx/sites-available/
	sudo ln -s \
		/etc/nginx/sites-available/${DOMAIN}.conf \
		/etc/nginx/sites-enabled/${DOMAIN}.conf
	sudo mkdir -p /var/log/nginx/${DOMAIN}
done

echo "Restarting Nginx ..."
sudo service nginx stop
sleep 5
sudo service nginx restart


#MARIADB
echo "Installing MariaDB ..."
sudo apt-get -y install mariadb-server
# See https://gist.github.com/Mins/4602864#gistcomment-1294952
echo "Set Root Password for MariaDB [--user=root --password=vagrant]..."
sudo mysql --user=root --batch --database=mysql < /provision/root-init.sql
cd /etc/mysql/
# See http://stackoverflow.com/a/6817713/102699
# See http://stackoverflow.com/a/6337930/102699
file_replace "mariadb.conf.d/mysqld.cnf" \
	"bind-address.+= 127.0.0.1" \
	"bind-address = 0.0.0.0" \
	"-r"

echo "Restarting MariaDB ..."
sudo service mysql restart

#PHP
echo "Installing PHP 5.6 ..."
sudo apt-get -y install php5 php5-fpm php5-mysql
echo "Installing PHP JSON ..."
sudo apt-get -y install php5-json
echo "Installing XDEBUG ..."
sudo apt-get -y install php5-xdebug

echo "Securing PHP ..."
file_replace "/etc/php5/fpm/pool.d/www.conf" \
	";security.limit_extensions = .php .php3 .php4 .php5" \
	"security.limit_extensions=.php"

echo "Eliminating Nginx Timeouts (max_execution_time=86,400 aka 1 day) ..."
file_replace "/etc/php5/fpm/php.ini" \
	"max_execution_time = 30" \
	"max_execution_time = 86400"


echo "Restarting PHP FPM ..."
sudo service php5-fpm restart

cd ${STARTDIR}

echo "Provision Complete."
