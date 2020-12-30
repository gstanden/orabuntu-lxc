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

if   [ $UbuntuVersion = '16.04' ]
then
#	apt-get -o Acquire::ForceIPv4=true update
#	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
#	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#	sudo apt-key fingerprint 0EBFCD88
#	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#	sudo apt-get -y update
#	sudo apt-get -y install docker-ce
        sudo apt-get -o Acquire::ForceIPv4=true update
        sudo apt-get -o Acquire::ForceIPv4=true -y install apt-transport-https ca-certificates curl software-properties-common
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get -o Acquire::ForceIPv4=true update
        sudo apt-get -o Acquire::ForceIPv4=true -y install docker-ce

elif [ $UbuntuVersion = '16.10' ]
then
	sudo apt-get -y install docker.io

elif [ $UbuntuMajorVersion -eq 17 ]
then
	sudo apt-get -o Acquire::ForceIPv4=true update
	sudo apt-get -o Acquire::ForceIPv4=true -y install apt-transport-https ca-certificates curl software-properties-common
	sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt-key fingerprint 0EBFCD88
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable"
	sudo apt-get -o Acquire::ForceIPv4=true update
	sudo apt-get -o Acquire::ForceIPv4=true -y install docker-cea
elif [ $UbuntuMajorVersion -ge 18 ]
then
	echo ''
	echo "=============================================="
	echo "Installing Snap Microk8s (Kubernetes)         "
	echo "=============================================="
	echo ''

	sudo snap install microk8s --classic

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Installing Snap Docker ...                    "
	echo "=============================================="
	echo ''

	sudo snap install  docker --edge
	sudo snap services docker

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Docker Snap Info ...                          "
	echo "=============================================="
	echo ''

	sudo snap info docker

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Microk8s Snap Info ...                        "
	echo "=============================================="
	echo ''

	sudo snap info microk8s

	sleep 5

	clear
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


echo ''
echo "=============================================="
echo "Done: Install docker-ce.                      "
echo "=============================================="
echo ''
echo "=============================================="
echo "Install User-Settable Docker Containers...    "
echo "=============================================="
echo ''

docker create ubuntu:16:04
# Install alpine-nettools
sudo docker run -d -p 2200:22 raesene/alpine-nettools

# Install ODOO ERP
# sudo docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres:9.4
# sudo docker run -d -p 8069:8069 --name odoo --link db:db -t odoo

# sudo docker exec -ti <container_name> /bin/sh
sleep 2
sudo docker ps -a

echo ''
echo "=============================================="
echo "Done: Install User-Settable Docker Containers."
echo "=============================================="
echo ''
echo "=============================================="
echo "Done: Install Docker.                         "
echo "=============================================="


