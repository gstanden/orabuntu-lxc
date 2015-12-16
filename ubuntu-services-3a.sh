#!/bin/bash

echo ''
echo "============================================"
echo "Script:  ubuntu-services-3a.sh              "
echo "                                            "
echo "This script extracts customzed files to     "
echo "the container required for running Oracle   "
echo "============================================"
echo ''
echo "============================================"
echo "This script is re-runnable                  "
echo "============================================"
echo ''

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
echo ''

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
echo "==========================================" 
echo "Extracting lxcora0 Oracle custom files..." 
echo "=========================================="
echo ''

sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/ssh/sshd_config
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/sysctl.conf
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/root/.bashrc
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/rc.local
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/sysconfig/ntpd
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/fstab

# GLS 20151126 Comment out NFS mounts which do not exist.  NFS is enabled and can be used but requires customization by user.
sudo sed -i 's/vmem1\.vmem\.org/# vmem1\.vmem\.org/' /var/lib/lxc/lxcora0/rootfs/etc/fstab
sudo sed -i 's/vmem1\.vmem\.org/# vmem1\.vmem\.org/' /var/lib/lxc/lxcora01/rootfs/etc/fstab

# GLS 20151213 Copy revised /etc/security/limits.conf to container
# GLS 20151215 Revised /etc/security/limits.conf updated in lxc-lxcora01.tar
# GLS 20151215 Revised /root/hugepages_setting.sh updated in lxc-lxcora01.tar
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/security/limits.conf
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/root/create_directories.sh
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/root/hugepages_setting.sh
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/nsswitch.conf
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/ntp.conf
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/sysconfig/network
sudo tar -vP --extract --file=lxc-lxcora01.tar /var/lib/lxc/lxcora01/rootfs/etc/selinux/config

sudo mv /var/lib/lxc/lxcora01/rootfs/etc/ssh/sshd_config /var/lib/lxc/lxcora0/rootfs/etc/ssh/sshd_config
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/sysctl.conf /var/lib/lxc/lxcora0/rootfs/etc/sysctl.conf
sudo mv /var/lib/lxc/lxcora01/rootfs/root/.bashrc /var/lib/lxc/lxcora0/rootfs/root/.bashrc
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/rc.local /var/lib/lxc/lxcora0/rootfs/etc/rc.local
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/sysconfig/ntpd /var/lib/lxc/lxcora0/rootfs/etc/sysconfig/ntpd
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/fstab /var/lib/lxc/lxcora0/rootfs/etc/fstab
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/security/limits.conf /var/lib/lxc/lxcora0/rootfs/etc/security/limits.conf
sudo mv /var/lib/lxc/lxcora01/rootfs/root/create_directories.sh /var/lib/lxc/lxcora0/rootfs/root/create_directories.sh
sudo mv /var/lib/lxc/lxcora01/rootfs/root/hugepages_setting.sh /var/lib/lxc/lxcora0/rootfs/root/hugepages_setting.sh
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/nsswitch.conf /var/lib/lxc/lxcora0/rootfs/etc/nsswitch.conf
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/ntp.conf /var/lib/lxc/lxcora0/rootfs/etc/ntp.conf
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/sysconfig/network /var/lib/lxc/lxcora0/rootfs/etc/sysconfig/network
sudo sed -i 's/HOSTNAME=lxcora01/HOSTNAME=lxcora0/g' /var/lib/lxc/lxcora0/rootfs/etc/sysconfig/network
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/selinux/config /var/lib/lxc/lxcora0/rootfs/etc/selinux/config

echo ''
echo "==========================================" 
echo "Extraction completed.                     " 
echo "=========================================="

sleep 5

clear

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-3b.sh      "
echo "==============================================="

sleep 5
