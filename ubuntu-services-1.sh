#    Copyright 2015-2016 Gilbert Standen
#    This file is part of orabuntu-lxc.

#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.

#    v2.8 GLS 20151231

#!/bin/bash

clear

# v2.4 GLS 20151224

echo ''
echo "=============================================="
echo "Orabuntu-lxc automation running ...           "
echo "=============================================="
echo ''
sudo date
echo ''
echo "=============================================="
echo "                                              "
echo "Script:  ubuntu-services-1.sh                 "
echo "                                              "
echo "Tested with Ubuntu 15.04 Vivid Vervet         "
echo "Tested with Ubuntu 15.10 Wily Werewolf        "
echo "                                              "
echo "  !! Only use a FRESH Ubuntu 15.x Install !!  "
echo "                                              "
echo "These scripts overwrite some configurations!  "
echo "These scripts (optionally) destroy containers!"
echo "These scripts will terminate DHCP leases!     "
echo "Use with customized Ubuntu at your own risk!  "
echo "                                              "
echo "If any doubts, <CTRL>+c NOW to exit and       " 
echo "review scripts first before running!          "
echo "                                              "
echo "=============================================="

echo ''
echo "=============================================="
echo "Ubuntu Release Version Check....              "
echo "=============================================="
echo ''

OracleRelease=$1$2
OracleVersion=$1.$2
Domain=$3
NameServer=$4

sudo cat /etc/lsb-release

function GetUbuntuVersion {
cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
}
UbuntuVersion=$(GetUbuntuVersion)

if [ $UbuntuVersion = '15.10' ] || [ $UbuntuVersion = '15.04' ]
then
echo ''
echo "=============================================="
echo "Ubuntu Release Version Check complete.        "
echo "=============================================="
else
echo ''
echo "=============================================="
echo "Ubuntu Version not tested with orabuntu-lxc   "
echo "Results may be unpredictable.                 " 
echo "Please use a supported Ubuntu OS version.     "
echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Check required packages status...             "
echo "=============================================="
echo ''

function CheckPackageInstalled {
echo 'lxc uml-utilities openvswitch-switch openvswitch-common bind9 bind9utils isc-dhcp-server apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop flashplugin-installer sshpass db5.1-util'
}
PackageInstalled=$(CheckPackageInstalled)
for i in $PackageInstalled
do
sudo dpkg -l $i | cut -f3 -d' ' | tail -1 | sed 's/^/Installed:/'
done

echo ''
echo "=============================================="
echo "Check required packages status completed.     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "==============================================" 
echo "Verify network up....                         "
echo "=============================================="
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
echo "ping google.com test must succeed             "
echo "<ctrl>+c to exit script NOW!                  "
echo "Address network issues/hiccups & rerun script."
echo "=============================================="
sleep 15
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
echo "Normally accept the default "Y" to terminate  "
echo "leases on a new install.                      "
echo "If there are existing containers, then the    "
echo "response might be N in that case.             "
echo "                                              " 
read -e -p "Terminate Existing DHCP Leases? [Y/N]   " -i "Y" TerminateLeases 
echo "                                              "
echo "=============================================="
echo ''

if [ $TerminateLeases = 'y' ] || [ $TerminateLeases = 'Y' ]
then
echo ''
echo "=============================================="
echo "Clear DHCP leases...                          "
echo "=============================================="
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

echo "=============================================="
echo "Clear DHCP leases complete.                   "
echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "         Optional step to destroy             "
echo "      existing LXC linux containers.          "
echo "                                              "
echo " Clone containers script starts cloning from  "
echo "            the n+1th container               "
echo "          so this step is optional            "
echo "=============================================="
echo ''
echo "=============================================="
echo "                                              "
read -e -p "Delete Existing LXC Containers? [Y/N]   " -i "Y" DestroyContainers 
echo "                                              "
echo "=============================================="

