#!/bin/bash

echo "============================================"
echo "Usage: ./ubuntu-services-3d.sh              "
echo "============================================"

echo "============================================"
echo "This script is re-runnable.                 "
echo "============================================"

echo "============================================"
echo "This script starts lxc clones "
echo "============================================"

sudo lxc-start -n lxcora0 > /dev/null 2>&1

echo ''
echo "============================================"
echo "Checking status of bind9 DNS...             "
echo "============================================"
echo ''
sudo service bind9 status
echo '' 
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

function CheckPublicIP {
sudo lxc-ls -f | sed 's/  */ /g' | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

if [ $ContainerUp != 'RUNNING' ]
then
sudo lxc-stop  -n lxcora0
sudo lxc-start -n lxcora0
sleep 20
fi

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
sudo lxc-ls -f | sed 's/  */ /g' | grep RUNNING | cut -f3 -d' ' | sed 's/,//'
sleep 5
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

sleep 5
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

sleep 5

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

if [ ! -e ~/Networking ]
then
mkdir ~/Networking
fi
 
cp -p ~/Downloads/crt_links_v2.sh  ~/Networking/crt_links.sh
sudo chown root:root ~/Networking/crt_links.sh

cd ~/Networking
pwd
sleep 5
echo ''
echo "================================================"
echo "Check directory is ~/Networking                 "
echo "Verify crt_links.sh exists and has 755 mode     "
echo "================================================"
echo ''
ls -l crt_links.sh
echo ''
sleep 15
 
sudo ./crt_links.sh
echo ''
ls -l ~/Networking
echo ''
cd ~/Downloads
pwd
sleep 10 

clear

echo "================================================"
echo "Starting LXC clone containers for Oracle        "
echo "60 seconds/container for correct DHCP assignment"
echo "================================================"
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/lxcora0 //' | sed 's/lxcora00 //' | sed 's/lxcora01 //'
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
echo "Starting container $j ..."
# echo $j
# echo "next command will be:   sudo lxc-start -n $j"
echo ''
sudo lxc-start -n $j
sleep 15
sudo lxc-stop -n $j
sleep 5
sudo lxc-start -n $j
sleep 20
sudo lxc-ls -f | grep lxcora$j
done

echo "================================================"
echo "Waiting for final container initialization...   " 
echo "================================================"
echo ''
echo "================================================"
echo "LXC containers for Oracle started.              "
echo "================================================"
echo ''

sudo lxc-ls -f

# This step occurs before clone now. Only needs to run once pre-clone for lxcora0.
# ssh root@lxcora0 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora2 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora3 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora4 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora5 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora6 usermod --password `perl -e "print crypt('grid','grid');"` grid
