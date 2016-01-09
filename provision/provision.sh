#!/usr/bin/env bash

STARTDIR=${PWD}

export DEBIAN_FRONTEND=noninteractive

file_replace() {
	echo "================================"
	echo "Updating $1 ..."
	STAT=$(stat -c%a $1)
	chmod 777 $1
	sudo sed $4 -i "s/$2/$3/" $1
	chmod ${STAT} $1
	echo "================================"
	return 0
}

#UBUNTU
echo "Updating Ubuntu 15.04 ..."
sudo apt-get -y update
echo "Upgrading Ubuntu 15.04 ..."
sudo apt-get -y upgrade

echo "Remove Uncomplicated Firewall ..."
sudo apt-get -y remove ufw

echo "Using Google's DNS ..."
sudo rm /etc/resolv.conf
sudo cp /vagrant/provision/resolve.conf /etc/resolv.conf

#JQ - Like sed for JSON
# See https://stedolan.github.io/jq/
# See https://josephscott.org/archives/2013/03/jq-command-line-json-processor/
echo "Installing jq ..."
sudo apt-get -y install jq
echo "Getting Domain for Nginx ..."
DOMAIN=$(cat /vagrant/wplib-box.json | jq -r '.domain')
echo "Domain for Nginx is ${DOMAIN} ..."
echo "Getting IP Address for MariaDB ..."
IP_ADDRESS=$(cat /vagrant/wplib-box.json | jq -r '.ip_address')
echo "IP address for MariaDB is ${IP_ADDRESS} ..."

echo "Adding ${IP_ADDRESS} for ${DOMAIN} to the Hosts file ..."
sudo sed -i '1 a ${IP_ADDRESS} ${DOMAIN}' /etc/hosts

echo "Adding ALL:ALL to the Hosts.Allow file ..."
sudo sed -i '$ a ALL:ALL' /etc/hosts.allow

##NGINX
echo "Installing Nginx ..."
sudo apt-get -y install nginx
echo "Setting Nginx Worker Processes to 1 ..."
file_replace "/etc/nginx/nginx.conf" \
	"worker_processes 4" \
	"worker_processes 1"
echo "Domain for Nginx is ${DOMAIN} ..."
cd /etc/nginx/
echo "Creating Nginx config file for ${DOMAIN} ..."
cp /vagrant/provision/nginx-server.conf sites-available/${DOMAIN}.conf
file_replace "sites-available/${DOMAIN}.conf" \
	"server_name {domain};" \
	"server_name ${DOMAIN};"
echo "Enabling domain ${DOMAIN} for Nginx ..."
sudo ln -s \
	/etc/nginx/sites-available/${DOMAIN}.conf \
	/etc/nginx/sites-enabled/${DOMAIN}.conf
echo "Restarting Nginx ..."
sudo service nginx restart

#MARIADB
echo "Installing MariaDB ..."
sudo apt-get -y install mariadb-server
# See https://gist.github.com/Mins/4602864#gistcomment-1294952
echo "Set Root Password for MariaDB [--user=root --password=vagrant]..."
sudo mysql --user=root --batch --database=mysql < /vagrant/provision/root-init.sql
cd /etc/mysql/
# See http://stackoverflow.com/a/6817713/102699
# See http://stackoverflow.com/a/6337930/102699 (REBOOT REQUIRED!)
file_replace "mariadb.conf.d/mysqld.cnf" \
	"bind-address.+= 127.0.0.1" \
	"bind-address = 0.0.0.0" \
	"-r"

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

echo "Provision Complete. Rebooting Vagrant Box NOW ..."
sudo reboot now
sleep 10
echo "Provisioned Vagrant Box should be available now, or very soon..."
