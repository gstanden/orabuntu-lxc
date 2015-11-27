#!/bin/bash

echo "============================================"
echo "Usage: ./ubuntu-services-3c.sh NumCon       "
echo "============================================"

echo "============================================"
echo "This script is re-runnable.                 "
echo "============================================"

echo "============================================"
echo "NumCon is the number of RAC nodes           "
echo "NumCon (small integer)                      "
echo "NumCon defaults to value '2'                "
echo "============================================"

# cd /etc/network/if-up.d/openvswitch
# sudo rm lxcora07* lxcora08* lxcora09* lxcora010*
# cd /etc/network/if-down.d/openvswitch
# sudo rm lxcora07* lxcora08* lxcora09* lxcora010*

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

sleep 15

echo ''
echo "============================================"
echo "This script creates oracle-ready lxc clones "
echo "for oracle-ready RAC container nodes        "
echo "============================================"

sudo lxc-start -n lxcora0 > /dev/null 2>&1

echo ''
echo "============================================"
echo "Checking status of bind9 DNS...             "
echo "============================================"
echo ''

sudo service bind9 status

sleep 5

echo ''
echo "============================================"
echo "Checking status of isc-dhcp-server DHCP...  "
echo "============================================"
echo ''

sudo service isc-dhcp-server status

echo ''
echo "============================================"
echo "Services checks completed.                  "
echo "============================================"

sleep 5

clear
echo "============================================"
echo "Begin google.com ping test...               "
echo "============================================"
echo ''

ping -c 3 google.com

echo ''
echo "============================================"
echo "End google.com ping test                    "
echo "============================================"
echo ''

sleep 3

