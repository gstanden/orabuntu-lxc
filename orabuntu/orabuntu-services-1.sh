#!/bin/bash

#    Copyright 2015-2019 Gilbert Standen
#    This file is part of Orabuntu-LXC.

#    Orabuntu-LXC is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-LXC is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Orabuntu-LXC. If not, see <http://www.gnu.org/licenses/>.

#    v2.4 		GLS 20151224
#    v2.8 		GLS 20151231
#    v3.0 		GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 		GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 		GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta	GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#
#!/bin/bash

MajorRelease=$1
PointRelease=$2
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
OSMemRes=$6
MultiHost=$7
DistDir=$8
Sx1Net=$9
Sw1Net=${10}

RSA=Y

if [ -e /sys/hypervisor/uuid ]
then
        function CheckAWS {
                cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
        }
        AWS=$(CheckAWS)
else
        AWS=0
fi

function GetNameServerBase {
	echo $NameServer | cut -f1 -d'-'
}
NameServerBase=$(GetNameServerBase)

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetMultiHostVar1 {
echo $MultiHost | cut -f1 -d':'
}
MultiHostVar1=$(GetMultiHostVar1)

function GetMultiHostVar2 {
echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar3 {
echo $MultiHost | cut -f3 -d':'
}
MultiHostVar3=$(GetMultiHostVar3)

function GetMultiHostVar4 {
echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

function GetMultiHostVar5 {
echo $MultiHost | cut -f5 -d':'
}
MultiHostVar5=$(GetMultiHostVar5)

function GetMultiHostVar6 {
echo $MultiHost | cut -f6 -d':'
}
MultiHostVar6=$(GetMultiHostVar6)

function GetMultiHostVar7 {
	echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)

function GetMultiHostVar8 {
	echo $MultiHost | cut -f8 -d':'
}
MultiHostVar8=$(GetMultiHostVar8)

function GetMultiHostVar9 {
	echo $MultiHost | cut -f9 -d':'
}
MultiHostVar9=$(GetMultiHostVar9)

function GetMultiHostVar10 {
	echo $MultiHost | cut -f10 -d':'
}
MultiHostVar10=$(GetMultiHostVar10)
GRE=$MultiHostVar10

function GetMultiHostVar11 {
        echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)

function GetMultiHostVar12 {
        echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)
LXDValue=$MultiHostVar12
LXD=$MultiHostVar12

function GetMultiHostVar13 {
        echo $MultiHost | cut -f13 -d':'
}
MultiHostVar13=$(GetMultiHostVar13)

function GetMultiHostVar14 {
        echo $MultiHost | cut -f14 -d':'
}
MultiHostVar14=$(GetMultiHostVar14)
PreSeed=$MultiHostVar14

function GetMultiHostVar15 {
        echo $MultiHost | cut -f15 -d':'
}
MultiHostVar15=$(GetMultiHostVar15)
LXDCluster=$MultiHostVar15

function GetMultiHostVar16 {
        echo $MultiHost | cut -f16 -d':'
}
MultiHostVar16=$(GetMultiHostVar16)
StorageDriver=$MultiHostVar16

function GetMultiHostVar17 {
        echo $MultiHost | cut -f17 -d':'
}
MultiHostVar17=$(GetMultiHostVar17)
StoragePoolName=$MultiHostVar17

function GetMultiHostVar20 {
        echo $MultiHost | cut -f20 -d':'
}
MultiHostVar20=$(GetMultiHostVar20)
TunType=$MultiHostVar20
echo "TunType = "$TunType
sleep 10

function CheckNetworkManagerInstalled {
	sudo dpkg -l | grep -v  network-manager- | grep network-manager | wc -l
}
NetworkManagerInstalled=$(CheckNetworkManagerInstalled)

function CheckLxcNetRunning {
        sudo systemctl | grep lxc-net | grep 'loaded active exited' | wc -l
}
LxcNetRunning=$(CheckLxcNetRunning)

echo ''
echo "=============================================="
echo "Install package net-tools ...                 "
echo "=============================================="
echo ''

sudo apt-get -y install net-tools

echo ''
echo "=============================================="
echo "Done: Install package net-tools.              "
echo "=============================================="
echo ''

sleep 5

clear

GetLinuxFlavors(){
if   [[ -e /etc/oracle-release ]]
then
        LinuxFlavors=$(cat /etc/oracle-release | cut -f1 -d' ')
elif [[ -e /etc/redhat-release ]]
then
        LinuxFlavors=$(cat /etc/redhat-release | cut -f1 -d' ')
elif [[ -e /usr/bin/lsb_release ]]
then
        LinuxFlavors=$(lsb_release -d | awk -F ':' '{print $2}' | cut -f1 -d' ')
elif [[ -e /etc/issue ]]
then
        LinuxFlavors=$(cat /etc/issue | cut -f1 -d' ')
else
        LinuxFlavors=$(cat /proc/version | cut -f1 -d' ')
fi
}
GetLinuxFlavors

function TrimLinuxFlavors {
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//' | sed 's/\!//'
}
LinuxFlavor=$(TrimLinuxFlavors)
LF=$LinuxFlavor

if [ -f /etc/lsb-release ]
then
	function GetUbuntuVersion {
		cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
	}
	UbuntuVersion=$(GetUbuntuVersion)
fi
RL=$UbuntuVersion

if [ -f /etc/lsb-release ]
then
	function GetUbuntuMajorVersion {
		cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
	}
	UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

function GetOperation {
echo $MultiHost | cut -f1 -d':'
}
Operation=$(GetOperation)

function CheckAptProcessRunning {
	ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
}
AptProcessRunning=$(CheckAptProcessRunning)

if [ $UbuntuMajorVersion -ge 18 ]
then
        function GetFacter {
                facter virtual --log-level=none
        }
        Facter=$(GetFacter)
else
        function GetFacter {
                facter virtual
        }
        Facter=$(GetFacter)
fi

sleep 5

clear

if [ $UbuntuVersion = '16.04' ]
then
	echo ''
	echo "=============================================="
	echo "Activate systemd-resolved ...                 "
	echo "=============================================="
	echo 

	sudo systemctl enable systemd-resolved
	echo ''
	sudo systemctl start  systemd-resolved
	echo ''
	sudo systemctl status systemd-resolved | head -50
	echo ''

	echo ''
	echo "=============================================="
	echo "Done: Activate systemd-resolved.              "
	echo "=============================================="

	sleep 5

	clear
fi

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

echo ''
echo "=============================================="
echo "Script:  orabuntu-services-1.sh               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Establish sudo privileges...                  "
echo "=============================================="
echo ''

sudo date

echo ''
echo "=============================================="
echo "Establish sudo privileges completed.          "
echo "=============================================="

sleep 5 

clear

if [ $LXD = 'Y' ]
then
	sudo tar -vP --extract --file=/opt/olxc/"$DistDir"/orabuntu/archives/ubuntu-host.tar -C / etc/orabuntu-lxc-scripts/get-images.sh --touch
fi

if [ $RSA = 'Y' ]
then
	echo ''
	echo "=============================================="
	echo "Create RSA key if it does not already exist   "
	echo "=============================================="
	echo ''

	if [ ! -e ~/.ssh/id_rsa.pub ]
	then
		ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
	fi

	if [ -e ~/.ssh/authorized_keys ]
	then
		cp -p ~/.ssh/authorized_keys ~/.ssh/authorized_keys.pre.olxc
	fi

	touch ~/.ssh/authorized_keys

	if [ -e ~/.ssh/id_rsa.pub ]
	then
		function GetAuthorizedKey {
			cat ~/.ssh/id_rsa.pub
		}
		AuthorizedKey=$(GetAuthorizedKey)
	fi

	function CheckAuthorizedKeys {
		grep -c "$AuthorizedKey" ~/.ssh/authorized_keys
	}
	AuthorizedKeys=$(CheckAuthorizedKeys)

	if [ "$AuthorizedKeys" -eq 0 ]
	then
		cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Done: Create RSA key completed                "
	echo "=============================================="

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Performance settings for sshd_config.         "
echo "=============================================="
echo ''
echo "=============================================="
echo "These make the install of Orabuntu-LXC faster."
echo "You can change these back after install or    "
echo "leave them at the new settings shown below.   "
echo "=============================================="
echo ''
echo "=============================================="
echo "There are security impllications for keeping  "
echo "these new sshd_config settings.  You should   "
echo "research the implications of new sshd_config  "
echo "parameters and make an informed decision on   "
echo "how you want to set them after the install of "
echo "Orabuntu-LXC is complete.                     "
echo "=============================================="
echo ''
echo "=============================================="
echo "Orabuntu-LXC has made a backup of sshd_config "
echo "located in the /etc/ssh directory if you want "
echo "to revert sshd_config to original settings    "
echo "after Orabuntu-LXC install is completed.      "
echo "=============================================="
echo ''

sleep 5

sudo apt-get install -y openssh-server >/dev/null 2>&1

sudo sed -i '/GSSAPIAuthentication/s/yes/no/'                                /etc/ssh/sshd_config
sudo sed -i '/UseDNS/s/yes/no/'                                              /etc/ssh/sshd_config
sudo sed -i '/GSSAPIAuthentication/s/#//'                                    /etc/ssh/sshd_config
sudo sed -i '/UseDNS/s/#//'                                                  /etc/ssh/sshd_config
sudo egrep 'GSSAPIAuthentication|UseDNS'                                     /etc/ssh/sshd_config
sudo service sshd restart

echo ''
echo "=============================================="
echo "Done: edit sshd_config.                       "
echo "=============================================="
echo ''

sleep 5 

clear

if [ -f /etc/orabuntu-lxc-release ]
then
	which lxc-ls > /dev/null 2>&1
	if [ $? -eq 0 ] && [ $Operation = 'reinstall' ]
	then
		echo ''
		echo "=============================================="
		echo "Orabuntu-LXC Reinstall delete lxc & reboot... "
		echo "=============================================="
		echo '' 
		echo "=============================================="
		echo "Re-run anylinux-services.sh after reboot...   "
		echo "=============================================="

		sudo /etc/orabuntu-lxc-scripts/stop_containers.sh

		if [ -d /var/lib/lxc ]
		then
			function CheckContainersExist {
				sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
			}
			ContainersExist=$(CheckContainersExist)

			echo ''
			echo "=============================================="
			read -e -p "Delete All LXC Containers? [ Y/N ]      " -i "Y" DestroyAllContainers
			echo "=============================================="
			echo ''

			if [ $DestroyAllContainers = 'Y' ] || [ $DestroyContainers = 'y' ]
			then
				DestroyContainers=$(CheckContainersExist)
				for j in $DestroyContainers
				do
					sudo lxc-stop -n $j
					sleep 2
					sudo lxc-destroy -n $j -f -s
					sudo rm -rf /var/lib/lxc/$j
				done

				echo ''
				echo "=============================================="
				echo "Destruction of Containers complete            "
				echo "=============================================="
			else
				echo "=============================================="
				echo "Destruction of Containers not executed.       "
				echo "=============================================="
			fi
		fi

		echo ''
		echo "=============================================="
		echo "Delete OpenvSwitch bridges...                 "
		echo "=============================================="
		echo ''

		sudo /etc/network/openvswitch/del-bridges.sh >/dev/null 2>&1
		sudo rm -f /etc/network/openvswitch/*

		echo ''
		echo "=============================================="
		echo "Done:  Delete OpenvSwitch Bridges.            "
		echo "=============================================="
		echo ''
	
		sudo rm -f  /etc/network/if-up.d/openvswitch/*
		sudo rm -f  /etc/network/if-down.d/openvswitch/*

		sudo systemctl disable sw4 > /dev/null 2>&1
		sudo systemctl disable sw5 > /dev/null 2>&1
		sudo systemctl disable sw6 > /dev/null 2>&1
		sudo systemctl disable sw7 > /dev/null 2>&1
		sudo systemctl disable sw8 > /dev/null 2>&1
		sudo systemctl disable sw9 > /dev/null 2>&1
		sudo systemctl disable sx1 > /dev/null 2>&1
		sudo systemctl disable $NameServer > /dev/null 2>&1

		sudo rm -f /etc/network/openvswitch/crt_ovs_sw4.sh
		sudo rm -f /etc/network/openvswitch/crt_ovs_sw5.sh
		sudo rm -f /etc/network/openvswitch/crt_ovs_sw6.sh
		sudo rm -f /etc/network/openvswitch/crt_ovs_sw7.sh
		sudo rm -f /etc/network/openvswitch/crt_ovs_sw8.sh
		sudo rm -f /etc/network/openvswitch/crt_ovs_sw9.sh
		sudo rm -f /etc/network/openvswitch/crt_ovs_sx1.sh

		sudo rm -f /etc/systemd/system/ora*c*.service
		sudo rm -f /etc/systemd/system/oel*c*.service
		sudo rm -f /etc/systemd/system/sw[456789].service
		sudo rm -f /etc/systemd/system/sx1.service
		sudo rm -f /etc/systemd/system/$NameServer.service

		sudo ip link del a1 > /dev/null 2>&1
		sudo ip link del a2 > /dev/null 2>&1
		sudo ip link del a3 > /dev/null 2>&1
		sudo ip link del a4 > /dev/null 2>&1
		sudo ip link del a5 > /dev/null 2>&1
		sudo ip link del a6 > /dev/null 2>&1

		echo ''
		echo "=============================================="
		echo "Uninstall lxc packages...                     "
		echo "=============================================="
		echo ''

		function CheckAptProcessRunning {
			ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
		}
		AptProcessRunning=$(CheckAptProcessRunning)

		while [ $AptProcessRunning -gt 0 ]
		do
			echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
			echo ''
			ps -ef | grep -v '_apt' | grep apt | grep -v grep
			sleep 10
			AptProcessRunning=$(CheckAptProcessRunning)
		done

		sudo apt-get -y purge lxc lxc-common lxc-templates lxc1 lxcfs python3-lxc liblxc1 dnsmasq
		sudo mv /etc/resolv.conf.orabuntu-lxc.original.* /etc/resolv.conf
		sudo userdel -r amide
	
		echo ''
		echo "=============================================="
		echo "Uninstall lxc packages completed.             "
		echo "=============================================="
		echo ''	
		echo "=============================================="
		echo "Rebooting to clear bridge lxcbr0...           "
		echo "=============================================="
		echo '' 
		echo "=============================================="
		echo "Re-run same script in anylinux after reboot   "
		echo "=============================================="

		sleep 5
	
		sudo reboot
		exit

		fi

# GLS 20170919 Ubuntu Specific Code Block 1 BEGIN

	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''

	function CheckAptProcessRunning {
		ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
	}
	AptProcessRunning=$(CheckAptProcessRunning)

	while [ $AptProcessRunning -gt 0 ]
	do
		echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
		echo ''
		ps -ef | grep -v '_apt' | grep apt | grep -v grep
		sleep 10
		AptProcessRunning=$(CheckAptProcessRunning)
	done

	sudo apt-get -y install lxc facter iptables lxc-templates

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Run LXC Checkconfig...                        "
	echo "=============================================="
	echo ''

	sleep 5

	sudo lxc-checkconfig

	echo "=============================================="
	echo "LXC Checkconfig completed.                    "
	echo "=============================================="
	echo ''
		
	sleep 5

	clear

        echo ''
        echo "=============================================="
        echo "Display Legacy Bridge for LXC ...             "
        echo "=============================================="
        echo ''

	sudo ifconfig lxcbr0

        echo "=============================================="
        echo "Done: Display Bridge for LXC                  "
        echo "=============================================="

        sleep 5

        clear

	echo ''
	echo "=============================================="
	echo "Display LXC Version...                        "
	echo "=============================================="
	echo ''

	sudo lxc-create --version

	echo ''
	echo "=============================================="
	echo "LXC version displayed.                        "
	echo "=============================================="
	echo ''
	
	sleep 5

	clear
fi

# GLS 20170919 Ubuntu Specific Code Block 1 END
 
# GLS 20170919 Ubuntu Specific Code Block 2 BEGIN

if [ ! -f /etc/orabuntu-lxc-release ]
then
	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''

	function CheckAptProcessRunning {
		ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
	}
	AptProcessRunning=$(CheckAptProcessRunning)

	while [ $AptProcessRunning -gt 0 ]
	do
		echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
		echo ''
		ps -ef | grep -v '_apt' | grep apt | grep -v grep
		sleep 10
		AptProcessRunning=$(CheckAptProcessRunning)
	done

	sudo apt-get -y install lxc facter iptables

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Run LXC Checkconfig...                        "
	echo "=============================================="
	echo ''

	sleep 5

	sudo lxc-checkconfig

	echo ''
	echo "=============================================="
	echo "LXC Checkconfig completed.                    "
	echo "=============================================="
	echo ''
		
	sleep 5

	clear

        echo ''
        echo "=============================================="
        echo "Display Legacy Bridge for LXC ...             "
        echo "=============================================="
        echo ''

	sudo ifconfig lxcbr0

        echo "=============================================="
        echo "Done: Display Bridge for LXC                  "
        echo "=============================================="

        sleep 5

        clear

	echo ''
	echo "=============================================="
	echo "Display LXC Version...                        "
	echo "=============================================="
	echo ''

	sudo lxc-create --version

	echo ''
	echo "=============================================="
	echo "LXC version displayed.                        "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi
	
# GLS 20170919 Ubuntu Specific Code Block 2 END
# GLS 20170919 LXC at version 2.0.8

function CheckAptProcessRunning {
	ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
}
AptProcessRunning=$(CheckAptProcessRunning)

while [ $AptProcessRunning -gt 0 ]
do
	echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
	echo ''
	ps -ef | grep -v '_apt' | grep apt | grep -v grep
	sleep 10
	AptProcessRunning=$(CheckAptProcessRunning)
done

echo ''
echo "=============================================="
echo "Installation required packages...             "
echo "=============================================="
echo ''

sleep 5

sudo apt-get install -y uml-utilities openvswitch-switch openvswitch-common ntp
sudo apt-get install -y bind9utils dnsutils apparmor-utils openssh-server uuid rpm lxc-templates
sudo apt-get install -y iotop sshpass facter iptables xfsprogs
sudo apt-get install -y ruby

if [ $UbuntuMajorVersion -lt 20 ]
then
	sudo apt-get -y install yum hugepages
fi

if [ $NetworkManagerInstalled -eq 1 ] && [ $SystemdResolvedInstalled -eq 0 ]
then
	sudo apt-get -y install dnsmasq
fi

if [ $UbuntuVersion = '16.04' ] && [ $FacterValue = 'xenu' ] && [ $AWS -eq 1 ]
then
	sudo apt-get -y install dnsmasq
fi

if [ $UbuntuVersion = '15.04' ] || [ $UbuntuVersion = '15.10' ]
then
	sudo apt-get -y install db5.1 db5.1-util
fi

if [ $UbuntuMajorVersion -ge 16 ] && [ $UbuntuMajorVersion -le 20 ]
then
	sudo apt-get -y install db5.3-util
	sudo ln -s /usr/bin/db5.3_dump /usr/bin/db5.1_dump
fi
sudo aa-complain /usr/bin/lxc-start
echo ''
echo "=============================================="
echo "Package Installation complete.                "
echo "=============================================="
echo ''

sleep 5

clear

if [ $Operation != new ]
then
	SwitchList='sw1 sx1'
	for k in $SwitchList
	do
		echo ''
		echo "=============================================="
		echo "Cleaning up OpenvSwitch $k iptables rules...  "
		echo "=============================================="
		echo ''

		sudo iptables -S | grep $k
		function CheckRuleExist {
		sudo iptables -S | grep -c $k
		}
		RuleExist=$(CheckRuleExist)
		function FormatSearchString {
		sudo iptables -S | grep $k | sort -u | head -1 | sed 's/-/\\-/g'
		}
		SearchString=$(FormatSearchString)
		if [ $RuleExist -ne 0 ]
		then
			function GetSwitchRuleCount {
			sudo iptables -S | grep -c "$SearchString"
			}
			SwitchRuleCount=$(GetSwitchRuleCount)
		else
 			SwitchRuleCount=0
 		fi
		function GetSwitchRule {
		sudo iptables -S | grep $k | sort -u | head -1 | cut -f2-10 -d' '
		}
		SwitchRule=$(GetSwitchRule)
		function GetCountSwitchRules {
		echo $SwitchRule | grep -c $k
		}
		CountSwitchRules=$(GetCountSwitchRules)
		while [ $SwitchRuleCount -ne 0 ] && [ $RuleExist -ne 0 ] && [ $CountSwitchRules -ne 0 ]
		do
			SwitchRule=$(GetSwitchRule)
			sudo iptables -D $SwitchRule
			SearchString=$(FormatSearchString) 
			SwitchRuleCount=$(GetSwitchRuleCount)
			RuleExist=$(CheckRuleExist)
			echo ''
			echo "Rules remaining to be deleted for OpenvSwitch $k:"
			echo ''
			function GetIptablesRulesCount {
				sudo iptables -S | grep -c $k
			}
			IptablesRulesCount=$(GetIptablesRulesCount)
			if [ $IptablesRulesCount -gt 0 ]
			then
				sudo iptables -S | grep $k
			else
				echo "=============================================="
				echo "All iptables switch $k rules deleted.         "
				echo "=============================================="
				
				sleep 5

				clear
			fi
		done
	done

	sudo iptables -S | egrep 'sx1|sw1'

	echo ''
	echo "=============================================="
	echo "OpenvSwitch iptables rules cleanup completed. "
	echo "=============================================="
	echo ''

	sleep 5

	clear
else
	sleep 5

	clear
fi

which lxc-ls > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''
	
	function CheckAptProcessRunning {
		ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
	}
	AptProcessRunning=$(CheckAptProcessRunning)

	while [ $AptProcessRunning -gt 0 ]
	do
		echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
		echo ''
		ps -ef | grep -v '_apt' | grep apt | grep -v grep
		sleep 10
		AptProcessRunning=$(CheckAptProcessRunning)
	done

	sudo apt-get install -y lxc facter iptables

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Run LXC Checkconfig...                        "
	echo "=============================================="
	echo ''

	sleep 5

	sudo lxc-checkconfig

	echo ''
	echo "=============================================="
	echo "LXC Checkconfig completed.                    "
	echo "=============================================="
	echo ''
		
	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Display LXC Version...                        "
	echo "=============================================="
	echo ''

	sudo lxc-create --version

	echo ''
	echo "=============================================="
	echo "LXC version displayed.                        "
	echo "=============================================="
	echo ''
	
	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Verify required packages status...            "
echo "=============================================="
echo ''

if [ $UbuntuMajorVersion -eq 15 ]
then
	function CheckPackageInstalled {
		echo 'facter lxc uml-utilities openvswitch-switch openvswitch-common bind9utils dnsutils apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop sshpass db5.1-util'
	}
	PackageInstalled=$(CheckPackageInstalled)
fi

if [ $UbuntuMajorVersion -ge 16 ] && [ $UbuntuMajorVersion -lt 20 ]
then
	function CheckPackageInstalled {
		echo 'facter lxc uml-utilities openvswitch-switch openvswitch-common bind9utils dnsutils apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop sshpass db5.3-util'
	}
	PackageInstalled=$(CheckPackageInstalled)
fi

if [ $UbuntuMajorVersion -ge 20 ]
then
	function CheckPackageInstalled {
		echo 'facter lxc uml-utilities openvswitch-switch openvswitch-common bind9utils dnsutils apparmor-utils openssh-server uuid rpm ntp iotop sshpass db5.3-util'
	}
	PackageInstalled=$(CheckPackageInstalled)
fi

for i in $PackageInstalled
do
	sudo dpkg -l $i | cut -f3 -d' ' | tail -1 | sed 's/^/Installed:/' | sort 
done

echo ''
echo "=============================================="
echo "Verify required packages status completed.    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Pre-install backup of key files...            "
echo "==============================================" 
echo ''
echo "=============================================="
echo "Extracting backup scripts...                  "
echo "==============================================" 
echo ''

sudo tar -v --extract --file=/opt/olxc/"$DistDir"/orabuntu/archives/ubuntu-host.tar -C / etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh --touch
sudo /etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh

echo ''
echo "=============================================="
echo "Key files backups check complete.             "
echo "==============================================" 

sleep 5

clear

function CheckNameServerExists {
	sudo lxc-ls -f | grep -c $NameServer
}
NameServerExists=$(CheckNameServerExists)

function GetLXCVersion {
        lxc-create --version
}
LXCVersion=$(GetLXCVersion)

function ConfirmContainerCreated {
        sudo lxc-ls -f | grep nsa | wc -l
}
ContainerCreated=$(ConfirmContainerCreated)

m=1; p=1; q=1
if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Create LXC DNS DHCP container...              "
	echo "=============================================="
	echo ''

	while [ $ContainerCreated -eq 0 ] && [ $m -le 3 ] && [ $UbuntuMajorVersion -gt 16 ]
	do
                echo "=============================================="
                echo "Trying Method 1 ...                           "
                echo "=============================================="
                echo ''

                dig +short us.images.linuxcontainers.org

                if [ ! -d /opt/olxc/"$DistDir"/lxcimage/nsa ]
                then
                        sudo mkdir -p /opt/olxc/"$DistDir"/lxcimage/nsa
                else
                        echo "Directory already exists: /opt/olxc/"$DistDir"/lxcimage/nsa"
                        echo ''
                fi

                sudo rm -f                /opt/olxc/"$DistDir"/lxcimage/nsa/*
                cd                        /opt/olxc/"$DistDir"/lxcimage/nsa
		sudo chown $Owner:$Group  /opt/olxc/"$DistDir"/lxcimage/nsa

                wget -4 -q https://us.images.linuxcontainers.org/images/ubuntu/focal/amd64/default/ -P /opt/olxc/"$DistDir"/lxcimage/nsa

                function GetBuildDate {
                        grep folder.gif index.html | tail -1 | awk -F "\"" '{print $8}' | sed 's/\///g' | sed 's/\.//g'
                }
                BuildDate=$(GetBuildDate)

                wget -4 -q https://us.images.linuxcontainers.org/images/ubuntu/focal/amd64/default/"$BuildDate"/SHA256SUMS -P /opt/olxc/"$DistDir"/lxcimage/nsa

                for i in rootfs.tar.xz meta.tar.xz
                do
                        if [ -f /opt/olxc/"$DistDir"/lxcimage/nsa/$i ]
                        then
                                rm -f /opt/olxc/"$DistDir"/lxcimage/nsa/$i
                        fi

                        echo ''
                        echo "Downloading $i ..."
                        echo ''

                        wget -4 -q --show-progress https://us.images.linuxcontainers.org/images/ubuntu/focal/amd64/default/"$BuildDate"/$i -P /opt/olxc/"$DistDir"/lxcimage/nsa
                        diff <(shasum -a 256 /opt/olxc/"$DistDir"/lxcimage/nsa/$i | cut -f1,11 -d'/' | sed 's/  */ /g' | sed 's/\///' | sed 's/  */ /g') <(grep $i /opt/olxc/"$DistDir"/lxcimage/nsa/SHA256SUMS)
                done
                if [ $? -eq 0 ]
                then
                        echo ''
                        sudo lxc-create -t local -n nsa -- -m /opt/olxc/"$DistDir"/lxcimage/nsa/meta.tar.xz -f /opt/olxc/"$DistDir"/lxcimage/nsa/rootfs.tar.xz
                else
                        m=$((m+1))
                fi

        	ContainerCreated=$(ConfirmContainerCreated)
        done

	while [ $ContainerCreated -eq 0 ] && [ $p -le 3 ]
	do
		echo ''
		echo "=============================================="
		echo "Trying Method 2...                            "
		echo "=============================================="
		echo ''
	
		sudo lxc-create -t download -n nsa -- --dist ubuntu --release focal --arch amd64 --keyserver hkp://keyserver.ubuntu.com:80
		if [ $? -ne 0 ]
		then
			sudo lxc-stop -n nsa -k
			sudo lxc-destroy -n nsa
			sudo rm -rf /var/lib/lxc/nsa
			sudo lxc-create -t download -n nsa -- --dist ubuntu --release focal --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80
			if [ $? -ne 0 ]
			then
				sudo lxc-stop -n nsa -k
				sudo lxc-destroy -n nsa
				sudo rm -rf /var/lib/lxc/nsa
                                sudo lxc-create -t download -n nsa -- --dist ubuntu --release focal --arch amd64 --no-validate
			fi
		fi

		p=$((p+1))
		ContainerCreated=$(ConfirmContainerCreated)
	done
	
	q=1
	while [ $ContainerCreated -eq 0 ] && [ $q -le 3 ]
	do
		echo ''
		echo "=============================================="
		echo "Trying Method 3...                            "
		echo "=============================================="
		echo ''

		sudo lxc-create -n nsa -t ubuntu -- --release focal --arch amd64
		sleep 5
		q=$((q+1))
		ContainerCreated=$(ConfirmContainerCreated)
	done

	if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
	then
		sudo lxc-update-config -c /var/lib/lxc/nsa/config
	else
                sudo sed -i 's/lxc.net.0/lxc.network/g'         	/var/lib/lxc/nsa/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'         	/var/lib/lxc/nsa/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'      	/var/lib/lxc/nsa/config
		sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'	/var/lib/lxc/nsa/config
	fi

	echo ''
	echo "=============================================="
	echo "Create LXC DNS DHCP container complete.       "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install & configure DNS DHCP LXC container... "
	echo "=============================================="

	echo ''
	sudo touch /var/lib/lxc/nsa/rootfs/etc/resolv.conf > /dev/null 2>&1
	sudo sed -i '0,/.*nameserver.*/s/.*nameserver.*/nameserver 8.8.8.8\n&/' /var/lib/lxc/nsa/rootfs/etc/resolv.conf > /dev/null 2>&1
	sudo lxc-start -n nsa
	echo ''

	sleep 5 

	clear

	echo ''
	echo "=============================================="
	echo "Testing lxc-attach for ubuntu user...         "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n nsa -- uname -a
	if [ $? -ne 0 ]
	then
		echo ''
		echo "=============================================="
		echo "lxc-attach has issue(s).                      "
		echo "=============================================="
	else
		echo ''
		echo "=============================================="
		echo "lxc-attach successful.                        "
		echo "=============================================="

		sleep 5 
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install bind9 & isc-dhcp-server in container. "
	echo "Install openssh-server in container.          "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n nsa -- sudo apt-get -y update
	sudo lxc-attach -n nsa -- sudo apt-get -y -o Dpkg::Options::=--force-confdef install bind9 isc-dhcp-server bind9utils dnsutils openssh-server man awscli sshpass

	sleep 2

	sudo lxc-attach -n nsa -- sudo service isc-dhcp-server start
	sudo lxc-attach -n nsa -- sudo service bind9 start

	echo ''
	echo "=============================================="
	echo "Install bind9 & isc-dhcp-server complete.     "
	echo "Install openssh-server complete.              "
	echo "=============================================="

	sleep 5

	clear

#	echo ''
#	echo "=============================================="
#	echo "Create DNS Replication Landing Zone ...       "
#	echo "=============================================="
#	echo ''

#	sudo lxc-attach -n nsa -- sudo mkdir -p /root/backup-lxc-container/$NameServerBase/updates

#	echo ''
#	echo "=============================================="
#	echo "Done: Create DNS Replication Landing Zone.    "
#	echo "=============================================="
#	echo ''

#	sleep 5

#	clear

	echo ''
	echo "=============================================="
	echo "DNS DHCP installed in LXC container.          "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Stopping DNS DHCP LXC container...            "
	echo "=============================================="
	echo ''

	sudo lxc-stop -n nsa
	sudo lxc-info -n nsa

	echo ''
	echo "=============================================="
	echo "DNS DHCP LXC container stopped.               "
	echo "=============================================="
	echo ''

	sleep 5 

	clear
fi

# Unpack customized OS host files for Oracle Linux LXC containers on LXC host server

function CheckNsaExists {
	sudo lxc-ls -f | grep -c nsa
}
NsaExists=$(CheckNsaExists)
FirstRunNsa=$NsaExists

echo ''
echo "=============================================="
echo "Unpack G1 host files for $LF Linux $RL...     "
echo "=============================================="
echo ''

sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/ubuntu-host.tar -C / --touch

# if	[ $SystemdResolvedInstalled -eq 0 ]
# then
# 	sudo rm /etc/systemd/resolved.conf
# fi

echo ''
echo "=============================================="
echo "Done: Unpack G1 host files for $LF Linux $RL. "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Unpack G2 host files for $LF Linux $RL...     "
echo "=============================================="
echo ''

sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/dns-dhcp-host.tar -C / --touch
sudo chmod +x /etc/network/openvswitch/crt_ovs_s*.sh

if [ $MultiHostVar2 = 'Y' ] && [ -f /var/lib/lxc/nsa/config ]
then
	sudo rm /var/lib/lxc/nsa/config
fi

echo ''
echo "=============================================="
echo "Done: Unpack G2 host files for $LF Linux $RL. "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Custom files for $LF Linux $RL installed.     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install OvsVethCleanup.service                "
echo "=============================================="
echo ''

sudo sh -c "echo '[Unit]'                                                               >  /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'Description=OvsVethCleanup job'                                       >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo '[Service]'                                                            >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'Type=oneshot'                                                         >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'User=root'                                                            >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'ExecStart=/usr/bin/bash /etc/network/openvswitch/OvsVethCleanup.sh'   >> /etc/systemd/system/OvsVethCleanup.service"

sudo cat /etc/systemd/system/OvsVethCleanup.service

echo ''
echo "=============================================="
echo "Done: Install OvsVethCleanup.service          "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install OvsVethCleanup.timer                  "
echo "=============================================="
echo ''

sudo sh -c "echo '[Unit]'                                                               >  /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'Description=OvsVethCleanup'                                           >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo '[Timer]'                                                              >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'OnUnitActiveSec=60s'                                                  >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'OnBootSec=60s'                                                        >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo '[Install]'                                                            >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'WantedBy=timers.target'                                               >> /etc/systemd/system/OvsVethCleanup.timer"

sudo cat /etc/systemd/system/OvsVethCleanup.timer

echo ''

sudo systemctl daemon-reload
sudo systemctl enable OvsVethCleanup.timer
sudo systemctl start  OvsVethCleanup.timer

echo ''

sudo systemctl list-timers --all

sleep 5

echo ''
echo "=============================================="
echo "Done: Install OvsVethCleanup.timer                  "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Create /etc/sysctl.d/60-olxc.conf file ...    "
echo "=============================================="
echo ''
echo "=============================================="
echo "These values are set automatically based on   "
echo "best practice guidelines.                     "
echo "You can adjust them after installation.       "
echo "=============================================="
echo ''

if [ -r /etc/sysctl.d/60-olxc.conf ]
then
	sudo cp -p /etc/sysctl.d/60-olxc.conf /etc/sysctl.d/60-olxc.conf.pre.orabuntu-lxc.bak
	sudo rm /etc/sysctl.d/60-olxc.conf
fi

sudo touch /etc/sysctl.d/60-olxc.conf
sudo cat /etc/sysctl.d/60-olxc.conf
sudo chmod +x /etc/sysctl.d/60-olxc.conf

echo 'Linux OS Memory Reservation (in Kb) ... '$OSMemRes 
function GetMemTotal {
	sudo cat /proc/meminfo | grep MemTotal | cut -f2 -d':' |  sed 's/  *//g' | cut -f1 -d'k'
}
MemTotal=$(GetMemTotal)
echo 'Memory (in Kb) ........................ '$MemTotal

((MemOracleKb = MemTotal - OSMemRes))
echo 'Memory for (in Kb) .................... '$MemOracleKb

((MemOracleBytes = MemOracleKb * 1024))
echo 'Memory for (in bytes) ................. '$MemOracleBytes

function GetPageSize {
	sudo getconf PAGE_SIZE
}
PageSize=$(GetPageSize)
echo 'Page Size (in bytes) .................. '$PageSize

((shmall = MemOracleBytes / 4096))
echo 'shmall (in 4Kb pages) ................. '$shmall
sudo sysctl -w kernel.shmall=$shmall 

((shmmax = MemOracleBytes / 2))
echo 'shmmax (in bytes) ..................... '$shmmax
sudo sysctl -w kernel.shmmax=$shmmax

sudo sh -c "echo '# New Stack Settings'                       > /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.conf.default.rp_filter=0'         >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.conf.all.rp_filter=0'             >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.ip_forward=1'                     >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo '# Oracle Settings'                         >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.shmall = $shmall'                   >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.shmmax = $shmmax'                   >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.shmmni = 4096'                      >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.sem = 250 32000 100 128'            >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'fs.file-max = 6815744'                     >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'fs.aio-max-nr = 1048576'                   >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.ip_local_port_range = 9000 65501' >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.rmem_default = 262144'            >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.rmem_max = 4194304'               >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.wmem_default = 262144'            >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.wmem_max = 1048576'               >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.panic_on_oops = 1'                  >> /etc/sysctl.d/60-olxc.conf"

echo ''
echo "=============================================="
echo "Done: Create /etc/sysctl.d/60-olxc.conf file. "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Display /etc/sysctl.d/60-olxc.conf            "
echo "=============================================="
echo ''

sudo sysctl -p /etc/sysctl.d/60-olxc.conf 

echo ''
echo "=============================================="
echo "Done: Display /etc/sysctl.d/60-olxc.conf file."
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Create 60-olxc.service in systemd...          "
echo "=============================================="
echo ''

if [ ! -f /etc/systemd/system/60-olxc.service ]
then
	sudo sh -c "echo '[Unit]'                                    			 > /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'Description=60-olxc Service'            			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'After=network.target'                     			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo ''                                         			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo '[Service]'                                			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'Type=oneshot'                             			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'User=root'                                			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'RemainAfterExit=yes'                      			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'ExecStart=/sbin/sysctl -p /etc/sysctl.d/60-olxc.conf'		>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo ''                                         			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo '[Install]'                                			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'               			>> /etc/systemd/system/60-olxc.service"
	sudo chmod 644 /etc/systemd/system/60-olxc.service
	sudo systemctl enable 60-olxc
fi

sudo cat /etc/systemd/system/60-olxc.service

echo ''
echo "=============================================="
echo "Created 60-olxc.service in systemd.           "
echo "=============================================="

sleep 5

clear

# Moved into product subdirectory for Oracle installs only.
# echo ''
# echo "=============================================="
# echo "Creating /etc/security/limits.d/70-oracle.conf"
# echo "=============================================="
# echo ''
# echo "=============================================="
# echo "These values are set automatically based on   "
# echo "Oracle best practice guidelines.              "
# echo "You can adjust them after installation.       "
# echo "=============================================="
# echo ''

# sudo touch /etc/security/limits.d/70-oracle.conf
# sudo chmod +x /etc/security/limits.d/70-oracle.conf

# Oracle Kernel Parameters

# sudo sh -c "echo '#                                      '  > /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '# Oracle DB Parameters                 ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '#                                      ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	soft	nproc       2047   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	hard	nproc      16384   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	soft	nofile      1024   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	hard	nofile     65536   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	soft	stack      10240   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	hard	stack      10240   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '* 	soft 	memlock  9873408           ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '* 	hard 	memlock  9873408           ' >> /etc/security/limits.d/70-oracle.conf"

# Oracle Grid Infrastructure Kernel Parameters
	
# sudo sh -c "echo '#                                        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '# Oracle GI Parameters                   ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '#                                        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	soft	nproc       2047     ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	hard	nproc      16384     ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	soft	nofile      1024     ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	hard	nofile     65536     ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	soft	stack      10240     ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	hard	stack      10240     ' >> /etc/security/limits.d/70-oracle.conf"

# echo "=============================================="
# echo 'Display /etc/security/limits.d/70-oracle.conf '
# echo "=============================================="
# echo ''
# sudo cat /etc/security/limits.d/70-oracle.conf
# echo ''
# echo "=============================================="
# echo "Created /etc/security/limits.d/70-oracle.conf "
# echo "Sleeping 10 seconds for settings review ...   "
# echo "=============================================="
# echo ''

# sleep 10

# clear

if [ $NameServerExists -eq 0  ]
then
	if [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Unpacking LXC nameserver custom files...      "
		echo "=============================================="
		echo ''
	
		sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/dns-dhcp-cont.tar -C / --touch

		echo ''
		echo "=============================================="
		echo "Custom files unpack complete                  "
		echo "=============================================="
	fi

	sleep 10

	clear

	echo ''
	echo "=============================================="
	echo "Customize domains and display /etc/resolv.conf"
	echo "=============================================="
	echo ''

	function GetHostName {
		echo $HOSTNAME | cut -f1 -d'.'
	}
	HostName=$(GetHostName)

	if [ -n $Domain1 ] 
	then
		if [ $NetworkManagerInstalled -eq 1 ]
		then
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/NetworkManager/dnsmasq.d/orabuntu-local
		fi
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/network/openvswitch/crt_ovs_sw1.sh
	fi
		
	if [ -n $Domain2 ] 
	then
		if [ $NetworkManagerInstalled -eq 1 ]
		then
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/NetworkManager/dnsmasq.d/orabuntu-local
		fi
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/network/openvswitch/crt_ovs_sw1.sh
	fi

	if [ $MultiHostVar2 = 'N' ]
	then
		# Remove the extra nameserver line used for DNS DHCP setup and add the required nameservers.

		sudo sed -i '/8.8.8.8/d' /var/lib/lxc/nsa/rootfs/etc/resolv.conf								> /dev/null 2>&1
		sudo sed -i '/nameserver/c\nameserver 10.207.39.2' /var/lib/lxc/nsa/rootfs/etc/resolv.conf					> /dev/null 2>&1
		sudo sh -c "echo 'nameserver 10.207.29.2' >> /var/lib/lxc/nsa/rootfs/etc/resolv.conf"						> /dev/null 2>&1
		sudo sh -c "echo 'search orabuntu-lxc.com consultingcommandos.us' >> /var/lib/lxc/nsa/rootfs/etc/resolv.conf"			> /dev/null 2>&1

		if [ ! -z $HostName ]
		then
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.consultingcommandos.us
		fi

		if [ -n $NameServer ]
		then
			# GLS 20151223 Settable Nameserver feature added
			# GLS 20161022 Settable Nameserver feature moved into DNS DHCP LXC container.
			# GLS 20162011 Settable Nameserver feature expanded to include nameserver and both domains.
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/var/lib/bind/rev.consultingcommandos.us
			sudo sed -i "/nsa/s/nsa/$NameServer/g" 		/var/lib/lxc/nsa/config
			sudo sed -i "/nsa/s/nsa/$NameServer/g" 		/var/lib/lxc/nsa/rootfs/etc/hostname
			sudo sed -i "/nsa/s/nsa/$NameServer/g" 		/var/lib/lxc/nsa/rootfs/etc/hosts
			sudo sed -i "/nsa/s/nsa/$NameServer/g" 		/var/lib/lxc/nsa/rootfs/root/crontab.txt
			sudo sed -i "/nsa/s/nsa/$NameServer/g" 		/var/lib/lxc/nsa/rootfs/root/ns_backup_update.lst
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/root/ns_backup_update.sh
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/root/ns_backup.start.sh
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" 	/var/lib/lxc/nsa/rootfs/root/dns-sync.sh

			function GetNameServerShortName {
				echo $NameServer | cut -f1 -d'-'
			}
			NameServerShortName=$(GetNameServerShortName)

			sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/ns_backup_update.sh
			sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/ns_backup.start.sh
			sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/dns-sync.sh


			sudo sed -i "/nsa/s/nsa/$NameServer/g" /etc/network/openvswitch/strt_nsa.sh
			sudo mv /var/lib/lxc/nsa /var/lib/lxc/$NameServer

			sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1 		/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1
			sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1 	/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1
			sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1 		/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1
			sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1 	/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1
			sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1 		/etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sw1
			sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1 	/etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sw1
			sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1 		/etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sx1
			sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1 	/etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sx1
			sudo cp -p /etc/network/openvswitch/strt_nsa.sh 			/etc/network/openvswitch/strt_$NameServerBase.sh
			sudo cp -p /etc/network/openvswitch/strt_nsa.sh 			/etc/network/openvswitch/strt_$NameServer.sh
		
			echo "/etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sw1" 		 > /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sw1" 	>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sx1" 		>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sx1" 	>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1" 		>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1" 		>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1" 		>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
			echo "/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1" 		>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
		fi

		if [ -n $Domain1 ]
		then
			# GLS 20151221 Settable Domain feature added
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/systemd/resolved.conf
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf	> /dev/null 2>&1
			
			if [ $NetworkManagerInstalled -eq 1 ]
			then
				sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/NetworkManager/dnsmasq.d/orabuntu-local
			fi
			
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/network/openvswitch/crt_ovs_sw1.sh
			
			if [ $SystemdResolvedInstalled -ge 1 ]
			then
				sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/systemd/resolved.conf > /dev/null 2>&1
			fi
 			
		#	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /run/systemd/resolve/stub-resolv.conf > /dev/null 2>&1
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
		#	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.lst
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/root/dns-thaw.sh
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain1
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain1
		fi

		if [ -n $Domain2 ]
		then
			# GLS 20151221 Settable Domain feature added
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/systemd/resolved.conf
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf > /dev/null 2>&1
			
			if [ $NetworkManagerInstalled -eq 1 ]
			then
				sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/NetworkManager/dnsmasq.d/orabuntu-local
			fi
			
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/network/openvswitch/crt_ovs_sw1.sh
			
			if [ $SystemdResolvedInstalled -ge 1 ]
			then
				sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/systemd/resolved.conf > /dev/null 2>&1
			fi

		#	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /run/systemd/resolve/stub-resolv.conf
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
		#	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.lst
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/root/dns-thaw.sh
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain2
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain2
		fi

	elif [ $MultiHostVar2 = 'Y' ] && [ $SystemdResolvedInstalled -ge 1 ]
	then
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" 		/etc/systemd/resolved.conf
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" 	/etc/systemd/resolved.conf
	fi

	# Cleanup duplicate search lines in /etc/resolv.conf if Orabuntu-LXC has been re-run
	
	if [ $NetworkManagerInstalled -eq 1 ]
	then
		sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D'	/etc/resolv.conf				> /dev/null 2>&1
	fi

	sudo service systemd-resolved restart

	sudo cat /etc/resolv.conf

	sleep 5

	echo ''
	echo "=============================================="
	echo "Done:  Customize and display.                 "
	echo "=============================================="
			
	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/systemd/resolved.conf 	> /dev/null 2>&1
fi

sleep 5

clear

if	[ $NetworkManagerInstalled -eq 1 ] && [ $SystemdResolvedInstalled -eq 0 ]
then
	echo ''
	echo "=============================================="
	echo "Activating NetworkManager dnsmasq service ... "
	echo "=============================================="
	echo ''

	# So that settings in /etc/NetworkManager/dnsmasq.d/orabuntu-local & /etc/NetworkManager/NetworkManager.conf take effect.

	sudo cat /etc/resolv.conf
	sudo sed -i '/plugins=ifupdown,keyfile/a dns=dnsmasq' /etc/NetworkManager/NetworkManager.conf
	sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/NetworkManager/NetworkManager.conf

	sudo service NetworkManager restart > /dev/null 2>&1

	function CheckResolvReady {
		sudo cat /etc/resolv.conf | egrep -c 'nameserver 127\.0\.1\.1|nameserver 127\.0\.0\.1'
	}
	ResolvReady=$(CheckResolvReady)
	NumResolvReadyTries=0
	while [ $ResolvReady -ne 1 ] && [ $NumResolvReadyTries -lt 60 ]
	do
		ResolvReady=$(CheckResolvReady)
		((NumResolvReadyTries=NumResolvReadyTries+1))
		sleep 1
		echo 'NumResolvReadyTries = '$NumResolvReadyTries
	done

	if [ $ResolvReady -eq 1 ]
	then
		echo ''
 		sudo service sw1 restart >/dev/null 2>&1
	else
		echo ''
 		echo "=============================================="
		echo "NetworkManager didn't set nameserver 127.0.0.1"
		echo "which is the setting required for NM dnsmasq. "
		echo "=============================================="
 	fi
	
	echo "=============================================="
	echo "NetworkManager dnsmasq activated.             "
	echo "=============================================="
fi

sleep 5

clear

if [ $UbuntuVersion = '16.04' ] && [ $SystemdResolvedInstalled -eq 0 ]
then
	echo ''
	echo "=============================================="
	echo "Configure DNS (dnsmasq)                       "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Display original /etc/resolv.conf...          "
	echo "=============================================="
	echo ''

	sudo cat /etc/resolv.conf

	function GetOriginalNameServers {
		cat /etc/resolv.conf  | grep nameserver | tr -d '\n' | sed 's/nameserver//g' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/  */ /g'
	}
	OriginalNameServers=$(GetOriginalNameServers)

	function GetOriginalSearchDomains {
		cat /etc/resolv.conf  | grep search | sed 's/  */ /g' | sed 's/search //g'
	}
	OriginalSearchDomains=$(GetOriginalSearchDomains)

	echo ''
	echo "=============================================="
	echo "Done: Display original /etc/resolv.conf.      "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Install and Configure dnsmasq...              "
	echo "=============================================="
	echo ''

	sudo dpkg --configure -a
	sudo apt-get -y install dnsmasq
	sudo service dnsmasq stop
	sleep 5

        function CheckSearchDomain1 {
                grep -c $Domain1 /etc/resolv.conf
        }
        SearchDomain1=$(CheckSearchDomain1)

        function CheckServerDomain1 {
                grep -c $Domain1 /etc/dnsmasq.conf
        }
        ServerDomain1=$(CheckServerDomain1)

        function CheckServerDomain2 {
                grep -c $Domain2 /etc/dnsmasq.conf
        }
        ServerDomain2=$(CheckServerDomain2)

        function CheckCacheSizeDnsmasq {
                grep -c cache-size=0 /etc/dnsmasq.conf
        }
        CacheSizeDnsmasq=$(CheckCacheSizeDnsmasq)

	for j in $OriginalNameServers
	do
		for i in $OriginalSearchDomains
		do
			function CountOriginalSearchDomainsDnsmasq {
				grep -c $j /etc/dnsmasq.conf
			}
			OriginalSearchDomainsDnsmasq=$(CountOriginalSearchDomainsDnsmasq)
		
			if [ $OriginalSearchDomainsDnsmasq -eq 0 ]
			then	
				sudo sh -c "echo 'server=/$i/$j' >> /etc/dnsmasq.conf"
			fi
		done
	done

	if [ $ServerDomain1 -eq 0 ]
	then
        	sudo sh -c "echo 'server=/$Domain1/10.207.39.2'                 >> /etc/dnsmasq.conf"
        	sudo sh -c "echo 'server=/39.207.10.in-addr.arpa/10.207.39.2'   >> /etc/dnsmasq.conf"
		sudo sh -c "echo 'server=/gns1.$Domain1/10.207.39.2'            >> /etc/dnsmasq.conf"
	fi

	if [ $ServerDomain2 -eq 0 ]
	then
        	sudo sh -c "echo 'server=/$Domain2/10.207.29.2'                 >> /etc/dnsmasq.conf"
        	sudo sh -c "echo 'server=/29.207.10.in-addr.arpa/10.207.29.2'   >> /etc/dnsmasq.conf"
        fi

	if [ $CacheSizeDnsmasq -eq 0 ]
	then
		sudo sh -c "echo 'cache-size=0'					>> /etc/dnsmasq.conf"
	fi
	
	sudo systemctl enable dnsmasq

	sudo service dnsmasq start

	if [ -f /etc/resolv.conf.orabuntu-lxc.original.* ]
	then	
               	function GetExistingSearchDomains {
                       	cat /etc/resolv.conf.orabuntu-lxc.original.* | grep search | cut -f2-10 -d' '
               	}
               	ExistingSearchDomains=$(GetExistingSearchDomains)
	else
               	function GetExistingSearchDomains {
                       	cat /etc/resolv.conf | grep search | sed 's/  */ /g' | grep -v "$Domain1" | cut -f2-100 -d' '
               	}
               	ExistingSearchDomains=$(GetExistingSearchDomains)
	fi

	if [ $AWS -eq 1 ]
        then
		sudo sed -i '/#/d'										   /etc/resolv.conf
                sudo sed -i '/search/d' 									   /etc/resolv.conf
		sudo sed -i '/127.0.0.1/!s/nameserver/# nameserver/g'   					   /etc/resolv.conf
		sudo sh  -c "echo 'nameserver 127.0.0.1' 							>> /etc/resolv.conf"
                sudo sh  -c "echo 'search $ExistingSearchDomains $Domain1 $Domain2 gns1.$Domain1' 		>> /etc/resolv.conf"
		sudo sed -i "/supersede domain-name/c\append domain-name \" $Domain1 $Domain2 gns1.$Domain1\""     /etc/dhcp/dhclient.conf
		sudo sed -i '/8.8.8.8/d' 									   /etc/resolv.conf
		sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D'  							   /etc/resolv.conf
        fi

        if [ $AWS -eq 0 ] && [ $SearchDomain1 -eq 0 ]
        then
                sudo sed -i '/search/d' 									   /etc/resolv.conf
		sudo sed -i '/127.0.0.1/!s/nameserver/# nameserver/g'   					   /etc/resolv.conf
                sudo sh -c  "echo 'search $Domain1 $Domain2 gns1.$Domain1' >> 					   /etc/resolv.conf"
		sudo sed -i "/supersede domain-name/c\append domain-name \" $Domain1 $Domain2 gns1.$Domain1\"" 	   /etc/dhcp/dhclient.conf
                sudo sed -i "/prepend domain-name-servers/s/#//"  						   /etc/dhcp/dhclient.conf
		sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D'  							   /etc/resolv.conf
        fi


	echo ''	
	echo "=============================================="
	echo "Done: Install and Configure dnsmasq           "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Display dnsmasq /etc/resolv.conf...           "
	echo "=============================================="
	echo ''

	sudo cat /etc/resolv.conf
	sleep 5

	echo ''
	echo "=============================================="
	echo "Done: Display dnsmasq /etc/resolv.conf        "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Done: Configure /etc/dhcp/dhclient.conf       "
	echo "=============================================="

	sleep 5

	clear
fi

if [ $UbuntuMajorVersion -eq 16 ]
then
	sudo sh -c "echo 'append domain-name \" $Domain1 $Domain2 gns1.$Domain1\";' >> /etc/dhcp/dhclient.conf"
fi

sudo chmod 755 /etc/network/openvswitch/*.sh

function GetNameServerShortName {
	echo $NameServer | cut -f1 -d'-'
}
NameServerShortName=$(GetNameServerShortName)

if   [ $MultiHostVar3 = 'X' ]
then
        echo ''
        echo "=============================================="
        echo "Get sx1 IP address...                         "
        echo "=============================================="
        echo ''

	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
        
	Sx1Index=201
        function CheckHighestSx1IndexHit {
                sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-attach -n $NameServerShortName -- getent hosts $Sx1Net.$Sx1Index" | grep -c 'name ='
        }
        HighestSx1IndexHit=$(CheckHighestSx1IndexHit)

        while [ $HighestSx1IndexHit = 1 ]
        do
                Sx1Index=$((Sx1Index+1))
                HighestSx1IndexHit=$(CheckHighestSx1IndexHit)
        done

        echo ''
        echo "=============================================="
        echo "Get sw1 IP address.                           "
        echo "=============================================="
        echo ''

	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
        
        Sw1Index=201
        function CheckHighestSw1IndexHit {
                sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-attach -n $NameServerShortName -- getent hosts $Sw1Net.$Sw1Index" | grep -c 'name ='
        }
        HighestSw1IndexHit=$(CheckHighestSw1IndexHit)

        while [ $HighestSw1IndexHit = 1 ]
        do
                Sw1Index=$((Sw1Index+1))
                HighestSw1IndexHit=$(CheckHighestSw1IndexHit)
        done

elif [ $MultiHostVar3 = 'X' ] && [ $MultiHostVar2 = 'Y' ] && [ $GRE = 'N' ]
then
        function GetSx1Index {
                sudo cat /etc/network/openvswitch/sx1.info | cut -f2 -d':' | cut -f4 -d'.'
        }
        Sx1Index=$(GetSx1Index)

        function GetSw1Index {
                sudo cat /etc/network/openvswitch/sw1.info | cut -f2 -d':' | cut -f4 -d'.'
        }
        Sw1Index=$(GetSw1Index)
else
        Sw1Index=$MultiHostVar3
        Sx1Index=$MultiHostVar3
fi

sudo sed -i "s/SWITCH_IP/$Sx1Index/g" /etc/network/openvswitch/crt_ovs_sx1.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw1.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw2.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw3.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw4.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw5.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw6.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw7.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw8.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw9.sh

if [ $LXDCluster = 'Y' ]
then
        echo ''
        echo "=============================================="
        echo "Install packages...                           "
        echo "=============================================="
        echo ''

        sudo apt-get -y install expect dos2unix
        
	echo ''
        echo "=============================================="
        echo "Done: Install packages.                       "
        echo "=============================================="
        echo ''

	sleep 5

	clear

        sudo sed -i "s/HOSTNAME/$HOSTNAME/g"    /etc/network/openvswitch/lxd-init-node1.sh

        if   [ $PreSeed = 'Y' ]
        then
                function GetShortHostName {
                        hostname -s
                }
                ShortHostName=$(GetShortHostName)

                if   [ $GRE = 'N' ]
                then
                        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"                                                   /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster
                        sudo sed -i "s/HOSTNAME/$ShortHostName/g"                                               /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster
                        sudo sed -i "s/STORAGE-DRIVER/$StorageDriver/g"                                         /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster
                        sudo sed -i "s/POOL/$StoragePoolName/g"                                                 /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster

                elif [ $GRE = 'Y' ]
                then
                        sshpass -p $MultiHostVar8 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S --prompt='' <<< "$MultiHostVar8" lxc info | sed -n '/BEGIN.*-/,/END.*-/p'" > /tmp/cert.txt
			rm /tmp/cert.txt
                        sshpass -p $MultiHostVar8 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S --prompt='' <<< "$MultiHostVar8" lxc info | sed -n '/BEGIN.*-/,/END.*-/p'" > /tmp/cert.txt
		
			echo ''
			echo "=============================================="
			echo "Display /tmp/cert.txt ...                     "
			echo "=============================================="
			echo ''

			cat /tmp/cert.txt

			echo ''
			echo "=============================================="
			echo "Done: Display /tmp/cert.txt.                  "
			echo "=============================================="
			echo ''

			sleep 5

			clear

                        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"                                                   /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i "s/HOSTNAME/$ShortHostName/g"                                               /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i "s/STORAGE-DRIVER/$StorageDriver/g"                                         /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i "s/POOL/$StoragePoolName/g"                                                 /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i -e '/-----BEGIN/,/-----END/!b' -e '/-----END/!d;r /tmp/cert.txt' -e 'd'     /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
			sudo dos2unix										/etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
		
			echo ''
			echo "=============================================="
			echo "Display LXD Preseed...                        "
			echo "=============================================="
			echo ''

			sudo cat /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
		
			echo ''
			echo "=============================================="
			echo "Done: Display LXD Preseed.                    "
			echo "=============================================="
			echo ''

			sleep 5

			clear
                fi
        fi
fi

sudo sed -i "s/MULTIHOSTVAR7/$MultiHostVar7/g"  /etc/network/openvswitch/crt_ovs_sw1.sh
sudo sed -i "s/MULTIHOSTVAR7/$MultiHostVar7/g"  /etc/network/openvswitch/crt_ovs_sx1.sh

if   [ $UbuntuMajorVersion -ge 16 ]
then
	SwitchList='sw1 sx1'
	for k in $SwitchList
	do
		echo ''
		echo "=============================================="
		echo "Installing OpenvSwitch $k...                  "
		echo "=============================================="

       		if [ ! -f /etc/systemd/system/$k.service ]
       		then
       	        	sudo sh -c "echo '[Unit]'						 > /etc/systemd/system/$k.service"
       	         	sudo sh -c "echo 'Description=$k Service'				>> /etc/systemd/system/$k.service"
		
		if [ $k = 'sw1' ]
		then
                	sudo sh -c "echo 'Wants=network-online.target'				>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'After=network-online.target'				>> /etc/systemd/system/$k.service"
		fi
		if [ $k = 'sx1' ]
		then
                	sudo sh -c "echo 'Wants=sw1.service'					>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'After=sw1.service'					>> /etc/systemd/system/$k.service"
		fi
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$k.service"

		if [ $AWS -eq 1 ]
		then
                	sudo sh -c "echo 'Type=idle'						>> /etc/systemd/system/$k.service"
		else
                	sudo sh -c "echo 'Type=oneshot'						>> /etc/systemd/system/$k.service"
		fi

                	sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/crt_ovs_$k.sh' 	>> /etc/systemd/system/$k.service"
			sudo sh -c "echo 'ExecStop=/usr/bin/ovs-vsctl del-br $k'                >> /etc/systemd/system/$k.service"
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'WantedBy=multi-user.target'				>> /etc/systemd/system/$k.service"

			sleep 5

			clear
		
			echo ''
			echo "=============================================="
			echo "Starting OpenvSwitch $k ...                   "
			echo "=============================================="
			echo ''
	
       			sudo chmod 644 /etc/systemd/system/$k.service
			sudo systemctl daemon-reload
       			sudo systemctl enable $k.service
			sudo service $k start
			sudo service $k status | head -50

			echo ''
			echo "=============================================="
			echo "Done: OpenvSwitch $k started.                "
			echo "=============================================="

			sleep 5

			clear
		else
			clear

			echo ''
			echo "=============================================="
			echo "OpenvSwitch $k previously installed.          "
			echo "=============================================="
			echo ''
		
			sleep 5

			clear
        	fi

		echo ''
		echo "=============================================="
		echo "Installed OpenvSwitch $k.                     "
		echo "=============================================="

		sleep 5

		clear
	done
else
	echo ''
	echo "=============================================="
	echo "Starting OpenvSwitch sw1 ...                  "
	echo "=============================================="

	sudo chmod 755 /etc/network/openvswitch/crt_ovs_sw1.sh
	sudo /etc/network/openvswitch/crt_ovs_sw1.sh >/dev/null 2>&1
	echo ''
	sleep 3
	sudo ifconfig sw1
	sudo sed -i '/sw1/s/^# //g' /etc/network/if-up.d/orabuntu-lxc-net

	echo "=============================================="
	echo "OpenvSwitch sw1 started.                      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Starting OpenvSwitch sx1 ...                  "
	echo "=============================================="

	sudo chmod 755 /etc/network/openvswitch/crt_ovs_sx1.sh
	sudo /etc/network/openvswitch/crt_ovs_sx1.sh >/dev/null 2>&1
	echo ''
	sleep 3
	sudo ifconfig sx1
	sudo sed -i '/sx1/s/^# //g' /etc/network/if-up.d/orabuntu-lxc-net

	echo "=============================================="
	echo "OpenvSwitch sx1 started.                      "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Ensure 10.207.39.0/24 & 10.207.29.0/24 up...  "
	echo "=============================================="
	echo ''

	sudo ifconfig sw1
	sudo ifconfig sx1

	echo "=============================================="
	echo "Networks are up.                              "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

sleep 5

clear

sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" 							/etc/systemd/orabuntu-resolv.conf
sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" 						/etc/systemd/orabuntu-resolv.conf

if   [ $SystemdResolvedInstalled -ge 1 ]
then
	echo ''
	echo "=============================================="
	echo "Create systemd-resolved-helper service...     "
	echo "=============================================="
	echo ''

	sudo sh -c "echo '[Unit]'                                                					 > /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo 'Description=systemd-resolved-helper Service'							>> /etc/systemd/system/systemd-resolved-helper.service"
#	sudo sh -c "echo 'Wants=sw1.service sx1.service'								>> /etc/systemd/system/systemd-resolved-helper.service"
#	sudo sh -c "echo 'After=sw1.service sx1.service'								>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo ''												>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo '[Service]'											>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo 'Type=idle'											>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo 'User=root'											>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo 'RemainAfterExit=yes'										>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo 'ExecStart=/bin/ln -sf /etc/systemd/orabuntu-resolv.conf /etc/resolv.conf'			>> /etc/systemd/system/systemd-resolved-helper.service"

	if   [ $UbuntuMajorVersion -gt 16 ]
	then
		sudo sh -c "echo 'ExecStop=/bin/ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf'		>> /etc/systemd/system/systemd-resolved-helper.service"
	
	elif [ $UbuntuMajorVersion -eq 16 ]
	then
		sudo sh -c "echo 'ExecStop=/bin/ln -sf /run/resolvconf/resolv.conf /etc/resolv.conf'			>> /etc/systemd/system/systemd-resolved-helper.service"
	fi

	sudo sh -c "echo ''												>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo '[Install]'											>> /etc/systemd/system/systemd-resolved-helper.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'									>> /etc/systemd/system/systemd-resolved-helper.service"

	sudo systemctl daemon-reload
	sudo systemctl enable systemd-resolved-helper
	sudo service systemd-resolved-helper start

	echo ''
	echo "=============================================="
	echo "Done: Create systemd-resolved-helper service  "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

if [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Setting secret in dhcpd.conf file...          "
	echo "=============================================="
	echo ''

	function GetKeySecret {
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/bind/rndc.key | grep secret | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	KeySecret=$(GetKeySecret)
	echo $KeySecret
	sudo sed -i "/secret/c\key rndc-key { algorithm hmac-sha256; $KeySecret }" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
	echo 'The following keys should match (for dynamic DNS updates by DHCP):'
	echo ''
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf | grep secret | cut -f7 -d' ' | cut -f1 -d';'
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/bind/rndc.key   | grep secret | cut -f2 -d' ' | cut -f1 -d';'
	echo ''
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf | grep secret

	echo ''
	echo "=============================================="
	echo "Secret successfuly set in dhcpd.conf file.    "
	echo "=============================================="

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Checking OpenvSwitch sw1...                   "
echo "=============================================="

sudo service sw1 stop
sleep 2
sudo service sw1 start
sleep 2
echo ''
sudo ifconfig sw1
echo ''
sudo service sw1 status | head -50

echo ''
echo "=============================================="
echo "OpenvSwitch sw1 is up.                        "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Checking OpenvSwitch sx1...                   "
echo "=============================================="

sudo service sx1 stop
sleep 2
sudo service sx1 start
sleep 2
echo ''
sudo ifconfig sx1
echo ''
sudo service sx1 status | head -50

echo ''
echo "=============================================="
echo "OpenvSwitch sx1 is up.                        "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Both required networks are up.                "
echo "=============================================="
echo ''

sleep 5

clear

if [ $GRE = 'Y' ] || [ $MultiHostVar3 != 'X' ]
then
	echo ''
	echo "=============================================="
	echo "Verify iptables rules are set correctly...    "
	echo "=============================================="
	echo ''

	sudo iptables -S | egrep 'sw1|sx1'

	echo ''
	echo "=============================================="
	echo "Verification of iptables rules complete.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ] && [ $MultiHostVar2 = 'N' ]
then
	sudo lxc-update-config -c /var/lib/lxc/$NameServer/config
fi

if [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Start LXC DNS DHCP container...               "
	echo "=============================================="
	echo ''

	sleep 5

	clear

        if [ -n $NameServer ]
        then
                sudo service sw1 restart
                sudo service sx1 restart
		sudo sed -i "/1500/s/1500/$MultiHostVar7/g"	/var/lib/lxc/$NameServer/config 	> /dev/null 2>&1
		sudo sed -i "/1500/s/1500/$MultiHostVar7/g"	/var/lib/lxc/$NameServerBase/config 	> /dev/null 2>&1

                function CheckFileSystemTypeXfs {
                        stat --file-system --format=%T /var/lib/lxc | grep -c xfs
                }
                FileSystemTypeXfs=$(CheckFileSystemTypeXfs)

                function CheckFileSystemTypeExt {
                        stat --file-system --format=%T /var/lib/lxc | grep -c ext
                }
                FileSystemTypeExt=$(CheckFileSystemTypeExt)

                if [ $FileSystemTypeXfs -eq 1 ]
                then
                        function GetFtype {
                                xfs_info / | grep -c ftype=1
                        }
                        Ftype=$(GetFtype)

                        if   [ $Ftype -eq 0 ]
                        then
                                sudo lxc-stop  -n $NameServer > /dev/null 2>&1
                                sudo lxc-copy  -n $NameServer -N $NameServerBase
                                NameServer=$NameServerBase
                                sudo lxc-start -n $NameServer

                        elif [ $Ftype -eq 1 ]
                        then
                                sudo lxc-stop  -n $NameServer > /dev/null 2>&1
                                sudo lxc-copy  -n $NameServer -N $NameServerBase -B overlayfs -s
                                NameServer=$NameServerBase
                                sudo lxc-start -n $NameServer
                        fi
                fi

                if [ $FileSystemTypeExt -eq 1 ]
                then
                        sudo lxc-stop  -n $NameServer > /dev/null 2>&1
                        sudo lxc-copy  -n $NameServer -N $NameServerBase -B overlayfs -s
                        NameServer=$NameServerBase
                        sudo lxc-start -n $NameServer
                fi
        fi

	echo ''
	echo "=============================================="
	echo "Done: Start LXC DNS DHCP container.           "
	echo "=============================================="

	sleep 5

	clear

	if [ ! -f /etc/systemd/system/$NameServer.service ]
	then
		echo ''
		echo "=============================================="
		echo "Create $NameServer Onboot Service...          "
		echo "=============================================="
		echo ''

		sudo sh -c "echo '[Unit]'             	         				 > /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'Description=$NameServer Service'  				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'Wants=network-online.target sw1.service sx1.service'		>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'After=network-online.target sw1.service sx1.service'		>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo ''                                 				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo '[Service]'                        				>> /etc/systemd/system/$NameServer.service"
	
		if [ $AWS -eq 1 ]
		then
			sudo sh -c "echo 'Type=idle'                   				>> /etc/systemd/system/$NameServer.service"
		else
			sudo sh -c "echo 'Type=oneshot'                   			>> /etc/systemd/system/$NameServer.service"
		fi

		sudo sh -c "echo 'User=root'                        				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'RemainAfterExit=yes'              				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_$NameServer.sh start'	>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/strt_$NameServer.sh stop'	>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo ''                                 				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo '[Install]'                        				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'WantedBy=multi-user.target'       				>> /etc/systemd/system/$NameServer.service"
		sudo chmod 644 /etc/systemd/system/$NameServer.service

		echo "/etc/systemd/system/$NameServer.service" >> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
        	sudo cp -p /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst ~/nameserver.lst
		sudo sed -i "s/-base//g" /etc/network/openvswitch/strt_$NameServer.sh
 
		sudo systemctl enable $NameServer

		echo ''
		echo "=============================================="
		echo "Created $NameServer Onboot Service.           "
		echo "=============================================="
	fi
fi

sleep 5

clear

# echo "NameServerExists = "$NameServerExists
# echo "MultiHostVar2    = "$MultiHostVar2
# sleep 30

if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'Y' ]
then
        echo ''
        echo "=============================================="
        echo "Replicate nameserver $NameServer...           "
        echo "=============================================="

        sudo mkdir -p /home/$Owner/Manage-Orabuntu
        sudo chown $Owner:$Group /home/$Owner/Manage-Orabuntu
        sudo chmod 775 /opt/olxc/"$DistDir"/orabuntu/archives/nameserver_copy.sh

	# GLS 20180411 Create the tar.gz of the source nameserver dynamically so that GRE hosts pick up all post-install nameserver configuration changes.

	sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S -p' '  <<< "$MultiHostVar9" echo ''; sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServerBase -k; sudo -S <<< "$MultiHostVar9" tar -P -czf ~/Manage-Orabuntu/"$NameServerBase".export."$HOSTNAME".tar.gz -T ~/Manage-Orabuntu/nameserver.lst --checkpoint=10000 --totals; sleep 2; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServerBase"

#	sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" echo '(Do NOT enter passwords...Wait...)'; echo ''; sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServerBase -k; sudo -S <<< "$MultiHostVar9" cat /home/orabuntu/.ssh/authorized_keys | cut -f3 -d' ' | cut -f2 -d'@' >> /var/lib/lxc/afns1/delta0/root/gre_hosts.txt; sudo -S <<< "$MultiHostVar9" cat /var/lib/lxc/afns1/delta0/root/gre_hosts.txt | sort -u > /var/lib/lxc/afns1/delta0/root/gre_hosts.tmp; sudo -S <<< "$MultiHostVar9" mv /var/lib/lxc/afns1/delta0/root/gre_hosts.tmp /var/lib/lxc/afns1/delta0/root/gre_hosts.txt; sudo -S <<< "$MultiHostVar9" tar -P -czf ~/Manage-Orabuntu/"$NameServerBase".export."$HOSTNAME".tar.gz -T ~/Manage-Orabuntu/nameserver.lst --checkpoint=10000 --totals; sleep 2; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServerBase"

        /opt/olxc/"$DistDir"/orabuntu/archives/nameserver_copy.sh $MultiHostVar5 $MultiHostVar6 $MultiHostVar8 $MultiHostVar9 $NameServerBase

        echo ''
        echo "=============================================="
        echo "Done: Replicate nameserver $NameServer.       "
        echo "=============================================="
        echo ''

        # Case 1 importing nameserver from an 2.1+ LXC enviro into a 2.0- LXC enviro.

        function CheckNameServerConfigFormat {
                sudo egrep -c 'lxc.net.0|lxc.net.1|lxc.uts.name|lxc.apparmor.profile' /var/lib/lxc/$NameServer/config
        }
        NameServerConfigFormat=$(CheckNameServerConfigFormat)

        function CheckNameServerBaseConfigFormat {
                sudo egrep -c 'lxc.net.0|lxc.net.1|lxc.uts.name|lxc.apparmor.profile' /var/lib/lxc/"$NameServerBase"/config
        }
        NameServerBaseConfigFormat=$(CheckNameServerBaseConfigFormat)

        if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion 2.1.0) ] && [ $NameServerConfigFormat -gt 0 ]
        then
                sudo sed -i 's/lxc.net.0/lxc.network/g'         	/var/lib/lxc/$NameServer/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'         	/var/lib/lxc/$NameServer/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'      	/var/lib/lxc/$NameServer/config
		sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'	/var/lib/lxc/$NameServer/config
        fi

        if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion 2.1.0) ] && [ $NameServerBaseConfigFormat -gt 0 ]
        then
                sudo sed -i 's/lxc.net.0/lxc.network/g'         	/var/lib/lxc/$NameServerBase/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'         	/var/lib/lxc/$NameServerBase/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'      	/var/lib/lxc/$NameServerBase/config
		sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'	/var/lib/lxc/$NameServerBase/config
        fi

        # Case 2 importing nameserver from an 2.0- LXC enviro into a 2.1+ LXC enviro.

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion 2.1.0) ] && [ $NameServerConfigFormat -eq 0 ]
        then
                sudo lxc-update-config -c /var/lib/lxc/"$NameServer"/config
                sudo lxc-update-config -c /var/lib/lxc/"$NameServerBase"/config
        fi

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion 2.1.0) ] && [ $NameServerBaseConfigFormat -eq 0 ]
        then
                sudo lxc-update-config -c /var/lib/lxc/"$NameServer"/config
                sudo lxc-update-config -c /var/lib/lxc/"$NameServerBase"/config
        fi

        sudo lxc-ls -f
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Checking and Configuring MultiHost Settings..."
echo "=============================================="
echo ''

sleep 5

clear

if [ $MultiHostVar2 = 'N' ]
then
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw2.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw3.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw4.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw5.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw6.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw7.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw8.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw9.sh

        echo ''
        echo "=============================================="
        echo "Unpack SCST Linux SAN Files...                "
        echo "=============================================="
        echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/scst-files.tar -C / --touch

        sudo chown -R $Owner:$Group             /opt/olxc/home/scst-files/.
        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"   /opt/olxc/home/scst-files/create-scst-target.sh

        echo ''
        echo "=============================================="
        echo "Done: Unpack SCST Linux SAN Files.            "
        echo "=============================================="
        echo ''

        sleep 5

        clear

        echo ''
        echo "=============================================="
        echo "Unpack TGT Linux SAN Files...                "
        echo "=============================================="
        echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/tgt-files.tar  -C / --touch

        echo ''
        echo "=============================================="
        echo "Done: Unpack TGT Linux SAN Files.            "
        echo "=============================================="
        echo ''

        sleep 5

        clear

	echo ''
	echo "=============================================="
	echo "Setting ubuntu user password in $NameServer..."
	echo "=============================================="
	echo ''

	sudo lxc-attach -n $NameServer -- usermod --password `perl -e "print crypt('ubuntu','ubuntu');"` ubuntu
	ssh-keygen -R 10.207.39.2
	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "date; uname -a"
	
	echo ''
	echo "=============================================="
	echo "Done: Set ubuntu password in $NameServer.     "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Configure jobs in $NameServer...              "
	echo "=============================================="
	echo ''

	genpasswd() { 
		local l=$1
       		[ "$l" == "" ] && l=8
      		tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs 
	}
	password=$(genpasswd)

	USERNAME=amide
	PASSWORD=$password

	sudo sed -i "s/Owner=ubuntu/Owner=amide/"	/var/lib/lxc/"$NameServer"-base/rootfs/root/ns_backup_update.sh
	sudo sed -i "s/Pass=ubuntu/Pass=$password/"	/var/lib/lxc/"$NameServer"-base/rootfs/root/ns_backup_update.sh

 	sudo useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash ${USERNAME}
	sudo mkdir -p /home/${USERNAME}/Downloads

	function CutOffBase {
		echo $NameServer | cut -f1 -d'-'
	}
	OffBase=$(CutOffBase)

	sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
	sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$OffBase/updates

	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Downloads 
	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Manage-Orabuntu
	sudo chmod -R 777 /home/${USERNAME}/Manage-Orabuntu

	sudo sed -i "/lxc\.mount\.entry/s/#/ /"              /var/lib/lxc/$NameServer/config
	sudo sed -i "/Manage\-Orabuntu/s/afns1\-base/afns1/" /var/lib/lxc/$NameServer/config

	sudo lxc-stop -n $NameServer
	sleep 5
	sudo lxc-start -n $NameServer
	clear

	echo ''
	echo "=============================================="
	echo "Done: Configure jobs in $NameServer.          "
	echo "=============================================="
	echo ''

	sleep 5

	clear

        echo ''
        echo "=============================================="
        echo "Create amide user RSA key...                  "
        echo "=============================================="
        echo ''

	sudo runuser -l amide -c "ssh-keygen -f /home/amide/.ssh/id_rsa -t rsa -N ''"

        echo ''
        echo "=============================================="
        echo "Done: Create amide user RSA key.              "
        echo "=============================================="

        sleep 5

        clear

	sudo sh -c "echo 'amide ALL=/bin/mkdir, /bin/cp, /bin/chown, /bin/mv' > /etc/sudoers.d/amide"
	sudo chmod 0440 /etc/sudoers.d/amide

	sudo lxc-attach -n $NameServer -- crontab /root/crontab.txt

        echo ''
        echo "=============================================="
        echo "Display $NameServer replica cronjob...        "
        echo "=============================================="
        echo ''

	sudo lxc-attach -n $NameServer -- crontab -l | tail -23

        echo ''
        echo "=============================================="
        echo "Done: Display $NameServer replica cronjob.    "
        echo "=============================================="
        echo ''

	sleep 5

	clear

        echo ''
        echo "=============================================="
        echo "Extract DNS sync service files ...            "
        echo "=============================================="
        echo ''
 
#	sudo lxc-attach -n $NameServer -- mkdir -p /root/backup-lxc-container/$NameServer/updates
	sudo lxc-attach -n $NameServer -- touch /root/gre_hosts.txt
	sudo lxc-attach -n $NameServer -- touch /home/ubuntu/gre_hosts.txt

#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" echo $HOSTNAME > ~/new_gre_host.txt"
#	sudo lxc-attach -n $NameServer -- cat ~/new_gre_host.txt
#	sleep 5
	
	sudo lxc-attach -n $NameServer -- tar -cvzPf /root/backup-lxc-container/$NameServer/updates/backup_"$NameServer"_ns_update.tar.gz -T /root/ns_backup_update.lst --numeric-owner
        
	sudo tar -v --extract --file=/opt/olxc/"$DistDir"/orabuntu/archives/dns-dhcp-cont.tar -C / var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-sync.service
        sudo tar -v --extract --file=/opt/olxc/"$DistDir"/orabuntu/archives/dns-dhcp-cont.tar -C / var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-thaw.service
        sudo mv /var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-sync.service /var/lib/lxc/"$NameServer"-base/rootfs/etc/systemd/system/dns-sync.service
        sudo mv /var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-thaw.service /var/lib/lxc/"$NameServer"-base/rootfs/etc/systemd/system/dns-thaw.service

	sudo lxc-attach -n $NameServer -- systemctl enable dns-sync
	sudo lxc-attach -n $NameServer -- systemctl enable dns-thaw
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/fwd.$Domain1
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/rev.$Domain1
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/fwd.$Domain2
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/rev.$Domain2
        sudo lxc-attach -n $NameServer -- chown root:bind /var/lib/bind
        sudo lxc-attach -n $NameServer -- chmod 775 /var/lib/bind

        echo ''
        echo "=============================================="
        echo "Done: Extract DNS sync service files.         "
        echo "=============================================="

        sleep 5

        clear

        echo ''
        echo "=============================================="
        echo "Create $NameServer RSA key...                 "
        echo "=============================================="
        echo ''

	sudo lxc-attach -n $NameServer -- ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''

        echo ''
        echo "=============================================="
        echo "Done: Create $NameServer RSA key.             "
        echo "=============================================="
        echo ''

        sleep 5

        clear

	NameServerBase=$(GetNameServerBase)

#	sudo sh -c "cat '/var/lib/lxc/$NameServerBase/overlay/delta/root/.ssh/id_rsa.pub'             	>> /home/amide/.ssh/authorized_keys"
#	sudo sh -c "cat '/var/lib/lxc/$NameServerBase/delta0/root/.ssh/id_rsa.pub' 			>> /home/amide/.ssh/authorized_keys"
#	sudo sh -c "cat '/var/lib/lxc/$NameServer/delta0/root/.ssh/id_rsa.pub'     			>  /home/amide/.ssh/authorized_keys"

	echo ''
	echo "=============================================="
	echo "Done: Configure jobs in $NameServer.          "
	echo "=============================================="
fi

sleep 5

clear

if [ $MultiHostVar2 = 'Y' ]
then
#	GLS 20170904 Switches sx1 and sw1 are set earlier (around lines 1988,1989) so they are not set here.

	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw2.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw3.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw4.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw5.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw6.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw7.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw8.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw9.sh
	
        echo ''
        echo "=============================================="
        echo "Unpack SCST Linux SAN Files...                "
        echo "=============================================="
        echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/scst-files.tar -C / --touch

        sudo chown -R $Owner:$Group             /opt/olxc/home/scst-files/.
        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"   /opt/olxc/home/scst-files/create-scst-target.sh

        echo ''
        echo "=============================================="
        echo "Done: Unpack SCST Linux SAN Files.            "
        echo "=============================================="
        echo ''

        sleep 5

        clear

        echo ''
        echo "=============================================="
        echo "Unpack TGT Linux SAN Files...                "
        echo "=============================================="
        echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/tgt-files.tar  -C / --touch

        echo ''
        echo "=============================================="
        echo "Done: Unpack TGT Linux SAN Files.            "
        echo "=============================================="
        echo ''

        sleep 5

        clear

        echo ''
        echo "=============================================="
        echo "Configure NS Replication Account...           "
        echo "=============================================="
        echo ''

        function GetAmidePassword {
		sudo sh -c "cat /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.sh" | grep 'Pass=' | cut -f2 -d'='
        }
        AmidePassword=$(GetAmidePassword)

        USERNAME=amide
        PASSWORD=$AmidePassword

        sudo useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash ${USERNAME}
        sudo mkdir -p /home/${USERNAME}/Downloads

	function CutOffBase {
		echo $NameServer | cut -f1 -d'-'
	}
	OffBase=$(CutOffBase)

	sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
	sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$OffBase/updates

	echo "sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$OffBase/updates"
	echo "sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer/updates"a

	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Downloads 
	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Manage-Orabuntu
	sudo chmod -R 744 /home/${USERNAME}/Manage-Orabuntu
	sudo chmod -R 744 /home/${USERNAME}/Downloads
	sudo runuser -l amide -c "ssh-keygen -f /home/amide/.ssh/id_rsa -t rsa -N ''"
	sudo sh -c "cat '/var/lib/lxc/$NameServerBase/delta0/root/.ssh/id_rsa.pub' >> /home/amide/.ssh/authorized_keys"
	sudo sed -i "/lxc\.mount\.entry/s/#/ /" /var/lib/lxc/$NameServer/config
	sudo sh -c "echo 'amide ALL=/bin/mkdir, /bin/cp' > /etc/sudoers.d/amide"
        sudo chmod 0440 /etc/sudoers.d/amide

#	echo ''
#	echo "=============================================="
#	echo "Debug of new file transfer mechanism ..."
#       echo "=============================================="
#	echo ''

#	echo "NameServer = "$NameServer	
#	echo "USERNAME   = "${USERNAME}
#	sudo ls -l /home/${USERNAME}/Manage-Orabuntu
#	sudo ls -l /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/
#	sudo ls -l /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer
#	sudo ls -l /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
#	sudo lxc-attach -n $NameServer -- sudo touch /root/backup-lxc-container/afns1/updates/testfile
#	sudo ls -l /home/amide/Manage-Orabuntu/backup-lxc-container/afns1/updates
#	sudo lxc-attach -n $NameServer -- ls -l /root/backup-lxc-container/afns1/updates

	echo ''
        echo "=============================================="
        echo "Done: Configure NS Replication Account.       "
        echo "=============================================="
        echo ''

	sleep 5

	clear

	if [ $GRE = 'Y' ]
	then
                sudo sed -i "/route add -net/s/#/ /"                            /etc/network/openvswitch/crt_ovs_sw1.sh
                sudo sed -i "/REMOTE_GRE_ENDPOINT/s/#/ /"                       /etc/network/openvswitch/crt_ovs_sw1.sh
                sudo sed -i "s/REMOTE_GRE_ENDPOINT/$MultiHostVar5/g"            /etc/network/openvswitch/crt_ovs_sw1.sh

		if   [ $TunType = 'geneve' ]
		then
                	sudo ovs-vsctl add-port sw1 geneve$Sw1Index -- set interface geneve$Sw1Index type=geneve options:remote_ip=$MultiHostVar5 options:key=flow

			sudo sed -i '/type=gre/d'				/etc/network/openvswitch/crt_ovs_sw1.sh	
			sudo sed -i '/type=vxlan/d'				/etc/network/openvswitch/crt_ovs_sw1.sh	
		
		elif [ $TunType = 'gre' ]
		then
			sudo ovs-vsctl add-port sw1 gre$Sw1Index    -- set interface gre$Sw1Index    type=gre    options:remote_ip=$MultiHostVar5

			sudo sed -i '/type=geneve/d'				/etc/network/openvswitch/crt_ovs_sw1.sh	
			sudo sed -i '/type=vxlan/d'				/etc/network/openvswitch/crt_ovs_sw1.sh	

		elif [ $TunType = 'vxlan' ]
		then
                	sudo ovs-vsctl add-port sw1 vxlan$Sw1Index -- set interface vxlan$Sw1Index type=vxlan options:remote_ip=$MultiHostVar5 options:key=flow

			sudo sed -i '/type=geneve/d'				/etc/network/openvswitch/crt_ovs_sw1.sh	
			sudo sed -i '/type=gre/d'				/etc/network/openvswitch/crt_ovs_sw1.sh	

		fi

                echo ''
                echo "=============================================="
                echo "Show local GRE endpoint...                    "
                echo "=============================================="
                echo ''

                sudo ovs-vsctl show | grep -A1 -B2 'type: gre' | grep -B4 "$MultiHostVar5" | sed 's/^[ \t]*//;s/[ \t]*$//'

                echo ''
                echo "=============================================="
                echo "Done: Show local GRE endpoint.                "
                echo "=============================================="
                echo ''

                sudo cp -p /etc/network/openvswitch/setup_gre_and_routes.sh /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

                sudo sed -i "s/MultiHostVar6/$MultiHostVar6/g"  /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
                sudo sed -i "s/MultiHostVar3/$Sw1Index/g"       /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

		if   [ $TunType = 'geneve' ]
		then
			sudo sed -i '/type=gre/d'		/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/type=vxlan/d'		/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
		
		elif [ $TunType = 'gre' ]
		then
			sudo sed -i '/type=geneve/d'		/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/type=vxlan/d'		/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

		elif [ $TunType = 'vxlan' ]
		then
			sudo sed -i '/type=geneve/d'		/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/type=gre/d'		/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
		fi

                sudo chmod 777 /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

                sleep 5

                clear

                echo ''
                echo "=============================================="
                echo "Setup GRE & Routes on $MultiHostVar5...       "
                echo "=============================================="
                echo ''

                ssh-keygen -R $MultiHostVar5
                sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 date
                if [ $? -eq 0 ]
                then
                	sshpass -p $MultiHostVar9 scp -p /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh $MultiHostVar8@$MultiHostVar5:~/.
                fi
                sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" ls -l ~/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh"
                if [ $? -eq 0 ]
                then
                	sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" ~/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh"
                fi

                echo ''
                echo "=============================================="
                echo "Done: Setup GRE & Routes on $MultiHostVar5.   "
                echo "=============================================="
                echo ''

                sleep 5

                clear

		if [ $UbuntuMajorVersion -eq 16 ]
		then
			sudo sh -c "echo 'nameserver 10.207.39.2'						>  /run/resolvconf/resolv.conf"
			sudo sh -c "echo 'nameserver 10.207.29.2'						>> /run/resolvconf/resolv.conf"
			sudo sh -c "echo 'search orabuntu-lxc.com consultingcommandos.us gns1.orabuntu-lxc.com'	>> /run/resolvconf/resolv.conf"
		fi

                function GetShortHost {
                        uname -n | cut -f1 -d'.'
                }
                ShortHost=$(GetShortHost)

		sudo ifconfig sw1 mtu $MultiHostVar7
		sudo ifconfig sx1 mtu $MultiHostVar7

                sudo nslookup $HOSTNAME.$Domain1 > /dev/null 2>&1
                if [ $? -eq 1 ]
                then
                        echo ''
                        echo "=============================================="
                        echo "Create ADD DNS $ShortHost.$Domain1...         "
                        echo "=============================================="
                        echo ''

                        sudo sh -c "echo 'echo \"server 10.207.39.2'								>  /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
                        sudo sh -c "echo 'update add $ShortHost.orabuntu-lxc.com 3600 IN A 10.207.39.$Sw1Index'			>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
                        sudo sh -c "echo 'send'											>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
                        sudo sh -c "echo 'update add $Sw1Index.39.207.10.in-addr.arpa 3600 IN PTR $ShortHost.orabuntu-lxc.com'	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
                        sudo sh -c "echo 'send'											>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
                        sudo sh -c "echo 'quit'											>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
                        sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"

                        sudo chmod 777                                          /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh
                        sudo ls -l                                              /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh
                        sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"            /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh

                        echo ''
                        echo "=============================================="
                        echo "Create DEL DNS $ShortHost.$Domain1...         "
                        echo "=============================================="
                        echo ''

                        sudo sh -c "echo 'echo \"server 10.207.39.2'					>  /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
                        sudo sh -c "echo 'update delete $ShortHost.orabuntu-lxc.com. A'			>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
                        sudo sh -c "echo 'send'								>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
                        sudo sh -c "echo 'update delete $Sw1Index.39.207.10.in-addr.arpa. PTR'		>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
                        sudo sh -c "echo 'send'								>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
                        sudo sh -c "echo 'quit'								>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
                        sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'				>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"

                        sudo chmod 777                                          /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh
                        sudo ls -l                                              /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh
                        sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"            /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh

                        ssh-keygen -R 10.207.39.2
                        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
                        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
                        sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
			sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
                        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain1_add_$ShortHost.sh"

                        echo ''
                        echo "=============================================="
                        echo "Done: Create ADD/DEL DNS $ShortHost.$Domain1  "
                        echo "=============================================="
                        echo ''

                        sleep 5

                        clear

                fi

                sudo nslookup $HOSTNAME.$Domain2 > /dev/null 2>&1
                if [ $? -eq 1 ]
                then
                        echo ''
                        echo "=============================================="
                        echo "Create ADD DNS $ShortHost.$Domain2 ...        "
                        echo "=============================================="
                        echo ''

                        sudo sh -c "echo 'echo \"server 10.207.29.2'									>  /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
                        sudo sh -c "echo 'update add $ShortHost.consultingcommandos.us 3600 IN A 10.207.29.$Sx1Index'			>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
                        sudo sh -c "echo 'send'												>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
                        sudo sh -c "echo 'update add $Sx1Index.29.207.10.in-addr.arpa 3600 IN PTR $ShortHost.consultingcommandos.us'	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
                        sudo sh -c "echo 'send'												>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
                        sudo sh -c "echo 'quit'												>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
                        sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'								>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"

                        sudo chmod 777                                          /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh
                        sudo ls -l                                              /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh
                        sudo sed -i "s/consultingcommandos\.us/$Domain2/g"      /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh

                        echo ''
                        echo "=============================================="
                        echo "Create DEL DNS $ShortHost.$Domain2...         "
                        echo "=============================================="
                        echo ''

                        sudo sh -c "echo 'echo \"server 10.207.29.2'					>  /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
                        sudo sh -c "echo 'update delete $ShortHost.consultingcommandos.us. A'		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
                        sudo sh -c "echo 'send'								>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
                        sudo sh -c "echo 'update delete $Sx1Index.29.207.10.in-addr.arpa. PTR'		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
                        sudo sh -c "echo 'send'								>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
                        sudo sh -c "echo 'quit'								>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
                        sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'				>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"

                        sudo chmod 777						/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh
                        sudo ls -l						/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh
                        sudo sed -i "s/consultingcommandos\.us/$Domain2/g"	/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh

                        ssh-keygen -R 10.207.29.2
                        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
                        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
                        sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh ubuntu@10.207.29.2:~/Downloads/.
			sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh ubuntu@10.207.29.2:~/Downloads/.
                        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain2_add_$ShortHost.sh"

                        echo ''
                        echo "=============================================="
                        echo "Done: Create ADD/DEL DNS $ShortHost.$Domain2  "
                        echo "=============================================="
                        echo ''

                        sleep 5

                        clear
                fi
        fi
fi

if [ $SystemdResolvedInstalled -ge 1 ]
then
        echo ''
        echo "=============================================="
        echo "Restart systemd-resolved...                   "
        echo "=============================================="
        echo ''

        sudo service systemd-resolved restart
        sleep 2
	sudo service systemd-resolved status | head -50

        echo ''
        echo "=============================================="
        echo "Done: Restart systemd-resolved.               "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

if [ $LxcNetRunning -ge 1 ]
then
        echo ''
        echo "=============================================="
        echo "Restart service lxc-net...                    "
        echo "=============================================="
        echo ''

        sudo service lxc-net restart
        sleep 2
        sudo service lxc-net status | head -50

        echo ''
        echo "=============================================="
        echo "Done: Restart service lxc-net.                "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

# GLS 20161118 This section for any tweaks to the unpacked files from archives.
if [ $UbuntuMajorVersion -ge 16 ]
then
	sudo rm /etc/network/if-up.d/orabuntu-lxc-net
fi

echo ''
echo "=============================================="
echo "MultiHost Settings Completed.                 "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Moving seed openvswitch veth files...         "
echo "=============================================="
echo ''

if [ ! -e /etc/orabuntu-lxc-release ] || [ ! -e /etc/network/if-up.d/lxcora00-pub-ifup-sw1 ] || [ ! -e /etc/network/if-down.d/lxcora00-pub-ifdown-sw1 ]
then
	cd /etc/network/if-up.d/openvswitch

	sudo cp lxcora00-asm1-ifup-sw8  oel$OracleRelease-asm1-ifup-sw8
	sudo cp lxcora00-asm2-ifup-sw9  oel$OracleRelease-asm2-ifup-sw9
	sudo cp lxcora00-priv1-ifup-sw4 oel$OracleRelease-priv1-ifup-sw4
	sudo cp lxcora00-priv2-ifup-sw5 oel$OracleRelease-priv2-ifup-sw5
	sudo cp lxcora00-priv3-ifup-sw6 oel$OracleRelease-priv3-ifup-sw6 
	sudo cp lxcora00-priv4-ifup-sw7 oel$OracleRelease-priv4-ifup-sw7
	sudo cp lxcora00-pub-ifup-sw1   oel$OracleRelease-pub-ifup-sw1

	cd /etc/network/if-down.d/openvswitch

	sudo cp lxcora00-asm1-ifdown-sw8  oel$OracleRelease-asm1-ifdown-sw8
	sudo cp lxcora00-asm2-ifdown-sw9  oel$OracleRelease-asm2-ifdown-sw9
	sudo cp lxcora00-priv1-ifdown-sw4 oel$OracleRelease-priv1-ifdown-sw4
	sudo cp lxcora00-priv2-ifdown-sw5 oel$OracleRelease-priv2-ifdown-sw5
	sudo cp lxcora00-priv3-ifdown-sw6 oel$OracleRelease-priv3-ifdown-sw6
	sudo cp lxcora00-priv4-ifdown-sw7 oel$OracleRelease-priv4-ifdown-sw7
	sudo cp lxcora00-pub-ifdown-sw1   oel$OracleRelease-pub-ifdown-sw1

	sudo ls -l /etc/network/if-up.d/openvswitch
	echo ''
	sudo ls -l /etc/network/if-down.d/openvswitch
fi

echo ''
echo "=============================================="
echo "Moving seed openvswitch veth files complete.  "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Create the crt_links.sh script...             "
echo "=============================================="
echo ''

sudo mkdir -p /etc/orabuntu-lxc-scripts

sudo sh -c "echo ' ln -sf /var/lib/lxc .' 								    > /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/resolv.conf .' 								   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/ssh/sshd_config .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"

if [ -n $NameServer ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1 .'	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1 .'	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces .'		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/rndc.key .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/default/bind9 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/dhcp/dhcpd.leases .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/dhcp .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/default/isc-dhcp-server .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/default/bind9 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.options .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ ! -n $NameServer ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1 .'		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1 .'		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/resolv.conf .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/rndc.key .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/default/bind9 .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/var/lib/dhcp/dhcpd.leases .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/dhcp .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/dhcp/dhcpd.conf .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/default/isc-dhcp-server .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/default/bind9 .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/named.conf .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/named.conf.local .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/named.conf.options .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ -n $Domain1 ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ -n $Domain2 ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain2 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain2 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

sudo sh -c "echo ' ln -sf /etc/sysctl.d/60-olxc.conf .' 			         		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/security/limits.d/70-oracle.conf .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"

if [ $NetworkManagerInstalled -eq 1 ]
then
	sudo sh -c "echo ' ln -sf /etc/NetworkManager/dnsmasq.d/orabuntu-local .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/NetworkManager/NetworkManager.conf .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if	[ $SystemdResolvedInstalled -ge 1 ]
then
	sudo sh -c "echo ' ln -sf /etc/systemd/resolved.conf .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

sudo sh -c "echo ' ln -sf /etc/orabuntu-lxc-scripts/stop_containers.sh .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/orabuntu-lxc-scripts/start_containers.sh .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw1.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw2.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw3.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw4.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw5.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw6.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw7.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw8.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw9.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sx1.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/del-bridges.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/veth_cleanups.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/create-ovs-sw-files-v2.sh .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/init/openvswitch-switch.conf .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/default/openvswitch-switch .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/multipath.conf .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/multipath.conf.example .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/if-down.d/scst-net .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"

ls -l /etc/orabuntu-lxc-scripts/crt_links.sh

echo ''
echo "=============================================="
echo "Created the crt_links.sh script.              "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Allow NTP to run in LXC Containers...         "
echo "=============================================="

if [ ! -f /usr/share/lxc/config/common.conf.d/01-sys-time.conf ]
then
	sudo touch /usr/share/lxc/config/common.conf.d/01-sys-time.conf
	sudo sh -c "echo 'lxc.cap.drop ='                                              > /usr/share/lxc/config/common.conf.d/01-sys-time.conf"
	sudo sh -c "echo 'lxc.cap.drop = mac_admin mac_override sys_module sys_rawio' >> /usr/share/lxc/config/common.conf.d/01-sys-time.conf"
	echo ''
	sudo ls -l /usr/share/lxc/config/common.conf.d/01-sys-time.conf
	echo ''
	cat /usr/share/lxc/config/common.conf.d/01-sys-time.conf
	echo ''
fi

echo "=============================================="
echo "Done: Allow NTP to run in LXC Containers.     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: orabuntu-services-2.sh    "
echo "=============================================="

sleep 5

