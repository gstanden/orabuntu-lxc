#    Copyright 2015-2016 Gilbert Standen
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

#    v2.8 GLS 20151231

#!/bin/bash

clear

# v2.4 GLS 20151224

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
Config=/var/lib/lxc/ol$OracleRelease/config

sleep 5

clear

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle     "
echo "=============================================="
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | egrep "ol$OracleRelease|ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' 
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
	echo "Starting container $j ..."
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
	}
	PublicIPIterative=$(CheckPublicIPIterative)
	echo $j | grep ol
	if [ $? -eq 0 ]
	then
	sudo bash -c "cat $Config|grep ipv4|cut -f2 -d'='|sed 's/^[ \t]*//;s/[ \t]*$//'|cut -f4 -d'.'|sed 's/^/\./'|xargs -I '{}' sed -i "/ipv4/s/\{}/\.1$OR/g" $Config"
#	sudo sed -i "s/\.39/\.$OracleRelease/g" /var/lib/lxc/ol$OracleRelease/config
#	sudo sed -i "s/\.40/\.$OracleRelease/g" /var/lib/lxc/ol$OracleRelease/config
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
echo "Check directory is ~/Networking               "
echo "Step creates pointers to relevant files.      "
echo "Use links to quickly locate config files.     "
echo "=============================================="
echo ''

if [ ! -e ~/Networking ]
then
mkdir ~/Networking
fi

cd ~/Networking
sudo chmod 755 /etc/scripts/crt_links.sh 
sudo /etc/scripts/crt_links.sh

echo ''
ls -l ~/Networking
echo ''
cd ~/Downloads/orabuntu-lxc-master

echo ''
echo "=============================================="
echo "Management links directory created.           "
echo "=============================================="
echo ''

sleep 5

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
echo "in ~/Networking to learn more about what      "
echo "files and configurations are used for the     "
echo "orabuntu-lxc project.                         "
echo "=============================================="
