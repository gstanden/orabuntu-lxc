#!/bin/bash

echo "============================================"
echo "Script: ubuntu-services-3d.sh              "
echo "============================================"

echo "============================================"
echo "This script is re-runnable.                 "
echo "============================================"

echo "============================================"
echo "This script starts lxc clones "
echo "============================================"

# GLS 20151127 New test for bind9 status.  Terminates script if bind9 status is not valid.

function GetBindStatus {
sudo service bind9 status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
BindStatus=$(GetBindStatus)

clear

echo ''
echo "============================================"
echo "Checking status of bind9 DNS...             "
echo "============================================"

if [ $BindStatus != 'Active:active(running)' ]
then
	echo ''
	echo "Bind9 is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "Bind9 DNS status ...                        "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "Bind9 DNS status incorrect.                  "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with bind9 and retry script. "
	echo "============================================"
	echo ''
	exit
else
	echo ''
	echo "Bind9 is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "Bind9 DNS status ...                        "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "Bind9 DNS status complete.                  "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================"
echo "Status check of bind9 DNS completed.        "
echo "============================================"
echo ''

# GLS 20151127 New test for bind9 status.  Terminates script if bind9 status is not valid.

# GLS 20151127 New DHCP server checks.  Terminates script if DHCP status is invalid.

clear

function GetDHCPStatus {
sudo service isc-dhcp-server status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
DHCPStatus=$(GetDHCPStatus)

echo ''
echo "============================================"
echo "Checking status of DHCP...                  "
echo "============================================"

if [ $DHCPStatus != 'Active:active(running)' ]
then
	echo ''
	echo "DHCP is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ...                             "
	echo "============================================"
	echo ''
	sudo service isc-dhcp-server status
	echo ''
	echo "============================================"
	echo "DHCP status incorrect.                      "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with DHCP and retry script.  "
	echo "============================================"
	echo ''
	exit
else
	echo ''
	echo "DHCP is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ...                             "
	echo "============================================"
	echo ''
	sudo service isc-dhcp-server status
	echo ''
	echo "============================================"
	echo "DHCP status complete.                       "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================"
echo "Status check of DHCP completed.        "
echo "============================================"
echo ''

# GLS 20151128 New DHCP status check end.

# GLS 20151128 Google ping test start.

clear

echo ''
echo "============================================"
echo "Begin google.com ping test...               "
echo "Be patient...                               "
echo "============================================"
echo ''

ping -c 3 google.com

echo ''
echo "============================================"
echo "End google.com ping test                    "
echo "============================================"
echo ''

sleep 3

clear

function CheckNetworkUp {
ping -c 1 google.com | grep 'packet loss' | cut -f1 -d'%' | cut -f6 -d' ' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
NetworkUp=$(CheckNetworkUp)

echo $NetworkUp

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

clear

echo ''
echo "============================================"
echo "DNS nslookup test...                        "
echo "Be patient...sometimes!                     "
echo "============================================"
echo ''

function GetLookup {
nslookup vmem1 | grep 10.207.39.1 | sed 's/\.//g' | sed 's/: //g'
}
Lookup=$(GetLookup)

if [ $Lookup != 'Address10207391' ]
then
	echo ''
	echo "DNS Lookups NOT working."
	echo ''
	echo "============================================"
	echo "DNS lookups status ...                             "
	echo "============================================"
	nslookup vmem1
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with DNS and retry script.  "
	echo "============================================"
	exit
else
	echo ''
	echo "DNS Lookups are working properly."
	echo ''
	echo "============================================"
	echo "DNS Lookup ...                             "
	echo "============================================"
	nslookup vmem1
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================"
echo "Status check of DNS Lookups completed.      "
echo "============================================"
echo ''

sleep 5

clear

sudo lxc-start -n lxcora0 > /dev/null 2>&1

sleep 5

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
echo "Bringing up public ip on lxcora0...         "
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

sleep 7
clear

echo ''
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
echo "This step creates pointers to relevant files.   "
echo "Use links to quickly locate relevant files.     "
echo "================================================"
echo ''
ls -l crt_links.sh
echo ''

sleep 5
 
sudo ./crt_links.sh
echo ''
ls -l ~/Networking
echo ''
cd ~/Downloads
pwd
sleep 5

clear

echo ''
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
sleep 20
# sudo lxc-stop -n $j
# sleep 5
# sudo lxc-start -n $j
# sleep 20
sudo lxc-ls -f | grep lxcora$j
done

echo "================================================"
echo "Waiting for final container initialization...   " 
echo "================================================"
echo "================================================"
echo "LXC containers for Oracle started.              "
echo "================================================"

sudo lxc-ls -f

# This step occurs before clone now. Only needs to run once pre-clone for lxcora0.
# ssh root@lxcora0 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora2 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora3 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora4 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora5 usermod --password `perl -e "print crypt('grid','grid');"` grid
# ssh root@lxcora6 usermod --password `perl -e "print crypt('grid','grid');"` grid

echo "================================================"
echo "Stopping the containers in 10 seconds           "
echo "Next step is to setup storage...                "
echo "tar -xvf scst-files.tar                         "
echo "cd scst-files                                   "
echo "cat README                                      "
echo "follow the instructions in the README           "
echo "Builds the SCST Linux SAN.                      "
echo "================================================"

sleep 15

~/Downloads/stop_containers.sh