if [ $DestroyContainers = 'y' ] || [ $DestroyContainers = 'Y' ]
then
echo ''
echo "=============================================="
echo "          Destruction of Containers           "
echo "                                              "
echo "                !!WARNING!!                   "
echo "                                              "
echo "     This step (optionally) destroys          "
echo "          all existing containers             "
echo "                                              "
echo "   If any doubts, <CTRL>+c NOW to exit and    " 
echo "    review scripts first before running!      "
echo "                                              "
echo "    Sleeping 25 seconds to give you time      "
echo "              to think...                     "
echo "                                              "
echo "=============================================="

sleep 5

clear

if [ ! -e /etc/orabuntu-release ]
then
	echo ''
	echo "=============================================="
	echo "Installing required LXC package...            "
	echo "=============================================="
	echo ''

	sudo apt-get install -y lxc

	echo ''
	echo "=============================================="
	echo "Installing required LXC package complete.     "
	echo "=============================================="
	echo ''
fi

function CheckContainersExist {
sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
}
ContainersExist=$(CheckContainersExist)

function CheckSeedContainersExist {
sudo ls /var/lib/lxc | more | grep ol | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
}
SeedContainersExist=$(CheckSeedContainersExist)

echo ''
echo "=============================================="
read -e -p "Delete Only Container ol$OracleRelease? [Y/N]    " -i "N" DestroySeedContainerOnly
echo "=============================================="
echo ''

if [ $DestroySeedContainerOnly = 'Y' ] || [ $DestroySeedContainerOnly = 'y' ]
then
DestroyContainers=$(CheckSeedContainersExist)
else
DestroyContainers=$(CheckContainersExist)
fi

for j in $DestroyContainers
do
sudo lxc-stop -n $j
sleep 2
sudo lxc-destroy -n $j -f 
sudo rm -rf /var/lib/lxc/$j
done

echo ''
echo "=============================================="
echo "Destruction of Containers complete            "
echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "         Show Defined Containers...           "
echo "=============================================="
echo ''

sudo lxc-ls -f

echo ''
echo "=============================================="
echo "         Container Check completed.           "
echo "=============================================="

sleep 5

clear

if [ ! -e /etc/orabuntu-release ]
then
	echo ''
	echo "=============================================="
	echo "Ubuntu Package Installation...                "
	echo "=============================================="
	echo ''

	apt-cache policy bind9 | grep Installed | cut -f1 -d':' | sed 's/^[ \t]*//;s/[ \t]*$//'

	sudo apt-get install -y lxc

	# GLS 20160103 synaptic and cpu-checker packages not necessary.
	# sudo apt-get install -y synaptic
	# sudo apt-get install -y cpu-checker

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

	# GLS 20151206 Not needed for LXC.
	# Uncomment if you want KVM vm capability.
	# sudo apt-get install -y qemu-kvm
	# sudo apt-get install -y libvirt-bin
	# sudo apt-get install -y virt-manager

	sudo apt-get install -y rpm
	sudo apt-get install -y yum
	sudo apt-get install -y hugepages

	# GLS 20160103 nfs-kernel-server and nfs-common-portmap not needed
	# sudo apt-get install -y nfs-kernel-server
	# sudo apt-get install -y nfs-common portmap
	# GLS 20160103 multipath-tools and open-iscsi install moved to ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-1a.sh
	# sudo apt-get install -y multipath-tools
	# sudo apt-get install -y open-iscsi 

	sudo apt-get install -y ntp
	sudo apt-get install -y iotop
	sudo apt-get install -y flashplugin-installer
	sudo apt-get install -y sshpass

	# GLS 20151213 gawk needed for scst custom kernel build on linux 4.x kernels.
	# GLS 20160103 gawk install moved to ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-1a.sh
	# sudo apt-get install -y gawk

	# GLS 20151221 Added to support Oracle Enterprise Linux 5.x LXC containers
	sudo apt-get install db5.1-util

	sudo aa-complain /usr/bin/lxc-start

	echo ''
	echo "=============================================="
	echo "Ubuntu Package Installation complete          "
	echo "=============================================="
	echo ''
	sleep 5
	clear
fi

sudo service bind9 stop
sudo service isc-dhcp-server stop
sudo service multipath-tools stop

# Check existing file backups to be sure they were made successfully

