#!/bin/bash

echo ''
echo "================================================="
echo "                                                 "
echo "Script:  ubuntu-services-1.sh                    "
echo "                                                 "
echo "Tested with Ubuntu 15.04 Vivid Vervet            "
echo "Tested with Ubuntu 15.10 Wily Werewolf           "
echo "                                                 "
echo "  !! Only use a FRESH Ubuntu 15.x Install !!     "
echo "                                                 "
echo "These scripts overwrite some configurations!     "
echo "These scripts will destroy lxcora* containers!   "
echo "These scripts will terminate DHCP leases!        "
echo "Use with customized Ubuntu at your own risk!     "
echo "                                                 "
echo "If any doubts, <CTRL>+c NOW to exit and          " 
echo "review scripts first before running!             "
echo "                                                 "
echo "Sleeping 25 seconds to give you time to think... "
echo "                                                 "
echo "================================================="

sleep 25

clear

echo ''
echo "================================================"
echo "Clear DHCP leases...                         "
echo "================================================"
echo ''

if [ -e /var/lib/dhcp/dhcpd.leases ]
then
	sudo service isc-dhcp-server stop >/dev/null 2>&1
	if [ -e /var/lib/dhcp/dhcpd.leases~ ]
		then
		sudo rm /var/lib/dhcp/dhcpd.leases~
	fi

	if [ -e /var/lib/dhcp/dhcpd.leases ]
	then
		sudo rm /var/lib/dhcp/dhcpd.leases
	fi
	sudo service isc-dhcp-server start >/dev/null 2>&1
fi

echo "==============================================="
echo "Clear DHCP leases complete.                    "
echo "==============================================="

sleep 5

clear

echo ''
echo "===============================================" 
echo "Verify network up....                          "
echo "==============================================="
echo ''

ping -c 3 google.com

function CheckNetworkUp {
ping -c 3 google.com | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -lt 5 ]
do
NetworkUp=$(CheckNetworkUp)
let n=$n+1
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "WAN is not up or is hiccuping badly.          "
echo "Script exiting.                               "
echo "ping google.com test must succeed             "
echo "Address network issues/hiccups & rerun script."
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Network ping test verification complete.      "
echo "WAN is up.                                    "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "          Destruction of Containers           "
echo "                                              "
echo "                !!WARNING!!                   "
echo "                                              "
echo "  This step destroys all existing containers  "
echo "    with the name lxcora* (e.g. lxcora11)     "
echo "                                              "
echo "   If any doubts, <CTRL>+c NOW to exit and    " 
echo "    review scripts first before running!      "
echo "                                              "
echo "    Sleeping 25 seconds to give you time      "
echo "              to think...                     "
echo "                                              "
echo "=============================================="
echo ''

sleep 25

echo ''
echo "=============================================="
echo "Installing LXC package...                     "
echo "=============================================="
echo ''

sudo apt-get install -y lxc

echo ''
echo "=============================================="
echo "Installing LXC package complete.              "
echo "=============================================="
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | more | grep lxcora | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
sudo lxc-stop -n $j > /dev/null 2>&1
sleep 2
sudo lxc-destroy -n $j -f > /dev/null 2>&1
sudo rm -rf /var/lib/lxc/$j
done

echo "=============================================="
echo "Destruction of Containers complete            "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "         Show Running Containers...           "
echo "  (NO containers names lxcora* should exist!) "
echo "=============================================="
echo ''

sudo lxc-ls -f

echo ''
echo "=============================================="
echo "Running Container Check completed             "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Ubuntu Package Installation...                "
echo "=============================================="
echo ''

sudo apt-get install -y synaptic
sudo apt-get install -y cpu-checker
sudo apt-get install -y uml-utilities
sudo apt-get install -y openvswitch-switch
sudo apt-get install -y openvswitch-common

# GLS 20151126 openvswitch-controller package no longer available, no longer needed.
# sudo apt-get install -y openvswitch-controller

sudo apt-get install -y bind9
sudo apt-get install -y bind9utils
sudo apt-get install -y isc-dhcp-server
sudo apt-get install -y apparmor-utils
sudo apt-get install -y openssh-server
sudo apt-get install -y uuid

