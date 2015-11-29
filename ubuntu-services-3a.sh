#!/bin/bash

echo ''
echo "============================================"
echo "Script:  ubuntu-services-3a.sh              "
echo "                                            "
echo "This script extracts customzed files to     "
echo "the container required for running Oracle   "
echo "============================================"

echo "============================================"
echo "This script is re-runnable                  "
echo "============================================"

# GLS 20151127 New test for bind9 status.  Terminates script if bind9 status is not valid.

function GetBindStatus {
sudo service bind9 status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
BindStatus=$(GetBindStatus)

clear

echo ''
echo "============================================"
echo "Checking status of bind9 DNS...             "
echo "============================================"

if [ $BindStatus != 'Active:active(running)' ]
then
	echo ''
	echo "Bind9 is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "Bind9 DNS status ...                        "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "Bind9 DNS status incorrect.                  "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with bind9 and retry script. "
	echo "============================================"
	echo ''
	exit
else
	echo ''
	echo "Bind9 is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "Bind9 DNS status ...                        "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "Bind9 DNS status complete.                  "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================"
echo "Status check of bind9 DNS completed.        "
echo "============================================"
echo ''

# GLS 20151127 New test for bind9 status.  Terminates script if bind9 status is not valid.

# GLS 20151127 New DHCP server checks.  Terminates script if DHCP status is invalid.

clear

function GetDHCPStatus {
sudo service isc-dhcp-server status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
DHCPStatus=$(GetDHCPStatus)

echo ''
echo "============================================"
echo "Checking status of DHCP...                  "
echo "============================================"

if [ $DHCPStatus != 'Active:active(running)' ]
then
	echo ''
	echo "DHCP is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ...                             "
	echo "============================================"
	echo ''
	sudo service isc-dhcp-server status
	echo ''
	echo "============================================"
	echo "DHCP status incorrect.                      "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with DHCP and retry script.  "
	echo "============================================"
	echo ''
	exit
else
	echo ''
	echo "DHCP is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ...                             "
	echo "============================================"
	echo ''
	sudo service isc-dhcp-server status
	echo ''
	echo "============================================"
	echo "DHCP status complete.                       "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================"
echo "Status check of DHCP completed.        "
echo "============================================"
echo ''

# GLS 20151128 New DHCP status check end.

# GLS 20151128 Google ping test start.

clear

echo ''
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

echo $NetworkUp

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

clear

echo ''
echo "============================================"
echo "DNS nslookup test...                        "
echo "Be patient...sometimes!                     "
echo "============================================"
echo ''

function GetLookup {
nslookup vmem1 | grep 10.207.39.1 | sed 's/\.//g' | sed 's/: //g'
}
Lookup=$(GetLookup)

if [ $Lookup != 'Address10207391' ]
then
	echo ''
	echo "DNS Lookups NOT working."
	echo ''
	echo "============================================"
	echo "DNS lookups status ...                             "
	echo "============================================"
	nslookup vmem1
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with DNS and retry script.  "
	echo "============================================"
	exit
else
	echo ''
	echo "DNS Lookups are working properly."
	echo ''
	echo "============================================"
	echo "DNS Lookup ...                             "
	echo "============================================"
	nslookup vmem1
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================"
echo "Status check of DNS Lookups completed.      "
echo "============================================"
echo ''

sleep 5

clear

echo ''

sudo lxc-start -n lxcora0 > /dev/null 2>&1

sleep 5

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

echo ''
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

sleep 5

ssh root@lxcora0 uname -a

echo ''
echo "==========================================="
echo "Verification of no-password ssh completed. "
echo "==========================================="

sleep 5

clear

echo ''
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

