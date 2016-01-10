#!/usr/bin/env bash

echo "Making new site with domain ${DOMAIN} ...";

SAVE_DIR="${PWD}"

DOMAIN="$1"
WP_VER="$2"
GIT_REPO="$3"

cd ${PWD}/sites
git clone ${GIT_REPO} ${DOMAIN}
ln -s /vagrant/wp/${WP_VER} /srv/sites/${DOMAIN}/www/wp

cd ${SAVE_DIR}

vagrant reload