# GLS 20151206 Not needed
# sudo apt-get install -y qemu-kvm
# sudo apt-get install -y libvirt-bin
# sudo apt-get install -y virt-manager

sudo apt-get install -y rpm
sudo apt-get install -y yum
sudo apt-get install -y hugepages
sudo apt-get install -y nfs-kernel-server
sudo apt-get install -y nfs-common portmap
sudo apt-get install -y multipath-tools
sudo apt-get install -y open-iscsi 
sudo apt-get install -y multipath-tools 
sudo apt-get install -y ntp
sudo apt-get install -y iotop
sudo apt-get install -y flashplugin-installer
sudo apt-get install -y sshpass

# GLS 20151213 gawk needed for scst custom kernel build on linux 4.x kernels.
# GLS 20151213 gawk optional for just the container build.
sudo apt-get install -y gawk

sudo aa-complain /usr/bin/lxc-start

echo ''
echo "=============================================="
echo "Ubuntu Package Installation complete          "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Create the LXC oracle container...            "
echo "=============================================="
echo ''

# Examples of setting the Oracle Enterprise Linux version
# sudo lxc-create -n lxcora0 -t oracle -- --release=6.latest
# sudo lxc-create -n lxcora0 -t oracle -- --release=7.latest
# Uncomment if you want a different version and rememember to comment out the 6.5 create command if you do.

sudo lxc-create -n lxcora0 -t oracle -- --release=6.5

echo ''
echo "=============================================="
echo "Create the LXC oracle container complete      "
echo "(Passwords are the same as the usernames)     "
echo "Sleeping 15 seconds...                        "
echo "=============================================="
echo ''

sleep 15

clear

sudo service bind9 stop
sudo service isc-dhcp-server stop
sudo service multipath-tools stop

# Backup existing files before untar of updated files.
~/Downloads/orabuntu-lxc-master/ubuntu-host-backup-1a.sh

# Check existing file backups to be sure they were made successfully

echo ''
echo "=============================================="
echo "Checking existing file backup before writing  "
echo "==============================================" 
echo ''

~/Downloads/orabuntu-lxc-master/ubuntu-host-backup-check-1a.sh

sleep 2 

echo ''
echo "=============================================="
echo "Existing file backups check complete          "
echo "==============================================" 

sleep 5

clear

# Unpack customized OS host files for Oracle on Ubuntu LXC host server

echo ''
echo "=============================================="
echo "Unpacking custom files for Oracle on Ubuntu..."
echo "=============================================="

sleep 5

sudo tar -P -xvf ubuntu-host.tar

sudo mkdir -p /etc/network/openvswitch

sudo cp -p ~/Downloads/orabuntu-lxc-master/openvswitch-net /etc/network/if-up.d/.
sudo chown root:root /etc/network/if-up.d/openvswitch-net

sudo cp -p ~/Downloads/orabuntu-lxc-master/rc.local.ubuntu.host /etc/rc.local
sudo chown root:root /etc/rc.local

# GLS 20151213 So that network IPs match up with container names.
sudo sed -i 's/10\.207\.39\.10/10\.207\.39\.9/' /etc/dhcp/dhcpd.conf

# GLS 20151126 Adding enp and wlp to support Ubuntu 15.10 Wily Werewolf Linux 4.2 kernels in OpenvSwitch networking files
sudo sed -i '/enp/!s/wlan|eth|bnep/enp|wlp|wlan|eth|bnep/' /etc/network/openvswitch/crt_ovs_sw1.sh
sudo sed -i '/enp/!s/wlan|eth|bnep/enp|wlp|wlan|eth|bnep/' /etc/network/openvswitch/crt_ovs_sx1.sh

echo ''
echo "============================================="
echo "Custom files for Ubuntu unpack complete      "
echo "============================================="

sleep 5

clear

echo ''
echo "============================================="
echo "Copying required /etc/resolv.conf file       "
echo "On reboot it will be auto-generated.         "
echo "============================================="