function CheckNetworkUp {
ping -c 1 google.com | grep 'packet loss' | cut -f1 -d'%' | cut -f6 -d' ' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
NetworkUp=$(CheckNetworkUp)
if [ "$NetworkUp" -ne 0 ]
then
echo ''
echo "============================================"
echo "Destination google.com is not pingable      "
echo "Address network issues and retry script     "
echo "Script exiting                              "
echo "============================================"
echo ''
exit
fi

function CheckContainerUp {
sudo lxc-ls -f | grep lxcora0 | sed 's/  */ /g' | grep RUNNING  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

if [ $ContainerUp != 'RUNNING' ]
then
sudo lxc-stop  -n lxcora0
sudo lxc-start -n lxcora0
fi

function CheckPublicIP {
sudo lxc-ls -f | sed 's/  */ /g' | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

clear

echo "============================================"
echo "Bringing up public ip on lxcora0...        "
echo "============================================"
echo ''

sleep 5

while [ "$PublicIP" -ne 1020739 ]
do
PublicIP=$(CheckPublicIP)
echo "Waiting for lxcora0 Public IP to come up..."
sudo lxc-ls -f | sed 's/  */ /g' | grep lxcora0 | grep RUNNING | cut -f3 -d' ' | sed 's/,//'
sleep 1
done

echo ''
echo "===========================================" 
echo "Public IP is up on lxcora0                "
echo ''
sudo lxc-ls -f
echo ''
echo "==========================================="
echo "Container Up.                              "
echo "==========================================="

sleep 3
clear

echo "==========================================="
echo "Verify no-password ssh working to lxcora0 "
echo "==========================================="
echo ''

ssh root@lxcora0 uname -a

echo ''
echo "==========================================="
echo "Verification of no-password ssh completed. "
echo "==========================================="

sleep 4

clear

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
echo ''
echo "==========================================="
echo "Container stopped.                         "
echo "==========================================="

sleep 5

clear

echo "!!! WARNING !!!"

echo "===================================================="
echo "Optional Destruction of cloned containers ( Y / N ) "
echo "===================================================="

# GLS 20151126 Modified with egrep to exempt containers numbered lower than 10 from destruction detection.
# GLS This software starts container cloning at lxcora10 and above.  
# GLS Containers lxcora09 and below can be used for one-off clones as needed.
# GLS Containers lxcora0 and lxcora01 are "special" congtainers used by the scripting.
# GLS Container lxcora00 is the Oracle "reference container" which is fully prepped for Oracle and can be used for one-off clones using lxc-clone command.

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | more | egrep -v 'lxcora0|lxcora00|lxcora01|lxcora02|lxcora03|lxcora04|lxcora05|lxcora06|lxcora07|lxcora08|lxcora09' | sed 's/$/ /' | tr -d '\n' | sed 's/lxcora0//' | sed 's/  */ /g'
}
ClonedContainersExist=$(CheckClonedContainersExist)

echo ''
echo "ClonedContainersExist = $ClonedContainersExist"
echo ''

sleep 10

echo "Existing containers in the set { $ClonedContainersExist } have been found."
echo "These containers MAY match the names of containers that are about to be created (if any are lxcora10 or higher, such as lxcora11, etc.."
echo "Please answer Y to destroy the existing containers or N to keep them."
echo "Note that scripted container creation starts at "lxcora10" therefore containers lxcora09 and lower do NOT need to be destroyed prior to continuing with script.
echo "Any containers lxcora10 and higher should be destroyed at this point to avoid overwrites or other script anomalies.

echo "!!! WARNING:  ANSWERING Y WILL DESTROY EXISTING CONTAINERS !!!"

echo "Destroy existing containers?  [ Y | N ]:"
read input_variable
echo "You entered: $input_variable"

echo "<ctrl>+c to exit program and abort container destruction"
echo "sleeping for 5 seconds..."

sleep 5

if [ ! -z "$ClonedContainersExist" ]
then
for j in $ClonedContainersExist
do
echo "Container Name = $j"
echo "<ctrl>+c to exit"

if [ "$input_variable" = 'N' ]
then
echo "sudo lxc-destroy -n $j"
echo ''
echo "Container NOT destroyed"
echo ''
fi

if [ $input_variable = 'Y' ]
then
echo "Destroying container in 5 seconds..."
sleep 5
sudo lxc-destroy -n $j
fi
done
fi
 
echo "==========================================="
echo "Cloning lxcora0 for reference container   "
echo "==========================================="
echo ''
 
sudo lxc-clone -o lxcora0 -n lxcora00
sleep 5

echo "=========================================="
echo "Ref Container lxcora00 clone completed.   " 
echo "=========================================="
echo ''

sleep 3

clear
echo "==========================================="
echo "Cloning lxcora0 to $NumCon containers     "
echo "==========================================="

sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh

i=10
n=$((NumCon+10))
while [ $i -le "$n" ]
do

echo "Clone Container Name = lxcora$i"
sudo lxc-clone -o lxcora0 -n lxcora"$i"
echo "Sleeping 5 seconds..."
sleep 5

sudo sed -i "s/lxcora0/lxcora$i/g" /var/lib/lxc/lxcora$i/config
sudo sed -i "s/\.10/\.$i/g" /var/lib/lxc/lxcora$i/config
function GetHostName (){ echo lxcora$i\1; }
HostName=$(GetHostName)
sudo sed -i "s/$HostName/lxcora$i/" /var/lib/lxc/lxcora$i/rootfs/etc/sysconfig/network
# sudo sed -i "s/$HostName/lxcora$i/" /var/lib/lxc/lxcora$i/rootfs/etc/hosts

i=$((i+1))

done

sudo sed -i "s/lxcora001/lxcora00/" /var/lib/lxc/lxcora00/rootfs/etc/sysconfig/network

echo "==========================================="
echo "Container cloning completed.               "
echo "==========================================="

echo "==========================================="
echo "LXC and MAC address setups completed.      "
echo "==========================================="

sleep 3

clear

echo "==========================================="
echo "Creating OpenvSwitch files ...             "
echo "==========================================="

sudo cp -p ~/Downloads/create-ovs-sw-files-v2.sh.bak /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh
sudo chmod 755 /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh
sudo /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh lxcora $NumCon

echo "==========================================="
echo "Now run ubuntu-services-3d.sh              "
echo "==========================================="
