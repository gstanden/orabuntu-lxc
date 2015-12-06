#!/bin/bash

echo ''
echo "============================================"
echo "Script: ubuntu-services-2b.sh               "
echo "                                            "
echo "This script sets up no-password ssh         "
echo "between the host and the container for root "
echo "============================================"

echo "============================================"
echo "This script is re-runnable                  "
echo "============================================"

echo ''

ssh-add > /dev/null 2>&1

sleep 5

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

echo ''
echo "============================================"
echo "Initializing container on OpenvSwitch...    "
echo "============================================"

cd /etc/network/if-up.d/openvswitch
sudo sed -i 's/lxcora01/lxcora0/' /var/lib/lxc/lxcora0/config

sudo lxc-start -n lxcora0 > /dev/null 2>&1
# sleep 10
# sudo lxc-stop -n  lxcora0 > /dev/null 2>&1
# sleep 10
# sudo lxc-start -n lxcora0 > /dev/null 2>&1

function CheckContainerUp {
sudo lxc-ls -f | grep lxcora0 | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
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

sleep 5

echo ''
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
sleep 1
done

echo ''
echo "============================================" 
echo "Public IP is up on lxcora0                 "
echo ''
sudo lxc-ls -f
echo ''
echo "============================================"
echo "Container Up.                               "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Begin lxcora0 ping test...                 "
echo "============================================"
echo ''

ping -c 3 lxcora0

echo ''
echo "============================================"
echo "End lxcora0 ping test                       "
echo "============================================"
echo ''

sleep 5

clear

echo ''
echo "============================================"
echo "Check Authorized Keys File ...              "
echo "============================================"
echo ''

if [ -e ~/.ssh/known_hosts ]
then
rm ~/.ssh/known_hosts
fi

function GetPublicKey {
cat ~/.ssh/id_rsa.pub | cut -f2 -d' '
}
PublicKey=$(GetPublicKey)
echo ''
echo 'PublicKey = '$PublicKey

function CheckAuthorizedKeys {
grep -c $PublicKey ~/.ssh/authorized_keys | sed 's/^[ \t]*//;s/[ \t]*$//'
}
AuthorizedKeys=$(CheckAuthorizedKeys)
echo ''
echo 'AuthorizedKeys = '$AuthorizedKeys
echo ''

if [ "$AuthorizedKeys" -eq 0 ]
then
echo "sudo cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
else
cat ~/.ssh/authorized_keys
fi

sudo rm -rf /var/lib/lxc/lxcora0/rootfs/root/.ssh/*
sudo mkdir -p /var/lib/lxc/lxcora0/rootfs/root/.ssh/
sudo cp -p ~/.ssh/authorized_keys /var/lib/lxc/lxcora0/rootfs/root/.ssh/.

echo ''
echo "============================================"
echo "Check Authorized Keys File completed.       "
echo "============================================"
echo ''

sleep 5

clear

echo ''
echo "============================================"
echo "Password:  root                             "
echo "============================================"
echo "============================================"
echo "Output of 'uname -a' in lxcora0..."
echo "============================================"
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a

echo ''
echo "============================================"
echo "End ssh test                                "
echo "============================================"

sleep 5

clear

# echo ''
# echo "============================================"
# echo "Begin no-password host-container setup      "
# echo "Accept defaults on most prompts             "
# echo "Overwrite (y/n)? y (answer 'y' if prompted) "
# echo "============================================"
# echo ''
# echo "============================================"
# echo "Password for root login is:  root           "
# echo "============================================"
# echo ''

# ssh root@lxcora0 ssh-keygen -f id_rsa -t rsa -N ''

# echo ''
# echo "============================================"
# echo "Key setup in containter completed.          "
# echo "Continuing in 10 seconds...                  "
# echo "============================================"

echo ''
echo "============================================"
echo "Testing passwordless-ssh for root user      "
echo "============================================"
echo "Output of 'uname -a' in lxcora0..."
echo "============================================"
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a

echo ''
echo "============================================"
echo "Testing passwordless-ssh completed          "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Begin lxcora0 ping test...                 "
echo "============================================"
echo ''

ping -c 3 lxcora0

echo ''
echo "============================================"
echo "End lxcora0 ping test                      "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Stopping lxcora0 container...              "
echo "============================================"
echo ''
sleep 2
sudo lxc-stop -n lxcora0
echo ''

while [ "$ContainerUp" = 'RUNNING' ]
do
sleep 1
sudo lxc-ls -f
ContainerUp=$(CheckContainerUp)
echo ''
echo $ContainerUp
echo ''
done
echo ''
echo "============================================"
echo "Container stopped.                          "
echo "============================================"

sleep 5

clear

echo ''
# echo "============================================"
# echo "!!! Host will reboot in 10 seconds !!!      "
# echo "============================================"
# echo "                                            "
# echo "[ To abort reboot, <ctrl>+c ]               "
# echo "                                            "
# echo "============================================"
# echo "Rebooting in 10 seconds...                  "
echo "============================================"
echo "Next script to run: ubuntu-services-3a.sh   "
echo "============================================"

# sleep 10

# sudo reboot
