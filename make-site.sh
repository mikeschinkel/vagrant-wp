#!/usr/bin/env bash

echo "Making new site with domain ${DOMAIN} ...";

SAVE_DIR="${PWD}"

DOMAIN="$1"
WP_VER="$2"
GIT_REPO="$3"

cd ${PWD}/sites
git clone ${GIT_REPO} ${DOMAIN}
composer install --prefer-source

cd ${SAVE_DIR}

# Copy provision script to website to it can be called
cp provision/provision.php sites/${DOMAIN}/www
# Run provision script to import initial database(s)
wget http://${DOMAIN}/provision.php?go=yes
# Delete provision script from website
rm sites/${DOMAIN}/www

vagrant reload
