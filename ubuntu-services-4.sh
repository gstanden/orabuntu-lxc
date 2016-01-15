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
OR=$OracleRelease

if [ -z $3 ]
then
NumCon=2
else
NumCon=$3
fi

ContainerPrefix=ora$1$2c

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
echo "Stopping ol$OracleRelease container...       "
echo "(OL 5 shutdown can take awhile...patience)   "
echo "(OL 6 and OL 7 are relatively fast shutdown)"
echo "=============================================="
echo ''

function CheckContainerUp {
sudo lxc-ls -f | grep ol$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)
sudo lxc-stop -n ol$OracleRelease > /dev/null 2>&1

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
	sudo bash -c "cat /var/lib/lxc/ol$OR/config.oracle /var/lib/lxc/ol$OR/config.asm.flex.cluster > /var/lib/lxc/ol$OR/config"
	sudo sed -i "s/ContainerName/ol$OR/g" /var/lib/lxc/ol$OR/config
fi

if [ $AddPrivateNetworks = 'n' ] || [ $AddPrivateNetworks = 'N' ]
then
	sudo cp -p /var/lib/lxc/ol$OracleRelease/config.oracle /var/lib/lxc/ol$OracleRelease/config
	sudo sed -i "s/ContainerName/ol$OracleRelease/g" /var/lib/lxc/ol$OracleRelease/config
fi

echo ''
echo "=============================================="
echo "Configure 12c ASM Flex Cluster completed.     "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Cloning ol$OracleRelease to $NumCon containers         "
echo "=============================================="
echo ''

sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/ol$OracleRelease/rootfs/root/lxc-services.sh

function GetHighestContainerIndex {
sudo ls /var/lib/lxc | more | grep ora | cut -c7-9 | sort -n | tail -1
}
HighestContainerIndex=$(GetHighestContainerIndex)

if [ -z $HighestContainerIndex ]
then
HighestContainerIndex=0
fi

if [ $HighestContainerIndex -lt 10 ]
then
let i=10
let NewHighestContainerIndex=$i+$NumCon-1
fi

if [ $HighestContainerIndex -ge 10 ]
then
let i=$HighestContainerIndex+1
let NewHighestContainerIndex=$i+$NumCon-1
fi

sleep 5

while [ $i -le "$NewHighestContainerIndex" ]
do
echo "Clone Container Name = $ContainerPrefix$i"
sudo lxc-clone -o ol$OracleRelease -n $ContainerPrefix$i
sudo sed -i "s/ol$OracleRelease/$ContainerPrefix$i/g" /var/lib/lxc/$ContainerPrefix$i/config
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
echo "      Reset config file for ol$OracleRelease."
echo "Removes ASM and RAC private network interfaces"
echo "      from seed container ol$OracleRelease   "
echo "(cloned containers are not affected by reset) "
echo "=============================================="
echo ''

read -e -p "Reset Seed Container ol$OracleRelease to single DHCP interface ? [Y/N]   " -i "Y" ResetSingleDHCPInterface

if [ $ResetSingleDHCPInterface = 'y' ] || [ $ResetSingleDHCPInterface = 'Y' ]
then
sudo cp -p /var/lib/lxc/ol$OracleRelease/config.oracle /var/lib/lxc/ol$OracleRelease/config
sudo sed -i "s/ContainerName/ol$OracleRelease/g" /var/lib/lxc/ol$OracleRelease/config
fi

echo ''
echo "=============================================="
echo "Config file reset successful.                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: ubuntu-services-5.sh      "
echo "=============================================="

sleep 5
