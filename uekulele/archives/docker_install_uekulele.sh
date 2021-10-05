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
	 Owner=$5
 RedHatVersion=$6

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

		n=1
		HelloWorld=1
		while [ $HelloWorld -ne 0 ] && [ $n -le 12 ]
		do
			sudo /var/lib/snapd/snap/bin/docker run -d hello-world
			HelloWorld=`echo $?`
			n=$((n+1))
			echo "Retry Docker ..."
			sleep 5
		done

		echo ''
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

		n=1
		HelloWorld=1
		while [ $HelloWorld -ne 0 ] && [ $n -le 12 ]
		do
			sudo /var/lib/snapd/snap/bin/docker run -d hello-world 
			HelloWorld=`echo $?`
			n=$((n+1))
			echo "Retry Docker ..."
			sleep 5
		done

		echo ''
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

		n=1
		HelloWorld=1
		while [ $HelloWorld -ne 0 ] && [ $n -le 12 ]
		do
			sudo /var/lib/snapd/snap/bin/docker run -d hello-world
			HelloWorld=`echo $?`
			n=$((n+1))
			echo "Retry Docker ..."
			sleep 5
		done

		echo ''
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

if [ $LinuxFlavor = 'Fedora' ]
then
	if   [ $RedHatVersion -ge 30 ]
	then
		if [ $LXDCluster = 'Y' ]
		then
			sudo snap install docker
		else
			sudo dnf -y install snapd
			sudo snap install docker
		fi

		sudo groupadd docker
		sudo usermod -aG docker $Owner
		sudo docker run -d hello-world
		sudo docker ps -a

	elif [ $RedHatVersion -le 29 ] && [ $RedHatVersion -ge 22 ]
	then
		sudo dnf -y install dnf-plugins-core

		ping -c 5 download.docker.com
		DockerCeRepo=1
		n=1
		while [ $DockerCeRepo -ne 0 ] && [ $n -le 5 ]
		do
		 	sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
			DockerCeRepo=`echo $?`
			n=$((n+1))
			sleep 5
		done
			
		sudo dnf -y install docker-ce
		sudo systemctl start docker
		sudo systemctl enable docker
		sudo docker run -d hello-world
		sudo docker ps -a
	
	elif [ $RedHatVersion -lt 22 ]
	then
		sudo dnf -y install docker
		sudo systemctl start docker
		sudo systemctl enable docker
		sudo service docker status
		sudo docker run -d hello-world
		sudo docker ps -a
	fi
fi

