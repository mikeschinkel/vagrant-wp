# -*- mode: ruby -*-
# vi: set ft=ruby :

# require 'rubygems'
# require 'json'
# See http://stackoverflow.com/a/13625633/102699

Vagrant.configure(2) do |config|

	config.vm.box = "ubuntu/vivid64"
  config.vm.hostname = 'wplib.box'
  config.vm.network :private_network, ip: "192.168.99.99"

	config.vm.provision "shell", path: "provision/make-srv-dir.sh"

	# See http://serverfault.com/questions/102569/should-websites-live-in-var-or-usr-according-to-recommended-usage

	# Create site for wplib.box
  config.vm.synced_folder \
    "www", "/var/www", \
    owner: 'www-data', group: 'www-data', \
    mount_options: ["dmode=775", "fmode=664"]

	# Create site for "User" Sites
  config.vm.synced_folder \
    "sites", "/srv/sites", \
    owner: 'www-data', group: 'www-data', \
    mount_options: ["dmode=775", "fmode=664"]

	# Make Server Logs accessible via Host
  config.vm.synced_folder \
    "logs", "/var/log", \
    owner: 'root', group: 'root', \
    mount_options: ["dmode=777", "fmode=777"]

	# Provide a root directory to provision scripts
  config.vm.synced_folder \
    "provision", "/provision", \
    owner: 'root', group: 'root', \
    mount_options: ["dmode=777", "fmode=777"]

	# Make Nginx config files accessible via Host
  config.vm.synced_folder \
    "config/nginx", "/etc/nginx", \
    owner: 'vagrant', group: 'vagrant', \
    mount_options: ["dmode=775", "fmode=664"]

	# Make PHP config files accessible via Host
  config.vm.synced_folder \
    "config/php", "/etc/php/fpm", \
    owner: 'vagrant', group: 'vagrant', \
    mount_options: ["dmode=775", "fmode=664"]

	# Make MariaDB config files accessible via Host
  config.vm.synced_folder \
    "config/mysql", "/etc/mysql", \
    owner: 'vagrant', group: 'vagrant', \
    mount_options: ["dmode=775", "fmode=664"]

	config.vm.provision "shell", path: "provision/provision.sh"


end
