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

clear

echo ''
echo "============================================"
echo "Initializing container on OpenvSwitch...    "
echo "============================================"

cd /etc/network/if-up.d/openvswitch
sudo sed -i 's/lxcora01/lxcora0/' /var/lib/lxc/lxcora0/config

sudo lxc-start -n lxcora0

sleep 5

function CheckContainerUp {
sudo lxc-ls -f | grep lxcora0 | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

if [ $ContainerUp != 'RUNNING' ]
then
sudo lxc-start -n lxcora0
fi

function CheckPublicIP {
sudo lxc-ls -f | sed 's/  */ /g' | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

sleep 5

echo ''
echo "=============================================="
echo "Bringing up public ip on lxcora0...           "
echo "=============================================="
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
echo "==============================================" 
echo "Public IP is up on lxcora0                    "
echo ''
sudo lxc-ls -f
echo ''
echo "=============================================="
echo "Container Up.                                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "===============================================" 
echo "Container lxcora0 ping test...                 "
echo "==============================================="
echo ''

ping -c 3 google.com

function CheckNetworkUp {
ping -c 3 lxcora0 | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -lt 5 ]
do
NetworkUp=$(CheckNetworkUp)
let n=$n+1
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "Container lxcora0 not reliably pingable.      "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Container lxcora0 is pingable.                "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "============================================"
echo "Output of 'uname -a' in lxcora0...          "
echo "============================================"
echo ''

ssh-add
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a

echo ''
echo "============================================"
echo "End ssh test                                "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Testing passwordless-ssh for root user      "
echo "============================================"
echo "Output of 'uname -a' in lxcora0..."
echo "============================================"
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a
if [ $? -ne 0 ]
then
echo ''
echo "============================================"
echo "No-password ssh to lxcora0 has issue(s).    "
echo "No-password ssh to lxcora0 must succeed.    "
echo "Fix issues retry script.                    "
echo "Script exiting.                             "
echo "============================================"
exit
fi
echo ''
echo "============================================"
echo "No-password ssh test to lxcora0 successful. "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Next script to run: ubuntu-services-3a.sh   "
echo "============================================"

sleep 5
