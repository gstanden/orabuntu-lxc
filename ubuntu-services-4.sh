#!/bin/bash

clear

# v2.1

echo ''
echo "=============================================="
echo "Script:  ubuntu-services-4.sh NumCon          "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "NumCon is the number of RAC nodes             "
echo "NumCon (small integer)                        "
echo "NumCon defaults to value '2'                  "
echo "=============================================="

OracleRelease=$1$2
OracleVersion=$1.$2

if [ -z $3 ]
then
NumCon=2
else
NumCon=$3
fi

ContainerPrefix=$4

echo ''
echo "=============================================="
echo "Number of LXC Container RAC Nodes = $NumCon   "
echo "=============================================="
echo ''
echo "=============================================="
echo "If wrong number of desired RAC nodes, then    "
echo "<ctrl>+c and restart script to set            "
echo "Sleeping 15 seconds...                        "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script creates oracle-ready lxc clones   "
echo "for oracle-ready RAC container nodes          "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Stopping oel$OracleRelease container...                 "
echo "=============================================="
echo ''

function CheckContainerUp {
sudo lxc-ls -f | grep oel$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)
sudo lxc-stop -n oel$OracleRelease > /dev/null 2>&1

while [ "$ContainerUp" = 'RUNNING' ]
do
sleep 1
ContainerUp=$(CheckContainerUp)
done

sudo lxc-ls -f

echo ''
echo "=============================================="
echo "Container stopped.                            "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Configure 12c ASM Flex Cluster (optional)     "
echo "=============================================="
echo ''

read -e -p "Add ASM Private Networks and RAC Private Networks ? [Y/N]   " -i "Y" AddPrivateNetworks

if [ $AddPrivateNetworks = 'y' ] || [ $AddPrivateNetworks = 'Y' ]
then
	sudo sed -i "s/ContainerName/oel$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config.asm.flex.cluster
	sudo bash -c "cat /var/lib/lxc/oel$OracleRelease/config /var/lib/lxc/oel$OracleRelease/config.asm.flex.cluster > /var/lib/lxc/oel$OracleRelease/config.asm.flex"
	sudo mv /var/lib/lxc/oel$OracleRelease/config.asm.flex /var/lib/lxc/oel$OracleRelease/config
fi

echo ''
echo "=============================================="
echo "Configure 12c ASM Flex Cluster completed.     "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Cloning oel$OracleRelease to $NumCon containers         "
echo "=============================================="
echo ''

sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/oel$OracleRelease/rootfs/root/lxc-services.sh

function GetHighestContainerIndex {
sudo ls /var/lib/lxc | more | grep -v oel | sort | tail -1 | cut -c7-9
}
HighestContainerIndex=$(GetHighestContainerIndex)

if [ -z $HighestContainerIndex ]
then
HighestContainerIndex=0
fi

if [ $HighestContainerIndex -lt 10 ]
then
HighestContainerIndex=10
i=$HighestContainerIndex
else
i=$((HighestContainerIndex+1))
fi

NewHighestContainerIndex=$((NumCon+HighestContainerIndex))

while [ $i -le "$NewHighestContainerIndex" ]
do
echo "Clone Container Name = $ContainerPrefix$i"
sudo lxc-clone -o oel$OracleRelease -n $ContainerPrefix$i
sudo sed -i "s/oel$OracleRelease/$ContainerPrefix$i/g" /var/lib/lxc/$ContainerPrefix$i/config
sudo sed -i "s/\.10/\.$i/g" /var/lib/lxc/$ContainerPrefix$i/config
sudo sed -i 's/sx1/sw1/g' /var/lib/lxc/$ContainerPrefix$i/config
function GetHostName (){ echo $ContainerPrefix$i\1; }
HostName=$(GetHostName)
sudo sed -i "s/$HostName/$ContainerPrefix$i/" /var/lib/lxc/$ContainerPrefix$i/rootfs/etc/sysconfig/network
i=$((i+1))
done

echo ''
echo "=============================================="
echo "Container cloning completed.                  "
echo "=============================================="

echo "=============================================="
echo "LXC and MAC address setups completed.         "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Creating OpenvSwitch files ...                "
echo "=============================================="

sleep 5

sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefix $NumCon $NewHighestContainerIndex

echo ''
echo "=============================================="
echo "Creating OpenvSwitch files complete.          "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: ubuntu-services-5.sh      "
echo "=============================================="

sleep 5
