#!/bin/bash

clear

echo ''
echo "============================================"
echo "Script:  ubuntu-services-3c.sh NumCon       "
echo "============================================"
echo ''
echo "============================================"
echo "This script is re-runnable.                 "
echo "============================================"
echo ''
echo "============================================"
echo "NumCon is the number of RAC nodes           "
echo "NumCon (small integer)                      "
echo "NumCon defaults to value '2'                "
echo "============================================"

if [ -z $1 ]
then
NumCon=2
else
NumCon=$1
fi

echo ''
echo "============================================"
echo "Number of LXC Container RAC Nodes = $NumCon "
echo "============================================"
echo ''
echo "============================================"
echo "If wrong number of desired RAC nodes, then  "
echo "<ctrl>+c and restart script to set          "
echo "Sleeping 15 seconds...                      "
echo "============================================"
echo ''
echo "============================================"
echo "This script creates oracle-ready lxc clones "
echo "for oracle-ready RAC container nodes        "
echo "============================================"

sleep 5

clear

echo ''
echo "==========================================="
echo "Verify no-password ssh working to lxcora0  "
echo "==========================================="
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a 

echo ''
echo "==========================================="
echo "Verification of no-password ssh completed. "
echo "==========================================="

sleep 5

clear

echo ''
echo "==========================================="
echo "Stopping lxcora0 container...             "
echo "==========================================="
echo ''

sudo lxc-stop -n lxcora0

while [ "$ContainerUp" = 'RUNNING' ]
do
sleep 1
sudo lxc-ls -f
ContainerUp=$(CheckContainerUp)
echo ''
echo $ContainerUp
done

sudo lxc-ls -f

echo ''
echo "==========================================="
echo "Container stopped.                         "
echo "==========================================="

sleep 5

clear

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | more | egrep -v 'lxcora0|lxcora00|lxcora01|lxcora02|lxcora03|lxcora04|lxcora05|lxcora06|lxcora07|lxcora08|lxcora09' | sed 's/$/ /' | tr -d '\n' | sed 's/lxcora0//' | sed 's/  */ /g'
}
ClonedContainersExist=$(CheckClonedContainersExist)

if [ ! -z "$ClonedContainersExist" ]
then
for j in $ClonedContainersExist
do
sudo lxc-destroy -n $j
done
fi

sleep 5

clear

echo '' 
echo "==========================================="
echo "Cloning lxcora0 for reference container   "
echo "==========================================="
echo ''
 
sudo lxc-clone -o lxcora0 -n lxcora00

echo ''
echo "=========================================="
echo "Ref Container lxcora00 clone completed.   " 
echo "=========================================="
echo ''

sleep 3

clear
echo ''
echo "==========================================="
echo "Cloning lxcora0 to $NumCon containers     "
echo "==========================================="
echo ''

sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh

i=10
n=$((NumCon+10))
while [ $i -le "$n" ]
do

echo "Clone Container Name = lxcora$i"
sudo lxc-clone -o lxcora0 -n lxcora"$i"

sudo sed -i "s/lxcora0/lxcora$i/g" /var/lib/lxc/lxcora$i/config
sudo sed -i "s/\.10/\.$i/g" /var/lib/lxc/lxcora$i/config
function GetHostName (){ echo lxcora$i\1; }
HostName=$(GetHostName)
sudo sed -i "s/$HostName/lxcora$i/" /var/lib/lxc/lxcora$i/rootfs/etc/sysconfig/network
# sudo sed -i "s/$HostName/lxcora$i/" /var/lib/lxc/lxcora$i/rootfs/etc/hosts

i=$((i+1))

done

sudo sed -i "s/lxcora001/lxcora00/" /var/lib/lxc/lxcora00/rootfs/etc/sysconfig/network

echo ''
echo "==========================================="
echo "Container cloning completed.               "
echo "==========================================="

echo "==========================================="
echo "LXC and MAC address setups completed.      "
echo "==========================================="

sleep 3

clear

echo ''
echo "==========================================="
echo "Creating OpenvSwitch files ...             "
echo "==========================================="

sudo cp -p ~/Downloads/orabuntu-lxc-master/create-ovs-sw-files-v2.sh.bak /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh
sudo chmod 755 /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh
sudo /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh lxcora $NumCon

echo ''
echo "==========================================="
echo "Creating OpenvSwitch files complete.       "
echo "==========================================="

sleep 5

clear

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-3d.sh      "
echo "==============================================="

sleep 5
