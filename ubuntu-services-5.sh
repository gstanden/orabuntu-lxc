#!/bin/bash

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

sleep 5

clear

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle     "
echo "=============================================="
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | grep -v oel | sort -V | sed 's/$/ /' | tr -d '\n' 
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
	echo "Starting container $j ..."
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
	}
	PublicIPIterative=$(CheckPublicIPIterative)
	sudo lxc-start -n $j > /dev/null 2>&1
	sleep 5
	i=1
	while [ "$PublicIPIterative" != 1020739 ] && [ "$i" -le 10 ]
	do
		echo "Waiting for $j Public IP to come up..."
		sleep 5
		PublicIPIterative=$(CheckPublicIPIterative)
		if [ $i -eq 5 ]
		then
		sudo lxc-stop -n $j
		sleep 5
		function GetVethCleanupsIterative {
		sudo ip link show | grep $j | cut -f2 -d':' | sed 's/ //g' | cut -f1 -d'@' | sed 's/^/sudo ip link del "/' | sed 's/$/";/' > ~/veth_cleanups_$j.sh
		}
		if [ -e ~/veth_cleanups_$j.sh ]
		then
		sudo rm ~/veth_cleanups_$j.sh 
		fi
		$(GetVethCleanupsIterative)
		echo ''
		sudo ls -l ~/veth_cleanups_$j.sh
		echo ''
		sudo cat ~/veth_cleanups_$j.sh
		echo ''
		sudo chown root:root ~/veth_cleanups_$j.sh
		sudo chmod 755 ~/veth_cleanups_$j.sh
		sudo mv ~/veth_cleanups_$j.sh /etc/network/openvswitch/.
		sleep 5
		sudo /etc/network/openvswitch/veth_cleanups_$j.sh
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
sudo chmod 755 /etc/script/crt_links.sh 
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
