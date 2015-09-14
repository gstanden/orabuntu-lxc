#!/bin/bash

echo ''
echo "============================================"
echo "This script sets up no-password ssh         "
echo "between the host and the container for root "
echo "============================================"

echo "============================================"
echo "This script is re-runnable                  "
echo "============================================"

echo "============================================"
echo "Initializing container on OpenvSwitch...    "
echo "May take a minute or two...be patient...    "
echo "============================================"

cd /etc/network/if-up.d/openvswitch
sudo sed -i 's/lxcora01/lxcora0/' /var/lib/lxc/lxcora0/config

sudo lxc-start -n lxcora0 > /dev/null 2>&1
sleep 10
sudo lxc-stop -n  lxcora0 > /dev/null 2>&1
sleep 10
sudo lxc-start -n lxcora0 > /dev/null 2>&1

clear

echo ''
echo "============================================"
echo "Checking status of bind9 DNS...             "
echo "============================================"
echo ''
sudo service bind9 status
echo ''
echo "============================================"
echo "DNS Service checks completed.               "
echo "============================================"
echo ''

sleep 5

clear

echo "============================================"
echo "Checking status of isc-dhcp-server DHCP...  "
echo "============================================"
echo ''
sudo service isc-dhcp-server status
echo ''
echo "============================================"
echo "DHCP Service checks completed.                   "
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

sleep 3

clear

echo "============================================"
echo "Begin lxcora0 ping test...                 "
echo "============================================"
echo ''

ping -c 3 lxcora0

echo ''
echo "============================================"
echo "End lxcora0 ping test                      "
echo "============================================"
echo ''

sleep 5

clear

rm ~/.ssh/known_hosts

echo "============================================"
echo "Password:  root                             "
echo "============================================"
echo "============================================"
echo "Output of 'uname -a' in lxcora0..."
echo "============================================"
echo ''
sudo ssh root@lxcora0 uname -a
echo ''
echo "============================================"
echo "End ssh test                                "
echo "============================================"

clear

sleep 3

echo "============================================"
echo "Begin no-password host-container setup      "
echo "Accept defaults on most prompts             "
echo "Overwrite (y/n)? y (answer 'y' if prompted) "
echo "============================================"
echo ''
echo "============================================"
echo "Password for root login is:  root           "
echo "============================================"
echo ''

ssh root@lxcora0 ssh-keygen -t rsa

sudo cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
sudo cp ~/.ssh/authorized_keys /var/lib/lxc/lxcora0/rootfs/root/.ssh/.

echo ''
echo "============================================"
echo "Key setup in containter completed.          "
echo "Continuing in 5 seconds...                  "
echo "============================================"

sleep 5

clear

echo "============================================"
echo "Testing passwordless-ssh for root user      "
echo "============================================"
echo "Output of 'uname -a' in lxcora0..."
echo "============================================"
echo ''

ssh root@lxcora0 uname -a

echo ''
echo "============================================"
echo "Testing passwordless-ssh completed          "
echo "============================================"

sleep 5

clear

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

  echo "============================================"
  echo "!!! Host will reboot in 10 seconds !!!      "
  echo "============================================"
  echo "                                            "
  echo "[ To abort reboot, <ctrl>+c ]               "
  echo "                                            "
  echo "============================================"
  echo "Rebooting in 10 seconds...                  "
  echo "============================================"
  echo "Next script to run: ubuntu-services-3a.sh   "
  echo "============================================"

sleep 10

sudo reboot
