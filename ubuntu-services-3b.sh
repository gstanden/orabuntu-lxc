#!/bin/bash

echo ''
echo "============================================"
echo "Script:  ubuntu-services-3b.sh              "
echo "============================================"
echo ''
echo "============================================"
echo "This script extracts customzed files to     "
echo "the container required for running Oracle   "
echo "============================================"
echo ''
echo "============================================"
echo "This script is re-runnable                  "
echo "============================================"

sleep 5

echo ''
echo "============================================"
echo "Verifying container up...                   "
echo "============================================"
echo ''

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
echo ''

sleep 5

clear

echo ''
echo "==========================================="
echo "Verify no-password ssh working to lxcora0  "
echo "==========================================="
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a

echo ''
echo "==========================================="
echo "Verification done.                         "
echo "==========================================="

sleep 5

clear

echo ''
echo "================================================"
echo "Logged into LXC container lxcora0              "
echo "Installing files and packages for Oracle...     "
echo "================================================"
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 /root/packages.sh
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 /root/create_users.sh
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 /root/lxc-services.sh
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 /root/install_grid.sh

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm
sudo mkdir -p /var/lib/lxc/lxcora0/rootfs/home/grid/grid/rpm
sudo mv /var/lib/lxc/lxcora01/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm /var/lib/lxc/lxcora0/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm
sudo cp -p /var/lib/lxc/lxcora0/rootfs/home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm /var/lib/lxc/lxcora0/rootfs/root/.

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 rpm -Uvh /home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm

# sudo tar -P --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora0/rootfs/home/grid/.bashrc
# sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/oracle/.bashrc
sudo cp ~/Downloads/orabuntu-lxc-master/oracle.bash_profile /var/lib/lxc/lxcora0/rootfs/home/oracle/.bash_profile
sudo cp ~/Downloads/orabuntu-lxc-master/oracle.bashrc /var/lib/lxc/lxcora0/rootfs/home/oracle/.bashrc
sudo cp ~/Downloads/orabuntu-lxc-master/oracle.kshrc /var/lib/lxc/lxcora0/rootfs/home/oracle/.kshrc

sudo cp -p ~/Downloads/orabuntu-lxc-master/rc.local /var/lib/lxc/lxcora0/rootfs/etc/rc.local
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown grid:oinstall /home/grid/grid
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown grid:oinstall /home/grid/grid/rpm
sshpass -p root scp -o CheckHostIP=no -o StrictHostKeyChecking=no edit_bashrc root@lxcora0:/home/grid/.
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown grid:oinstall /home/grid/edit_bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chmod 755 /home/grid/edit_bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod --password `perl -e "print crypt('grid','grid');"` grid
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod --password `perl -e "print crypt('oracle','oracle');"` oracle
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod -g oinstall oracle
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.bash_profile
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.kshrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.bash_logout
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 sed -i '/ORACLE_SID/d' /home/oracle/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod --password `perl -e "print crypt('grid','grid');"` grid
sshpass -p grid ssh -o CheckHostIP=no -o StrictHostKeyChecking=no grid@lxcora0 /home/grid/edit_bashrc

echo ''
echo "================================================"
echo "Installing files and packages for Oracle done.  "
echo "================================================"
echo ''

sleep 5

clear

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-3c.sh      "
echo "==============================================="

sleep 5
