#!/bin/bash

#    Copyright 2015-2021 Gilbert Standen
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

   LinuxFlavor=$1
       Release=$2
       DistDir=$3
    LXDCluster=$4

if [ $LinuxFlavor = 'Oracle' ]
then
	if   [ $Release -eq 8 ]
	then
		echo ''
		echo "=============================================="
		echo "Install OCI Tools (podman skopeo buildah) ... "
		echo "=============================================="
		echo ''

		sudo yum-config-manager --enable ol8_addons
		sudo dnf -y install yum-utils
		sudo dnf -y install podman skopeo buildah 
		podman run -d hello-world
		podman ps -a

	elif [ $Release -eq 7 ] 
	then 
		if [ $LXDCluster = 'Y' ]
		then
			sudo snap install docker
		else
			sudo yum -y install snapd
			sudo snap install docker
		fi

		sudo /var/lib/snapd/snap/bin/docker run -d hello-world
		sudo /var/lib/snapd/snap/bin/docker ps -a
	
	elif [ $Release -eq 6 ]
	then
		function CheckUEKVersion {
			sudo /opt/olxc/"$DistDir"/anylinux/vercomp | cut -f2 -d"'" | cut -f1 -d' ' | cut -f1 -d'.'
		}
		UEKVersion=$(CheckUEKVersion)

		if [ $UEKVersion -ge 4 ]
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
			sudo docker run -d hello-world
			sudo docker ps -a
		else
			echo "=============================================="
			echo "Docker unsupported on UEK $UEKVersion kernels."
			echo "=============================================="
		fi
	fi
fi

if [ $LinuxFlavor = 'Red' ]
then
	if   [ $Release -eq 8 ]
	then
		echo ''
		echo "=============================================="
		echo "Install OCI Tools (podman skopeo buildah) ... "
		echo "=============================================="
		echo ''

		sudo dnf -y install podman skopeo buildah 
		podman run -d hello-world
		podman ps -a

	elif [ $Release -eq 7 ] 
	then 
		if [ $LXDCluster = 'Y' ]
		then
			sudo snap install docker
		else
			sudo yum -y install snapd
			sudo snap install docker
		fi

		sudo /var/lib/snapd/snap/bin/docker run -d hello-world
		sudo /var/lib/snapd/snap/bin/docker ps -a
	
	elif [ $Release -eq 6 ]
	then
		sudo yum -y update
		sudo yum -y  install yum-utils device-mapper-persistent-data lvm2
		sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
		sudo yum -y update
		sudo yum -y install docker-ce
		sudo systemctl enable docker
		sudo systemctl status docker
		sudo docker run -d hello-world
		sudo docker ps -a
	fi
fi

if [ $LinuxFlavor = 'CentOS' ]
then
	if   [ $Release -eq 8 ]
	then
		echo ''
		echo "=============================================="
		echo "Install OCI Tools (podman skopeo buildah) ... "
		echo "=============================================="
		echo ''

		sudo dnf -y install podman skopeo buildah 
		podman run -d hello-world
		podman ps -a

	elif [ $Release -eq 7 ] 
	then 
		if [ $LXDCluster = 'Y' ]
		then
			sudo snap install docker
		else
			sudo yum -y install snapd
			sudo snap install docker
		fi

		sudo /var/lib/snapd/snap/bin/docker run -d hello-world
		sudo /var/lib/snapd/snap/bin/docker ps -a
	
	elif [ $Release -eq 6 ]
	then
		sudo yum -y update
		sudo yum -y  install yum-utils device-mapper-persistent-data lvm2
		sudo yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
		sudo yum -y update
		sudo yum -y install docker-ce
		sudo systemctl enable docker
		sudo systemctl status docker
		sudo docker run -d hello-world
		sudo docker ps -a
	fi
fi

# if [ $LinuxFlavor = 'CentOS' ]
# then
# 	if   [ $Release -eq 6 ]
# 	then
# 		sudo yum -y install docker-io
# 		sleep 2
# 		sudo service docker start
# 		sudo chkconfig docker on
# 
# 		function CheckDockerRunning {
# 			ps -ef | grep -c 'docker \-d'
# 		}
# 		DockerRunning=$(CheckDockerRunning)
# 
# 		d=1
# 		while [ $DockerRunning -eq 0 ] && [ $d -le 5 ]
# 		do
# 			sleep 5
# 			sudo service docker start
# 			echo ''
# 			DockerRunning=$(CheckDockerRunning)
# 			ps -ef | grep docker
# 			d=$((d+1))
# 		done
# 
# 	elif [ $Release -eq 7 ]
# 	then
# 		sudo yum install -y yum-utils device-mapper-persistent-data lvm2
# 		sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 		sudo yum-config-manager --enable docker-ce-edge
# 		sudo yum-config-manager --enable docker-ce-test
# 		sudo yum -y install docker-ce
# 		sudo systemctl start docker
# 		sudo systemctl enable docker
# 	fi
# fi

if [ $LinuxFlavor = 'Fedora' ]
then
	function CheckSnapdInstalled {
		sudo snap version | egrep -c 'snap|snapd'	
	}
	SnapdInstalled=$(CheckSnapdInstalled)

	if [ $Release -ge 8 ] && [ $SnapdInstalled -ge 1 ]
	then
		sudo snap install docker
		sudo docker run -d oraclelinux:7.3
	else
		sudo dnf -y install dnf-plugins-core
		sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
		sudo dnf -y install docker-ce
		sudo systemctl start docker
		sudo systemctl enable docker
	fi
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

if [ $LinuxFlavor = 'Oracle' ]
then
	function CheckUEKVersion {
		sudo /opt/olxc/"$DistDir"/anylinux/vercomp | cut -f2 -d"'" | cut -f1 -d' ' | cut -f1 -d'.'
	}
	UEKVersion=$(CheckUEKVersion)
else
	UEKVersion=0
fi

if   [ $Release -le 7 ]
then
 	sudo docker run -d hello-world
#	sudo docker run -d -p 2200:22 raesene/alpine-nettools
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

elif [ $Release -eq 8 ] && [ $LinuxFlavor = 'Oracle' ]
then
 	podman run -d hello-world
#	podman run -d raesene/alpine-nettools
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
else
	sudo docker run -d hello-world
fi


# Install ODOO ERP
# sudo docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db postgres:9.4
# sudo docker run -d -p 8069:8069 --name odoo --link db:db -t odoo
# sudo docker exec -ti <container_name> /bin/sh

