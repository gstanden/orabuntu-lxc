#!/bin/bash

echo ''
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
echo "============================================"
echo "Checking status of bind9 DNS completed      "
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
echo "Checking status of DHCP completed           "
echo "============================================"

sleep 5

clear

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

sleep 5

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
sudo mv /var/lib/lxc/lxcora01/rootfs/etc/selinux/config /var/lib/lxc/lxcora0/rootfs/etc/selinux/config

echo ''
echo "==========================================" 
echo "Extraction completed.                     " 
echo "=========================================="
echo ''
echo "=========================================="
echo "Run script ubuntu-services-3b.sh next...  "
# echo "(Ubuntu host must reboot before running)  " 
echo "=========================================="
echo ''
# echo "=========================================="
# echo "Rebooting Ubuntu host in 20 seconds...    "
# echo "<CTRL> + C to abort reboot                "
# echo "=========================================="

sleep 5
# sudo reboot

