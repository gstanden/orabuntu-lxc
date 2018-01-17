#!/bin/bash

clear

function GetUbuntuVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
}
UbuntuVersion=$(GetUbuntuVersion)

function GetUbuntuMajorVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
}
UbuntuMajorVersion=$(GetUbuntuMajorVersion)

echo ''
echo "=============================================="
echo "Install Docker...                             "
echo "=============================================="
echo ''
echo "=============================================="
echo "Install required packages...                  "
echo "=============================================="
echo ''

sudo apt-get -y update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

echo ''
echo "=============================================="
echo "Done: Install required packages.              "
echo "=============================================="
echo ''
echo "=============================================="
echo "Configure required repository...              "
echo "=============================================="
echo ''

if   [ $UbuntuMajorVersion -eq 16 ]
then
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

elif [ $UbuntuMajorVersion -eq 17 ]
then
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt-key fingerprint 0EBFCD88
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable"
	sudo apt-get -y update
fi

echo ''
echo "=============================================="
echo "Done: Configure required repository.          "
echo "=============================================="
echo ''
echo "=============================================="
echo "Install docker-ce...                          "
echo "=============================================="
echo ''

sudo apt-get -y install docker-ce

echo ''
echo "=============================================="
echo "Done: Install docker-ce.                      "
echo "=============================================="
echo ''
echo "=============================================="
echo "Install docker raesene/alping-nettools...     "
echo "=============================================="
echo ''

sudo docker run -d -p 2200:22 raesene/alpine-nettools
# sudo docker exec -ti <container_name> /bin/sh
sleep 2
sudo docker ps -a

echo ''
echo "=============================================="
echo "Done: Install docker raesene/alping-nettools. "
echo "=============================================="
echo ''
echo "=============================================="
echo "Done: Install Docker.                         "
echo "=============================================="