if [ ! -e /etc/orabuntu-release ]
then
	echo ''
	echo "=============================================="
	echo "Checking existing file backup before writing  "
	echo "==============================================" 
	echo ''
	echo "=============================================="
	echo "Extracting backup scripts...                  "
	echo "==============================================" 
	echo ''

	sudo tar -vP --extract --file=ubuntu-host.tar /etc/scripts/ubuntu-host-backup.sh
	sudo tar -vP --extract --file=ubuntu-host.tar /etc/scripts/ubuntu-host-backup-check.sh
	echo ''
	sudo /etc/scripts/ubuntu-host-backup.sh
	sudo /etc/scripts/ubuntu-host-backup-check.sh

	echo ''
	echo "=============================================="
	echo "Existing file backups check complete          "
	echo "==============================================" 
fi

sleep 5

clear

# Unpack customized OS host files for Oracle on Ubuntu LXC host server

if [ ! -e /etc/orabuntu-release ]
then
	echo ''
	echo "=============================================="
	echo "Unpacking custom files for Oracle on Ubuntu..."
	echo "=============================================="

	sleep 5

	sudo tar -P -xvf ubuntu-host.tar

	# GLS 20151126 Adding enp and wlp to support Ubuntu 15.10 Wily Werewolf Linux 4.2 kernels in OpenvSwitch networking files
	sudo sed -i '/enp/!s/wlan|eth|bnep/enp|wlp|wlan|eth|bnep/' /etc/network/openvswitch/crt_ovs_sw1.sh
	sudo sed -i '/enp/!s/wlan|eth|bnep/enp|wlp|wlan|eth|bnep/' /etc/network/openvswitch/crt_ovs_sx1.sh

	# GLS 20160107 Enhancements to OpenvSwitch startup to prevent hangs on some systems.
	sudo chmod +x /etc/init.d/rc.local
	sudo chmod +x /etc/rc.local.startup
	sudo chmod +x /etc/rc.local.shutdown
	sudo /usr/sbin/update-rc.d -f rc.local remove
	sudo /usr/sbin/update-rc.d rc.local defaults
	sudo mv /etc/rcS.d/S02rc.local /etc/rcS.d/S15rc.local

	echo ''
	echo "=============================================="
	echo "Modifying the design of rc.local scripting... "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Output should be 3 lines that match these 3..."
	echo "=============================================="
	echo ''
	echo 'This stanza of 3 lines should match the next stanza of 3 lines.'
	echo ''
	echo '/etc/rc0.d/K01rc.local'
	echo '/etc/rc6.d/K01rc.local'
	echo '/etc/rcS.d/S15rc.local'
	echo ''
	sudo find /etc/rc?.d -iname '*local'
	echo ''
	echo "=============================================="
	echo "Re-design of rc.local scripting completd.     "
	echo "=============================================="
	echo ''

	sleep 5

	if [ -n $NameServer ]
	then
	# GLS 20151223 Settable Nameserver feature added
		sudo service bind9 stop
		sudo sed -i "/nameserver01/s/nameserver01/$NameServer/g" /var/lib/bind/fwd.yourdomain.com
		sudo sed -i "/nameserver01/s/nameserver01/$NameServer/g" /var/lib/bind/rev.yourdomain.com
	fi

	if [ -n $Domain ]
	then
	# GLS 20151221 Settable Domain feature added
		sudo service bind9 stop
		sudo rm /var/lib/bind/*.jnl > /dev/null 2>&1
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /var/lib/bind/fwd.yourdomain.com
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /var/lib/bind/rev.yourdomain.com
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /etc/bind/named.conf.local
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /etc/dhcp/dhcpd.conf
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /etc/dhcp/dhclient.conf
		sudo sed -i "/yourdomain\.com/s/yourdomain\.com/$Domain/g" /run/resolvconf/resolv.conf 
		sudo mv /var/lib/bind/fwd.yourdomain.com /var/lib/bind/fwd.$Domain
		sudo mv /var/lib/bind/rev.yourdomain.com /var/lib/bind/rev.$Domain
	fi
	
	echo ''
	echo "============================================="
	echo "Custom files for Ubuntu unpack complete      "
	echo "============================================="
	sleep 5
	clear
fi


if [ ! -e /etc/orabuntu-release ]
then

echo ''
echo "=============================================="
echo "Starting required openvswitches...patience... "
echo "=============================================="

	sudo /etc/network/openvswitch/crt_ovs_sw1.sh >/dev/null 2>&1
	echo ''
	sleep 10
	echo ''
	sudo ifconfig sw1
	echo ''
	sleep 10
	sudo ifconfig sx1

echo ''
echo "=============================================="
echo "Required openvswitches started.               "
echo "=============================================="
echo ''

fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Verify iptables rules are set correctly...    "
echo "=============================================="
echo ''

sudo iptables -S

echo ''
echo "=============================================="
echo "Verification of iptables rules complete.      "
echo "=============================================="

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
else
	echo ''
	echo "DHCP is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ... (ignore PID warning message)"
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
echo "Status check of DHCP completed.             "
echo "============================================"
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

if [ ! -e /etc/orabuntu-release ] || [ ! -e /etc/network/if-up.d/lxcora00-pub-ifup-sw1 ] || [ ! -e /etc/network/if-down.d/lxcora00-pub-ifdown-sw1 ]
then
	cd /etc/network/if-up.d/openvswitch
	sudo cp lxcora00-asm1-ifup-sw8  ol$OracleRelease-asm1-ifup-sw8
	sudo cp lxcora00-asm2-ifup-sw9  ol$OracleRelease-asm2-ifup-sw9
	sudo cp lxcora00-priv1-ifup-sw4 ol$OracleRelease-priv1-ifup-sw4
	sudo cp lxcora00-priv2-ifup-sw5 ol$OracleRelease-priv2-ifup-sw5
	sudo cp lxcora00-priv3-ifup-sw6 ol$OracleRelease-priv3-ifup-sw6 
	sudo cp lxcora00-priv4-ifup-sw7 ol$OracleRelease-priv4-ifup-sw7
	sudo cp lxcora00-pub-ifup-sw1   ol$OracleRelease-pub-ifup-sw1

	cd /etc/network/if-down.d/openvswitch

	sudo cp lxcora00-asm1-ifdown-sw8  ol$OracleRelease-asm1-ifdown-sw8
	sudo cp lxcora00-asm2-ifdown-sw9  ol$OracleRelease-asm2-ifdown-sw9
	sudo cp lxcora00-priv1-ifdown-sw4 ol$OracleRelease-priv1-ifdown-sw4
	sudo cp lxcora00-priv2-ifdown-sw5 ol$OracleRelease-priv2-ifdown-sw5
	sudo cp lxcora00-priv3-ifdown-sw6 ol$OracleRelease-priv3-ifdown-sw6
	sudo cp lxcora00-priv4-ifdown-sw7 ol$OracleRelease-priv4-ifdown-sw7
	sudo cp lxcora00-pub-ifdown-sw1   ol$OracleRelease-pub-ifdown-sw1

	sudo useradd -u 1098 grid >/dev/null 2>&1
	sudo useradd -u 500 oracle >/dev/null 2>&1
fi

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

sudo touch /etc/orabuntu-release

sleep 5

clear

echo ''
echo "=============================================="
echo "Create the LXC oracle container...            "
echo "=============================================="
echo ''

sleep 5

sudo lxc-create -n ol$OracleRelease -t oracle -- --release=$OracleVersion

echo ''
echo "=============================================="
echo "Create the LXC oracle container complete      "
echo "(Passwords are the same as the usernames)     "
echo "Sleeping 5 seconds...                         "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Check nameserver set to 127.0.0.1...          "
echo "(This will be set automatically on reboot).   "
echo "=============================================="
echo ''

sudo sed -i "/127\.0\.1\.1/s/127\.0\.1\.1/127\.0\.0\.1/" /run/resolvconf/resolv.conf

sudo cat /etc/resolv.conf

echo ''
echo "=============================================="
echo "Nameserver 127.0.0.1 set.                     "
echo "=============================================="
echo ''

sleep 5

clear

echo "============================================"
echo "Next script to run: ubuntu-services-2.sh    "
echo "============================================"

