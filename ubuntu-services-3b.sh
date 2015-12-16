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

clear

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

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/grid/.bashrc
sudo mv /var/lib/lxc/lxcora01/rootfs/home/grid/.bashrc /var/lib/lxc/lxcora0/rootfs/home/grid/.bashrc

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/oracle/.bashrc
sudo mv /var/lib/lxc/lxcora01/rootfs/home/oracle/.bashrc /var/lib/lxc/lxcora0/rootfs/home/oracle/.bashrc

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/oracle/.bash_logout
sudo mv /var/lib/lxc/lxcora01/rootfs/home/oracle/.bash_logout /var/lib/lxc/lxcora0/rootfs/home/oracle/.bash_logout

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/oracle/.bash_profile
sudo mv /var/lib/lxc/lxcora01/rootfs/home/oracle/.bash_profile /var/lib/lxc/lxcora0/rootfs/home/oracle/.bash_profile

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/home/oracle/.kshrc
sudo mv /var/lib/lxc/lxcora01/rootfs/home/oracle/.kshrc /var/lib/lxc/lxcora0/rootfs/home/oracle/.kshrc

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown grid:oinstall /home/grid/grid
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown grid:oinstall /home/grid/grid/rpm
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown grid:oinstall /home/grid/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chmod 755 /home/grid/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod --password `perl -e "print crypt('grid','grid');"` grid
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod --password `perl -e "print crypt('oracle','oracle');"` oracle
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 usermod -g oinstall oracle
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.bash_profile
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.kshrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.bash_logout
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 chown oracle:oinstall /home/oracle/.

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
