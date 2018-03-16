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

GetLinuxFlavors(){
if   [[ -e /etc/oracle-release ]]
then
        LinuxFlavors=$(cat /etc/oracle-release | cut -f1 -d' ')
elif [[ -e /etc/redhat-release ]]
then
        LinuxFlavors=$(cat /etc/redhat-release | cut -f1 -d' ')
elif [[ -e /usr/bin/lsb_release ]]
then
        LinuxFlavors=$(lsb_release -d | awk -F ':' '{print $2}' | cut -f1 -d' ')
elif [[ -e /etc/issue ]]
then
        LinuxFlavors=$(cat /etc/issue | cut -f1 -d' ')
else
        LinuxFlavors=$(cat /proc/version | cut -f1 -d' ')
fi
}
GetLinuxFlavors

function TrimLinuxFlavors {
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//'
}
LinuxFlavor=$(TrimLinuxFlavors)

if   [ $LinuxFlavor = 'Oracle' ]
then
        CutIndex=7
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                CutIndex=7
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                CutIndex=4
        fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        if [ $RedHatVersion -ge 19 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Ubuntu' ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
        LF=$LinuxFlavor
        RL=$UbuntuVersion
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

echo ''
echo "=============================================="
echo "Install docker-ce...                          "
echo "=============================================="
echo ''

if [ $LinuxFlavor = 'Oracle' ]
then
	sudo yum-config-manager --enable ol7_addons
	sudo yum -y install docker-engine
	sudo systemctl start docker
	sudo systemctl enable docker
elif [ $LinuxFlavor = 'CentOS' ]
then
	sudo yum install -y yum-utils device-mapper-persistent-data lvm2
	sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# 	sudo yum-config-manager --enable docker-ce-edge
# 	sudo yum-config-manager --enable docker-ce-test
	sudo yum -y install docker-ce
	sudo systemctl start docker
	sudo systemctl enable docker
elif [ $LinuxFlavor = 'Fedora' ]
then
	sudo dnf -y install dnf-plugins-core
	sudo dnf -y config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
	sudo dnf -y install docker-ce
	sudo systemctl start docker
	sudo systemctl enable docker
fi

echo ''
echo "=============================================="
echo "Done: Configure required repository.          "
echo "=============================================="
echo ''
echo "=============================================="
echo "Done: Install docker-ce.                      "
echo "=============================================="
echo ''
echo "=============================================="
echo "Install User-Settable Docker Containers...    "
echo "=============================================="
echo ''

# Install alpine-nettools
# sudo docker run -d -p 2200:22 raesene/alpine-nettools

# Install odoo ERP
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

