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
NGINX_LOADED=$(sudo service nginx status | grep "Loaded: loaded")
NGINX_ACTIVE=$(sudo service nginx status | grep "Active: active")
if [ -z "$NGINX_LOADED" ] ||  [ -z "$NGINX_ACTIVE" ]; then

	# See https://enriquemorenotent.com/removing-nginx-completely-from-ubuntu/
	#     http://askubuntu.com/questions/235347/what-is-the-best-way-to-uninstall-nginx
	sudo service nginx stop > /dev/null 2>&1
	sudo apt-get -y autoremove nginx
	sudo apt-get -y remove --purge nginx*
	sudo apt-get -y autoremove
	sudo apt-get -y autoclean

	echo "Installing Nginx ..."
	sudo apt-get -y -f install nginx
	sudo service nginx stop
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
		sudo mkdir -p /var/log/nginx
		sudo mkdir -p /var/log/nginx/${DOMAIN}
	done

	echo "Restarting Nginx ..."
	sleep 5
	sudo service nginx restart
fi

#MARIADB
MYSQL_LOADED=$(sudo service mysql status | grep "Loaded: loaded")
MYSQL_ACTIVE=$(sudo service mysql status | grep "Active: active")
if [ -z "$MYSQL_LOADED" ] ||  [ -z "$MYSQL_ACTIVE" ]; then
	echo "Installing MariaDB ..."
	# See https://www.londonappdeveloper.com/how-to-completely-uninstall-mariadb-from-a-debian-7-server/
	sudo service mysql stop > /dev/null 2>&1
	sudo apt-get -y --purge remove "mysql*"
	sudo rm -Rf /etc/mysql > /dev/null 2>&1
  # Install now
	sudo apt-get -y install mariadb-server
	# See https://gist.github.com/Mins/4602864#gistcomment-1294952
	echo "Set Root Password for MariaDB [--user=root --password=vagrant]..."
	sudo mysql --user=root --password=vagrant --batch --database=mysql < /provision/root-init.sql
	# See http://stackoverflow.com/a/6817713/102699
	# See http://stackoverflow.com/a/6337930/102699
	file_replace "/etc/mysql/mariadb.conf.d/mysqld.cnf" \
		"bind-address.+= 127.0.0.1" \
		"bind-address = 0.0.0.0" \
		"-r"

	echo "Restarting MariaDB ..."
	sudo service mysql restart
fi

#PHP
PHP5_LOADED=$(sudo service php5-fpm status | grep "Loaded: loaded")
PHP5_ACTIVE=$(sudo service php5-fpm status | grep "Active: active")
if [ -z "$PHP5_LOADED" ] ||  [ -z "$PHP5_ACTIVE" ]; then

	# See http://askubuntu.com/questions/59886/how-to-compelety-remove-php
	sudo service php5-fpm stop > /dev/null 2>&1
	sudo apt-get -y purge php.*

	echo "Installing PHP 5.6 w/X-DEBUG..."
	sudo apt-get -y install php5 php5-fpm php5-mysql php5-json php5-xdebug

	echo "Securing PHP ..."
	file_replace "/etc/php5/fpm/pool.d/www.conf" \
		";security.limit_extensions = .php .php3 .php4 .php5" \
		"security.limit_extensions=.php"

	echo "Eliminating Nginx Timeouts (max_execution_time=86,400 aka 1 day) ..."

	file_replace "/etc/php5/fpm/pool.d/www.conf" \
		";request_terminate_timeout = 0" \
		"request_terminate_timeout = 0"

	cd /etc/php5/fpm/conf.d
	sudo sed -i "$a xdebug.remote_enable=1" 20-xdebug.ini
	sudo sed -i "$a xdebug.remote_connect_back=1" 20-xdebug.ini
	sudo sed -i "$a xdebug.remote_port=9000" 20-xdebug.ini
	sudo sed -i "$a xdebug.idekey=PHPSTORM" 20-xdebug.ini
	sudo sed -i "$a xdebug.max_nesting_level=1000" 20-xdebug.ini

	#-- THIS IS BREAKING php5-fpm. NOT SURE WHY
	echo "Stop PHP trying to fix broken URLs ..."
	file_replace "/etc/php5/fpm/php.ini" \
		";cgi.fix_pathinfo=1" \
		"cgi.fix_pathinfo=0"

	echo "Restarting PHP FPM ..."
	sudo service php5-fpm restart
fi

cd ${STARTDIR}

echo "Provision Complete."
