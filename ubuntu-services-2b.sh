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

sleep 5

sudo ovs-vsctl del-br sw1 >/dev/null 2>&1
sudo ovs-vsctl del-br sw2 >/dev/null 2>&1
sudo ovs-vsctl del-br sw3 >/dev/null 2>&1
sudo ovs-vsctl del-br sw4 >/dev/null 2>&1
sudo ovs-vsctl del-br sw5 >/dev/null 2>&1
sudo ovs-vsctl del-br sw6 >/dev/null 2>&1
sudo ovs-vsctl del-br sw7 >/dev/null 2>&1
sudo ovs-vsctl del-br sw8 >/dev/null 2>&1
sudo ovs-vsctl del-br sw9 >/dev/null 2>&1
sudo ovs-vsctl del-br sx1 >/dev/null 2>&1

sudo /etc/network/if-up.d/openvswitch-net

sudo service bind9 stop
sudo service bind9 start

sudo service isc-dhcp-server stop

sleep 5

sudo service isc-dhcp-server start

sudo lxc-start -n lxcora0

clear

echo ''
echo "============================================"
echo "Initializing container on OpenvSwitch...    "
echo "============================================"

cd /etc/network/if-up.d/openvswitch
sudo sed -i 's/lxcora01/lxcora0/' /var/lib/lxc/lxcora0/config

sudo lxc-start -n lxcora0 > /dev/null 2>&1
sleep 10
sudo lxc-stop -n  lxcora0 > /dev/null 2>&1
sleep 10
sudo lxc-start -n lxcora0 > /dev/null 2>&1

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

sudo lxc-ls -f

echo ''
echo "============================================"
echo "Container stopped.                          "
echo "============================================"

sleep 5

clear

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-3a.sh      "
echo "==============================================="

sleep 5
