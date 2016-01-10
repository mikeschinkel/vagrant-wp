#!/usr/bin/env bash

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

