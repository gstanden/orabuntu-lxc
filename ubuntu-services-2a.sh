#!/bin/bash

echo ''
echo "============================================"
echo "This script installs lxcora0 files         "
echo "This script creates rsa key for host if one "
echo "does not already exist                      "
echo "============================================"

# echo "============================================"
# echo "This script is re-runnable                  "
# echo "============================================"

sleep 3

clear

echo "============================================"
echo "Checking status of bind9 DNS...             "
echo "============================================"
echo ''
sudo service bind9 status
echo '' 
echo "============================================"
echo "DNS Service check completed.                   "
echo "============================================"

sleep 5

clear

echo "============================================"
echo "Checking status of isc-dhcp-server DHCP...  "
echo "============================================"
echo ''
sudo service isc-dhcp-server status
echo ''
echo "============================================"
echo "DHCP Service check completed.                   "
echo "============================================"

sleep 5

clear

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

echo "============================================"
echo "DNS nslookup test...                        "
echo "Be patient...sometimes!                     "
echo "============================================"
echo ''

nslookup vmem1

echo ''
echo "============================================"
echo "DNS nslookup test completed                 "
echo "============================================"

sleep 5

clear

echo "=================================================="
echo "Extracting lxcora0 container-specific files...   "
echo "=================================================="
echo ''

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/root/packages.sh 
sudo mv /var/lib/lxc/lxcora01/rootfs/root/packages.sh /var/lib/lxc/lxcora0/rootfs/root/packages.sh
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/root/create_users.sh 
sudo mv /var/lib/lxc/lxcora01/rootfs/root/create_users.sh /var/lib/lxc/lxcora0/rootfs/root/create_users.sh
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/root/lxc-services.sh 
sudo mv /var/lib/lxc/lxcora01/rootfs/root/lxc-services.sh /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh
sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh
sudo cp -p ~/Downloads/install_grid.sh /var/lib/lxc/lxcora0/rootfs/root/install_grid.sh
sudo cp -p ~/Downloads/lxc-services.sh /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh
sudo cp -p ~/Downloads/dhclient.conf /var/lib/lxc/lxcora0/rootfs/etc/dhcp/dhclient.conf
sudo chown root:root /var/lib/lxc/lxcora0/rootfs/root/install_grid.sh
sudo chmod 755 /var/lib/lxc/lxcora0/rootfs/root/install_grid.sh
sudo chown root:root /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh
sudo chmod 755 /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh
sudo chown root:root /var/lib/lxc/lxcora0/rootfs/etc/dhcp/dhclient.conf
sudo chmod 644 /var/lib/lxc/lxcora0/rootfs/etc/dhcp/dhclient.conf

echo ''
echo "=================================================="
echo "Extraction container-specific files complete      "
echo "=================================================="

sleep 5

clear

# sudo sed -i 's/BOOTPROTO=dhcp/BOOTPROTO=static/g' /var/lib/lxc/lxcora0/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0

echo "============================================"
echo "Begin MAC Address reset...                  "
echo "Be patient...                               "
echo "============================================"
echo ''

function GetMacAddr11 {
sudo grep hwaddr /var/lib/lxc/lxcora0/config | head -2 | tail -1 | cut -f2 -d'=' | sed 's/ //g'
}

function GetMacAddr12 {
sudo grep hwaddr /var/lib/lxc/lxcora0/config | head -1 | cut -f2 -d'=' | sed 's/ //g'
}

sudo cp -p /var/lib/lxc/lxcora0/config /var/lib/lxc/lxcora0/config.original.bak
OldMacAddr1=$(GetMacAddr11)
sudo grep hwaddr /var/lib/lxc/lxcora0/config | head -2 | tail -1
sudo tar -P --extract --file=lxc-config.tar /var/lib/lxc/lxcora01/config
sudo mv /var/lib/lxc/lxcora01/config /var/lib/lxc/lxcora0/config
NewMacAddr1=$(GetMacAddr12)
sudo grep hwaddr /var/lib/lxc/lxcora0/config | head -1
sudo sed -i "s/$NewMacAddr1/$OldMacAddr1/g" /var/lib/lxc/lxcora0/config
# sudo mv /var/lib/lxc/lxcora01/config /var/lib/lxc/lxcora0/config
sudo grep hwaddr /var/lib/lxc/lxcora0/config | head -1

echo ''
echo "============================================"
echo "MAC Address reset complete                  "
echo "============================================"

sleep 5

clear

sudo chmod 644 /var/lib/lxc/lxcora0/config

echo "============================================="
echo "Create RSA key if it does not already exist  "
echo "Press <Enter> to accept ssh-keygen defaults  "
echo "============================================="
echo ''

if [ ! -e ~/.ssh/id_rsa.pub ]
then
ssh-keygen -t rsa
fi

if [ -e ~/.ssh/known_hosts ]
then
rm ~/.ssh/known_hosts
fi

if [ -e ~/.ssh/authorized_keys ]
then
rm ~/.ssh/authorized_keys
fi

touch ~/.ssh/authorized_keys

if [ -e ~/.ssh/id_rsa.pub ]
then
function GetAuthorizedKey {
cat ~/.ssh/id_rsa.pub
}
AuthorizedKey=$(GetAuthorizedKey)

echo ''
echo 'Authorized Key:'
echo ''
echo $AuthorizedKey 
echo ''
fi

function CheckAuthorizedKeys {
grep -c "$AuthorizedKey" ~/.ssh/authorized_keys
}
AuthorizedKeys=$(CheckAuthorizedKeys)

echo "Results of grep = $AuthorizedKeys"

if [ "$AuthorizedKeys" -eq 0 ]
then
cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

echo ''
echo 'cat of authorized_keys'
echo ''
cat ~/.ssh/authorized_keys

echo ''
echo "============================================="
echo "Create RSA key completed                     "
echo "============================================="

sleep 5

clear

echo "=================================================="
echo "Legacy script cleanups...                         "
echo "=================================================="
echo ''

sudo rm -rf /var/lib/lxc/lxcora01

# sudo rm /etc/network/if-up.d/openvswitch/lxcora0[23456]*
sudo ls -l /etc/network/if-up.d/openvswitch/lxcora0*
# sudo rm /etc/network/if-down.d/openvswitch/lxcora0[23456]*
sudo ls -l /etc/network/if-down.d/openvswitch/lxcora0*

echo ''
echo "=================================================="
echo "Legacy script cleanups complete                   "
echo "=================================================="

sleep 5

clear

echo "==========================================="
echo "Next run ubuntu-services-2b.sh             "
echo "Rebooting in 10 seconds...                 "
echo "<CTRL> + C to exit                         "
echo "==========================================="

sleep 10

sudo reboot