sudo cp ~/Downloads/orabuntu-lxc-master/resolv.conf.temp /etc/resolv.conf

sleep 5

echo ''
echo "============================================="
echo "Copying required /etc/resolv.conf complete   "
echo "============================================="

sleep 2

clear

echo ''
echo "============================================="
echo "Creating OpenvSwitch sw1 ...                 "
echo "============================================="
echo ''

sudo /etc/network/openvswitch/crt_ovs_sw1.sh

echo ''
echo "============================================="
echo "OpenvSwitch sw1 created.                     "
echo "============================================="
echo ''

sleep 5

clear

echo ''
echo "============================================"
echo "Starting and checking status of DHCP...     "
echo "============================================"

sudo service isc-dhcp-server start

sleep 5

function GetDHCPStatus {
sudo service isc-dhcp-server status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
DHCPStatus=$(GetDHCPStatus)

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
echo "============================================="
echo "Status check of DHCP completed.              "
echo "============================================="
echo ''

# GLS 20151128 New DHCP status check end.

sleep 5

clear

# GLS 20151127 New bind9 server checks.  Terminates script if bind9 status is invalid.

echo ''
echo "============================================="
echo "Starting and checking status of bind9...     "
echo "============================================="

sudo service bind9 start

sleep 5

function GetNamedStatus {
sudo service bind9 status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
NamedStatus=$(GetNamedStatus)

if [ $NamedStatus != 'Active:active(running)' ]
then
	echo ''
	echo "bind9 is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "bind9 status ...                             "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "bind9 status incorrect.                      "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with bind9 and retry script.  "
	echo "============================================"
	echo ''
	exit
else
	echo ''
	echo "bind9 is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "bind9 status ...                             "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "bind9 status complete.                       "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
	echo ''
fi

echo "============================================"
echo "Status check of bind9 completed.            "
echo "============================================"
echo ''

# GLS 20151128 New bind9 status check end.

sleep 5

clear

sudo cp -p ~/Downloads/orabuntu-lxc-master/create-ovs-sw-files-v2.sh.bak /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh

cd /etc/network/if-up.d/openvswitch

sudo cp lxcora00-asm1-ifup-sw8  lxcora0-asm1-ifup-sw8
sudo cp lxcora00-asm2-ifup-sw9  lxcora0-asm2-ifup-sw9
sudo cp lxcora00-priv1-ifup-sw4 lxcora0-priv1-ifup-sw4
sudo cp lxcora00-priv2-ifup-sw5 lxcora0-priv2-ifup-sw5
sudo cp lxcora00-priv3-ifup-sw6 lxcora0-priv3-ifup-sw6 
sudo cp lxcora00-priv4-ifup-sw7 lxcora0-priv4-ifup-sw7
sudo cp lxcora00-pub-ifup-sw1   lxcora0-pub-ifup-sw1

cd /etc/network/if-down.d/openvswitch

sudo cp lxcora00-asm1-ifdown-sw8  lxcora0-asm1-ifdown-sw8
sudo cp lxcora00-asm2-ifdown-sw9  lxcora0-asm2-ifdown-sw9
sudo cp lxcora00-priv1-ifdown-sw4 lxcora0-priv1-ifdown-sw4
sudo cp lxcora00-priv2-ifdown-sw5 lxcora0-priv2-ifdown-sw5
sudo cp lxcora00-priv3-ifdown-sw6 lxcora0-priv3-ifdown-sw6
sudo cp lxcora00-priv4-ifdown-sw7 lxcora0-priv4-ifdown-sw7
sudo cp lxcora00-pub-ifdown-sw1   lxcora0-pub-ifdown-sw1

sudo useradd -u 1098 grid >/dev/null 2>&1
sudo useradd -u 500 oracle >/dev/null 2>&1

echo ''
echo "============================================"
echo "Check existence of Oracle and Grid users... "
echo "============================================"
echo ''

id grid
id oracle

echo ''
echo "============================================"
echo "Oracle and Grid users displayed.            "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Next script to run: ubuntu-services-2a.sh   "
echo "============================================"

sleep 5

