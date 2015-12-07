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

sudo lxc-start -n lxcora0 > /dev/null 2>&1

sleep 5

clear

echo ''
echo "==========================================="
echo "Verify no-password ssh working to lxcora0 "
echo "==========================================="
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a

echo ''
echo "==========================================="
echo "Verification of no-password ssh completed. "
echo "==========================================="

sudo lxc-stop -n lxcora0

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

sudo lxc-start -n lxcora0

sleep 5

clear

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-3b.sh      "
echo "==============================================="

sleep 5
