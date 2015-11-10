#!/bin/bash

echo "============================================"
echo "Usage: ./ubuntu-services-3b.sh              "
echo "============================================"

echo "============================================"
echo "This script extracts customzed files to     "
echo "the container required for running Oracle   "
echo "============================================"

echo "============================================"
echo "This script is re-runnable                  "
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

echo "================================================"
echo "Logged into LXC container lxcora0              "
echo "Installing files and packages for Oracle...     "
echo "================================================"
echo ''

ssh root@lxcora0 /root/packages.sh
ssh root@lxcora0 /root/create_users.sh
ssh root@lxcora0 /root/lxc-services.sh
ssh root@lxcora0 /root/install_grid.sh

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm
sudo mkdir -p /var/lib/lxc/lxcora0/rootfs/home/grid/grid/rpm
sudo mv /var/lib/lxc/lxcora01/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm /var/lib/lxc/lxcora0/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm
sudo cp -p /var/lib/lxc/lxcora0/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm /var/lib/lxc/lxcora0/rootfs/root/.

ssh root@lxcora0 rpm -Uvh /home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm

# sudo tar -P --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora0/rootfs/home/grid/.bashrc
# sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/oracle/.bashrc
sudo cp ~/Downloads/oracle.bash_profile /var/lib/lxc/lxcora0/rootfs/home/oracle/.bash_profile
sudo cp ~/Downloads/oracle.bashrc /var/lib/lxc/lxcora0/rootfs/home/oracle/.bashrc
sudo cp ~/Downloads/oracle.kshrc /var/lib/lxc/lxcora0/rootfs/home/oracle/.kshrc

sudo cp -p ~/Downloads/rc.local /var/lib/lxc/lxcora0/rootfs/etc/rc.local
ssh root@lxcora0 chown grid:oinstall /home/grid/grid
ssh root@lxcora0 chown grid:oinstall /home/grid/grid/rpm
scp edit_bashrc root@lxcora0:/home/grid/.
ssh root@lxcora0 chown grid:oinstall /home/grid/edit_bashrc
ssh root@lxcora0 chmod 755 /home/grid/edit_bashrc
ssh root@lxcora0 usermod --password `perl -e "print crypt('grid','grid');"` grid
ssh root@lxcora0 usermod --password `perl -e "print crypt('oracle','oracle');"` oracle
ssh root@lxcora0 usermod -g oinstall oracle
ssh root@lxcora0 chown oracle:oinstall /home/oracle/.bash_profile
ssh root@lxcora0 chown oracle:oinstall /home/oracle/.bashrc
ssh root@lxcora0 chown oracle:oinstall /home/oracle/.kshrc
ssh root@lxcora0 chown oracle:oinstall /home/oracle/.bash_logout
ssh root@lxcora0 chown oracle:oinstall /home/oracle/.

echo "================================================"
echo "Password for grid:  grid (same as username)     "
echo "================================================"
echo ''

ssh grid@lxcora0 /home/grid/edit_bashrc

sleep 5

clear

echo "================================================"
echo "Verify .bashrc file has umask 022 entry         "
echo "================================================"
echo ''
echo "================================================"
echo "Password for grid:  grid (same as username)     "
echo "================================================"
echo ''

ssh grid@lxcora0 cat .bashrc

echo ''
echo "================================================"
echo "Verified .bashrc file has umask 022 entry       "
echo "================================================"
echo ''
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

sleep 3

clear
 
echo "================================================"
echo "Now run ubuntu-services-3c.sh X                 "
echo "Note that ubuntu-services-3c.sh takes an input  "
echo "variable X which is the number of LXC RAC nodes "
echo "you wish to create.  If X is not entered, the   "
echo "build defaults to a 2-node RAC cluster.  If X is"
echo "set to 6 it will create a 6-node RAC            "
echo "================================================"
