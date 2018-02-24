#!/bin/bash

#    Copyright 2015-2018 Gilbert Standen
#    This file is part of Orabuntu-LXC.

#    Orabuntu-LXC is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-LXC is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Orabuntu-LXC.  If not, see <http://www.gnu.org/licenses/>.

#    v2.4               GLS 20151224
#    v2.8               GLS 20151231
#    v3.0               GLS 20160710 Updates for Ubuntu 16.04
#    v4.0               GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0               GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta    GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC

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
	sudo apt-get -y update
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt-get -y install docker-ce

elif [ $UbuntuVersion = '16.10' ]
then
	sudo apt-get install docker.io
elif [ $UbuntuVersion = '17.04' ] || [ $UbuntuVersion = '17.10' ]
then
	sudo apt-get -y update
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	sudo apt-key fingerprint 0EBFCD88
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable"
	sudo apt-get -y update
	sudo apt-get -y install docker-ce
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


