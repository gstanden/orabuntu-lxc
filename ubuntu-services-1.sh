#!/bin/bash

echo ''
echo "================================================="
echo "                                                 "
echo "Script:  ubuntu-services-1.sh                    "
echo "                                                 "
echo "Tested with Ubuntu 15.04 Vivid Vervet            "
echo "Tested with Ubuntu 15.10 Wily Werewolf           "
echo "Only use a FRESH Ubuntu 15.x Install             "
echo "These scripts overwrite some configurations!     "
echo "Use with customized Ubuntu at your own risk!     "
echo "<CTRL> + C to exit                               "
echo "Sleeping 10 seconds...                           "
echo "                                                 "
echo "================================================="

sleep 10

clear

echo ''
echo "==============================================="
echo "DHCP service clear, start, and test...         "
echo "Verify health status...                        "
echo "==============================================="
echo ''

if [ -e /var/lib/dhcp/dhcpd.leases ]
then
	sudo service isc-dhcp-server stop
	if [ -e /var/lib/dhcp/dhcpd.leases~ ]
		then
		sudo rm /var/lib/dhcp/dhcpd.leases~
	fi

	if [ -e /var/lib/dhcp/dhcpd.leases ]
	then
		sudo rm /var/lib/dhcp/dhcpd.leases
	fi
	sudo service isc-dhcp-server start
	sudo service isc-dhcp-server status
fi

echo ''
echo "==============================================="
echo "Clear DHCP leases and start DHCP complete.     "
echo "==============================================="

sleep 5

clear

echo ''
echo "============================================" 
echo "Verify network up....                       "
echo "============================================"
echo ''

sleep 2

ping -c 3 google.com
if [ $? -ne 0 ]
then
echo ''
echo "============================================"
echo "Network is not up.  Script exiting.         "
echo "ping google.com must succeed                "
echo "Address network issues and retry script     "
echo "============================================"
echo ''
fi

echo ''
echo "============================================"
echo "Network verification complete               "
echo "============================================"
echo ''

sleep 5

clear

echo ''
echo "==========================================="
echo "Destruction of Containers                  "
echo "==========================================="
echo ''

