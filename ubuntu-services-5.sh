#    Copyright 2015-2017 Gilbert Standen
#    This file is part of orabuntu-lxc.

#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.

#    v2.4 GLS 20151224
#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container

#!/bin/bash

clear


echo ''
echo "=============================================="
echo "Script: ubuntu-services-5.sh                  "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script starts lxc clones                 "
echo "=============================================="

OracleRelease=$1$2
OracleVersion=$1.$2
OR=$OracleRelease
Config=/var/lib/lxc/oel$OracleRelease/config

sleep 5

clear

echo ''
echo "=============================================="
echo "Make sure all openvswitch interfaces are up   "
echo "=============================================="
echo ''

sudo /etc/network/openvswitch/crt_ovs_sw2.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw3.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw4.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw5.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw6.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw7.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw6.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw8.sh >/dev/null 2>&1
sudo /etc/network/openvswitch/crt_ovs_sw9.sh >/dev/null 2>&1

ifconfig | grep -v 'ns' | egrep -A1 'sw|sx'

sleep 5

echo ''
echo "=============================================="
echo "Openvswitch interfaces are up.                "
echo "=============================================="
echo ''

clear

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle...  "
echo "=============================================="
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | egrep "oel$OracleRelease|ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' 
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
	function GetUbuntuVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
	}
	UbuntuVersion=$(GetUbuntuVersion)
	# GLS 20160707

	echo "Starting container $j ..."
	if [ $UbuntuVersion = 15.04 ] || [ $UbuntuVersion = 15.10 ]
	then
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
	}
	fi
	if [ $UbuntuVersion = 16.04 ]
	then
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f5 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
	}
	fi
	PublicIPIterative=$(CheckPublicIPIterative)
	echo $j | grep oel
	if [ $? -eq 0 ]
	then
	sudo bash -c "cat $Config|grep ipv4|cut -f2 -d'='|sed 's/^[ \t]*//;s/[ \t]*$//'|cut -f4 -d'.'|sed 's/^/\./'|xargs -I '{}' sed -i "/ipv4/s/\{}/\.1$OR/g" $Config"
#	sudo sed -i "s/\.39/\.$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
#	sudo sed -i "s/\.40/\.$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
	fi
	sudo lxc-start -n $j > /dev/null 2>&1
	sleep 5
	i=1
	while [ "$PublicIPIterative" != 10207 ] && [ "$i" -le 10 ]
	do
		echo "Waiting for $j Public IP to come up..."
		sleep 5
		PublicIPIterative=$(CheckPublicIPIterative)
		if [ $i -eq 5 ]
		then
		sudo lxc-stop -n $j
		sleep 2
		echo ''
		sudo /etc/network/openvswitch/veth_cleanups.sh $j
		echo ''
		sleep 2
		sudo lxc-start -n $j
		fi
	sleep 1
	i=$((i+1))
	done
done

echo ''
echo "=============================================="
echo "LXC clone containers for Oracle started.      "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "LXC containers for Oracle started.            "
echo "=============================================="
echo ''

sudo lxc-ls -f

echo ''
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Management links directory creation...        "
echo "Location is:  ~/Manage-Orabuntu-LXC           "
echo "Step creates pointers to relevant files for   "
echo "quickly locating Orabuntu-LXC config files.   "
echo "=============================================="
echo ''

if [ ! -e ~/Manage-Orabuntu-LXC ]
then
mkdir ~/Manage-Orabuntu-LXC
fi

cd ~/Manage-Orabuntu-LXC
sudo chmod 755 /etc/orabuntu-lxc-scripts/crt_links.sh 
sudo /etc/orabuntu-lxc-scripts/crt_links.sh

echo ''
ls -l ~/Manage-Orabuntu-LXC
echo ''
cd ~/Downloads/orabuntu-lxc-master

echo ''
echo "=============================================="
echo "Management links directory created.           "
echo "=============================================="
echo ''

sleep 15

clear

echo ''
echo "=============================================="
echo "Next step is to setup storage...              "
echo "tar -xvf scst-files.tar                       "
echo "cd scst-files                                 "
echo "cat README                                    "
echo "follow the instructions in the README         "
echo "Builds the SCST Linux SAN.                    "
echo "                                              "
echo "Note that deployment management links are     "
echo "in ~/Manage-Orabuntu-LXC to learn more about  "
echo "what files and configurations are used for the"
echo "orabuntu-lxc project.                         "
echo "=============================================="
