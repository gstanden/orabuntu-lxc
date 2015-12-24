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

sleep 5

clear

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle     "
echo "=============================================="
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | egrep "oel$OracleRelease|ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' 
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
	echo "Starting container $j ..."
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
	}
	PublicIPIterative=$(CheckPublicIPIterative)
	echo $j | grep oel
	if [ $? -eq 0 ]
	then
	sudo sed -i "s/\.39/\.$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
	sudo sed -i "s/\.40/\.$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
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