sudo apt-get install -y lxc
echo ''
function CheckClonedContainersExist {
sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
sudo lxc-stop -n $j 
sleep 2
sudo lxc-destroy -n $j -f > /dev/null 2>&1
sudo rm -rf /var/lib/lxc/$j
done

echo ''
echo "==========================================="
echo "Destruction of Containers complete         "
echo "==========================================="

sleep 5

clear

echo ''
echo "==========================================="
echo "Show Running Containers...                 "
echo "==========================================="
echo ''

sudo lxc-ls -f

echo ''
echo "==========================================="
echo "Running Container Check completed          "
echo "==========================================="

sleep 5

clear

echo ''
echo "==========================================="
echo "Ubuntu Package Installation...             "
echo "==========================================="
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
sudo apt-get install -y gawk

sudo aa-complain /usr/bin/lxc-start

echo ''
echo "==========================================="
echo "Ubuntu Package Installation complete       "
echo "==========================================="
echo ''

sleep 5

clear

echo ''
echo "==========================================="
echo "Create the LXC oracle container...         "
echo "==========================================="
echo ''

# Examples of setting the Oracle Enterprise Linux version
# Uncomment if you want a different version and rememember to comment out the 6.5 create command if you do.

# sudo lxc-create -n lxcora0 -t oracle -- --release=6.latest
# sudo lxc-create -n lxcora0 -t oracle -- --release=7.latest

sudo lxc-create -n lxcora0 -t oracle -- --release=6.5

echo ''
echo "==========================================="
echo "Create the LXC oracle container complete   "
echo "(Passwords are the same as the usernames)  "
echo "Sleeping 15 seconds...                     "
echo "==========================================="
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
echo "==============================================="
echo "Checking existing file backups before writing  "
echo "===============================================" 
echo ''

~/Downloads/orabuntu-lxc-master/ubuntu-host-backup-check-1a.sh

sleep 2 

echo ''
echo "==============================================="
echo "Existing file backups check complete           "
echo "===============================================" 

sleep 5

clear

# Unpack customized OS host files for Oracle on Ubuntu LXC host server
echo ''
echo "==============================================="
echo "Unpacking custom files for Oracle on Ubuntu... "
echo "==============================================="

sleep 5

sudo tar -P -xvf ubuntu-host.tar

# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw1.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw2.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw3.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw4.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw5.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw6.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw7.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw8.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sw9.sh
# sudo tar -vP --extract --file=ubuntu-host.tar /home/gstanden/OpenvSwitch/crt_ovs_sx1.sh

sudo mkdir -p /etc/network/openvswitch

sudo mv /home/gstanden/OpenvSwitch/* /etc/network/openvswitch/.

sudo cp -p ~/Downloads/orabuntu-lxc-master/openvswitch-net /etc/network/if-up.d/.
sudo chown root:root /etc/network/if-up.d/openvswitch-net

sudo cp -p ~/Downloads/orabuntu-lxc-master/rc.local.ubuntu.host /etc/rc.local
sudo chown root:root /etc/rc.local
sudo sed -i 's/10\.207\.39\.10/10\.207\.39\.9/' /etc/dhcp/dhcpd.conf

# GLS 20151126 Adding enp and wlp to support Ubuntu 15.10 Wily Werewolf Linux 4.2 kernels in OpenvSwitch networking files
sudo sed -i '/enp/!s/wlan|eth|bnep/enp|wlp|wlan|eth|bnep/' /etc/network/openvswitch/crt_ovs_sw1.sh
sudo sed -i '/enp/!s/wlan|eth|bnep/enp|wlp|wlan|eth|bnep/' /etc/network/openvswitch/crt_ovs_sx1.sh

echo ''
echo "==============================================="
echo "Custom files for Ubuntu unpack complete        "
echo "==============================================="

sleep 5

clear

echo ''
# echo "==============================================="
# echo "Restarting Networking on the Ubuntu host...    "
# echo "==============================================="
# echo ''

# sudo /etc/init.d/networking restart

# echo ''
# echo "==============================================="
# echo "Restarting Network complete.                   "
# echo "==============================================="

# sleep 2

# clear

echo ''
echo "==============================================="
echo "Copying required /etc/resolv.conf file         "
echo "On reboot it will be auto-generated.           "
echo "==============================================="
sudo cp ~/Downloads/orabuntu-lxc-master/resolv.conf.temp /etc/resolv.conf

sleep 2

echo ''
echo "==============================================="
echo "Copying required /etc/resolv.conf complete     "
echo "==============================================="

sleep 2

clear

echo ''
echo "==============================================="
echo "Starting bind9 service...                      "
echo "Verify healthy status...                       "
echo "==============================================="
echo ''
sudo service bind9 start
sudo service bind9 status
echo ''
echo "==============================================="
echo "Verify bind9 service completed                 "
echo "==============================================="

sleep 5

clear

echo ''
echo "==============================================="
echo "Creating OpenvSwitch sw1 ...                   "
echo "==============================================="
echo ''

sudo /etc/network/openvswitch/crt_ovs_sw1.sh

echo ''
echo "==============================================="
echo "OpenvSwitch sw1 created.                       "
echo "==============================================="
echo ''

sleep 5

clear

echo ''
echo "==============================================="
echo "Starting DHCP service...                       "
echo "==============================================="
echo ''

sudo service isc-dhcp-server start
sudo service isc-dhcp-server status

echo ''
echo "==============================================="
echo "DHCP Service Started and Status displayed.     "
echo "==============================================="

# GLS 20151127 New DHCP server checks.  Terminates script if DHCP status is invalid.

sleep 5

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

sleep 5

clear

sudo cp -p ~/Downloads/orabuntu-lxc-master/create-ovs-sw-files-v2.sh.bak /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh

cd /etc/network/if-up.d/openvswitch
sudo mv lxcora01-asm1-ifup-sw8  lxcora00-asm1-ifup-sw8
sudo mv lxcora01-asm2-ifup-sw9  lxcora00-asm2-ifup-sw9
sudo mv lxcora01-priv1-ifup-sw4 lxcora00-priv1-ifup-sw4
sudo mv lxcora01-priv2-ifup-sw5 lxcora00-priv2-ifup-sw5
sudo mv lxcora01-priv3-ifup-sw6 lxcora00-priv3-ifup-sw6 
sudo mv lxcora01-priv4-ifup-sw7 lxcora00-priv4-ifup-sw7
sudo mv lxcora01-pub-ifup-sw1   lxcora00-pub-ifup-sw1

sudo cp lxcora00-asm1-ifup-sw8  lxcora0-asm1-ifup-sw8
sudo cp lxcora00-asm2-ifup-sw9  lxcora0-asm2-ifup-sw9
sudo cp lxcora00-priv1-ifup-sw4 lxcora0-priv1-ifup-sw4
sudo cp lxcora00-priv2-ifup-sw5 lxcora0-priv2-ifup-sw5
sudo cp lxcora00-priv3-ifup-sw6 lxcora0-priv3-ifup-sw6 
sudo cp lxcora00-priv4-ifup-sw7 lxcora0-priv4-ifup-sw7
sudo cp lxcora00-pub-ifup-sw1   lxcora0-pub-ifup-sw1

sudo rm lxcora02* lxcora03* lxcora04* lxcora05* lxcora06* 

cd /etc/network/if-down.d/openvswitch
sudo mv lxcora01-asm1-ifdown-sw8  lxcora00-asm1-ifdown-sw8
sudo mv lxcora01-asm2-ifdown-sw9  lxcora00-asm2-ifdown-sw9
sudo mv lxcora01-priv1-ifdown-sw4 lxcora00-priv1-ifdown-sw4
sudo mv lxcora01-priv2-ifdown-sw5 lxcora00-priv2-ifdown-sw5
sudo mv lxcora01-priv3-ifdown-sw6 lxcora00-priv3-ifdown-sw6
sudo mv lxcora01-priv4-ifdown-sw7 lxcora00-priv4-ifdown-sw7
sudo mv lxcora01-pub-ifdown-sw1   lxcora00-pub-ifdown-sw1

sudo cp lxcora00-asm1-ifdown-sw8  lxcora0-asm1-ifdown-sw8
sudo cp lxcora00-asm2-ifdown-sw9  lxcora0-asm2-ifdown-sw9
sudo cp lxcora00-priv1-ifdown-sw4 lxcora0-priv1-ifdown-sw4
sudo cp lxcora00-priv2-ifdown-sw5 lxcora0-priv2-ifdown-sw5
sudo cp lxcora00-priv3-ifdown-sw6 lxcora0-priv3-ifdown-sw6
sudo cp lxcora00-priv4-ifdown-sw7 lxcora0-priv4-ifdown-sw7
sudo cp lxcora00-pub-ifdown-sw1   lxcora0-pub-ifdown-sw1

sudo rm lxcora02* lxcora03* lxcora04* lxcora05* lxcora06* 

sudo useradd -u 1098 grid >/dev/null 2>&1
sudo useradd -u 500 oracle >/dev/null 2>&1

echo ''
echo "==============================================="
echo "Check existence of Oracle and Grid users...    "
echo "==============================================="
echo ''

id grid
id oracle

echo ''
echo "==============================================="
echo "Oracle and Grid users displayed.               "
echo "==============================================="

sleep 5

clear

echo ''
echo "==============================================="
echo "Next script to run: ubuntu-services-2a.sh      "
echo "==============================================="

sleep 5

# sudo reboot
