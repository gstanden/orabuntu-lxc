#!/bin/bash

clear

echo ''
echo "============================================"
echo "ubuntu-services-2a.sh script                "
echo ''
echo "This script installs lxcora0 files          "
echo "This script creates rsa key for host if one "
echo "does not already exist                      "
echo "============================================"
echo ''
echo "============================================"
echo "This script is re-runnable                  "
echo "============================================"
echo ''

sleep 5

clear

echo ''
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
sudo cp -p ~/Downloads/orabuntu-lxc-master/install_grid.sh /var/lib/lxc/lxcora0/rootfs/root/install_grid.sh
sudo cp -p ~/Downloads/orabuntu-lxc-master/lxc-services.sh /var/lib/lxc/lxcora0/rootfs/root/lxc-services.sh
sudo cp -p ~/Downloads/orabuntu-lxc-master/dhclient.conf /var/lib/lxc/lxcora0/rootfs/etc/dhcp/dhclient.conf
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

echo ''
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

# GLS 20151126 Added to support symlinked multipath storage in /dev/mapper, as well as older style device node multipath storage in /dev/mapper
sudo sed -i '/lxc.mount.entry = \/dev\/mapper \/var\/lib\/lxc\/lxcora01\/rootfs\/dev\/mapper none defaults,bind,create=dir 0 0/a lxc.mount.entry = \/dev \/var\/lib\/lxc\/lxcora01\/rootfs\/dev none defaults,bind,create=dir 0 0' /var/lib/lxc/lxcora01/config

sudo cp /var/lib/lxc/lxcora01/config /var/lib/lxc/lxcora0/config
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

echo ''
echo "============================================="
echo "Create RSA key if it does not already exist  "
echo "Press <Enter> to accept ssh-keygen defaults  "
echo "============================================="
echo ''

if [ ! -e ~/.ssh/id_rsa.pub ]
then
# ssh-keygen -t rsa
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
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

echo ''
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

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-2b.sh      "
echo "==============================================="

sleep 5
