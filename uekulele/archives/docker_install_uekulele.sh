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

#    v2.4 		GLS 20151224
#    v2.8 		GLS 20151231
#    v3.0 		GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 		GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 		GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta	GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#
#!/bin/bash

LinuxFlavor=$1
    Release=$2

if [ $LinuxFlavor = 'Oracle' ]
then
	if   [ $Release -eq 8 ]
	then
		echo ''
		echo "=============================================="
		echo "Install OCI Tools (podman skopeo buildah) ... "
		echo "=============================================="
		echo ''

		sudo yum -y install yum-utils
		sudo yum-config-manager --enable ol8_addons
		sudo yum -y install podman skopeo buildah 

	elif [ $Release -eq 7 ]
	then
		echo ''
		echo "=============================================="
		echo "Install docker-ce...                          "
		echo "=============================================="
		echo ''

		sudo yum-config-manager --enable ol7_addons
		sudo yum -y install docker-engine podman
		sudo systemctl start docker
		sudo systemctl enable docker

	elif [ $Release -eq 6 ]
	then
		echo ''
		echo "=============================================="
		echo "Install docker-ce...                          "
		echo "=============================================="
		echo ''

		sudo yum-config-manager --enable public_ol6_addons
		sudo yum -y install docker-engine
		sudo service docker start
		sudo chkconfig docker on
	fi
fi

if [ $LinuxFlavor = 'CentOS' ]
then
	if   [ $Release -eq 6 ]
	then
		sudo yum -y install docker-io
		sleep 2
		sudo service docker start
		sudo chkconfig docker on

		function CheckDockerRunning {
			ps -ef | grep -c 'docker \-d'
		}
		DockerRunning=$(CheckDockerRunning)

		d=1
		while [ $DockerRunning -eq 0 ] && [ $d -le 5 ]
		do
			sleep 5
			sudo service docker start
			echo ''
			DockerRunning=$(CheckDockerRunning)
			ps -ef | grep docker
			d=$((d+1))
		done

 	elif [ $Release -eq 7 ]
 	then
 		sudo yum install -y yum-utils device-mapper-persistent-data lvm2
 		sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
 		sudo yum-config-manager --enable docker-ce-edge
 		sudo yum-config-manager --enable docker-ce-test
 		sudo yum -y install docker-ce
 		sudo systemctl start docker
 		sudo systemctl enable docker
 	fi
fi

if [ $LinuxFlavor = 'Fedora' ]
then
	sudo dnf -y install dnf-plugins-core
	sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
	sudo dnf -y install docker-ce
	sudo systemctl start docker
	sudo systemctl enable docker
fi

# echo ''
# echo "=============================================="
# echo "Done: Configure required repository.          "
# echo "=============================================="
# echo ''
# echo "=============================================="
# echo "Done: Install docker-ce.                      "
# echo "=============================================="
# echo ''
# echo "=============================================="
# echo "Install User-Settable Docker Containers...    "
# echo "=============================================="
# echo ''

# Install alpine-nettools

if   [ $Release -le 7 ]
then
	sudo docker run -d -p 2200:22 raesene/alpine-nettools
	sudo docker ps -a

	sleep 2

	echo ''
	echo "=============================================="
	echo "Done: Install User-Settable Docker Containers."
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Done: Install Docker.                         "
	echo "=============================================="

elif [ $Release -eq 8 ]
then
	podman run -d raesene/alpine-nettools
	podman ps -a

	sleep 2

	echo ''
	echo "=============================================="
	echo "Done: Install User-Settable Podman Containers."
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Done: Install OCI Tools.                      "
	echo "=============================================="
fi

# Install ODOO ERP
# sudo docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres:9.4
# sudo docker run -d -p 8069:8069 --name odoo --link db:db -t odoo
# sudo docker exec -ti <container_name> /bin/sh

