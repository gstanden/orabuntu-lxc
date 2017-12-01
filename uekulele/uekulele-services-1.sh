#!/bin/bash

#    Copyright 2015-2017 Gilbert Standen
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

#    v2.4 GLS 20151224
#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 GLS 20170909 Orabuntu-LXC MultiHost

#    Note that this software builds a conntainerized DNS DHCP solution for the Desktop environment.
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet though (a feature this software does not yet support - it's on the roadmap) to match your subnet manually.

MajorRelease=$1
PointRelease=$2
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
OSMemRes=$6
MultiHost=$7
LxcOvsVersion=$8

function GetLxcVersion {
echo $LxcOvsVersion | cut -f1 -d':'
}
LxcVersion=$(GetLxcVersion)

function GetOvsVersion {
echo $LxcOvsVersion | cut -f2 -d':'
}
OvsVersion=$(GetOvsVersion)

function GetMultiHostVar2 {
echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar4 {
echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

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

function GetMultiHostVar11 {
	echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)

function GetMultiHostVar12 {
	echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)

GRE=$MultiHostVar10
OnVm1=$MultiHostVar11
OnVm2=$MultiHostVar12

function CheckSystemdResolvedInstalled {
        sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

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
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//'
}
LinuxFlavor=$(TrimLinuxFlavors)

if   [ $LinuxFlavor = 'Oracle' ]
then
	function GetOracleDistroRelease {
		sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
	}
	OracleDistroRelease=$(GetOracleDistroRelease)
	Release=$OracleDistroRelease
	LF=$LinuxFlavor
	RL=$Release
elif [ $LinuxFlavor = 'Red' ]
then
	function GetRedHatVersion {
		sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
	}
	RedHatVersion=$(GetRedHatVersion)
	Release=$RedHatVersion 
	LF=$LinuxFlavor'Hat'
	RL=$Release
fi

function GetOperation {
echo $MultiHost | cut -f1 -d':'
}
Operation=$(GetOperation)

clear

echo ''
echo "=============================================="
echo "Script: uekulele-services-1.sh                "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Establish sudo privileges...                  "
echo "=============================================="
echo ''

echo $MultiHostVar4 | sudo -S date

echo ''
echo "=============================================="
echo "Privileges established.                       "
echo "=============================================="

sleep 5

clear

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
echo "Orabuntu-LXC has made a backup of sshd_config "
echo "located in the /etc/ssh directory if you want "
echo "to revert sshd_config to original settings    "
echo "after Orabuntu-LXC install is completed.      "
echo "=============================================="
echo ''

sleep 5

sudo sed -i '/GSSAPIAuthentication/s/yes/no/'                                /etc/ssh/sshd_config
sudo sed -i '/UseDNS/s/yes/no/'                                              /etc/ssh/sshd_config
sudo sed -i '/GSSAPIAuthentication/s/#//'                                    /etc/ssh/sshd_config
sudo sed -i '/UseDNS/s/#//'                                                  /etc/ssh/sshd_config
sudo egrep 'GSSAPIAuthentication|UseDNS'         	                     /etc/ssh/sshd_config
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
		echo ''

		sudo /etc/orabuntu-lxc-scripts/stop_containers.sh

		if [ -d /var/lib/lxc ]
		then
			function CheckContainersExist {
				sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
			}
			ContainersExist=$(CheckContainersExist)

			echo "=============================================="
		read -e -p   "Delete All LXC  Containers? [ Y/N ]     " -i "Y" DestroyAllContainers
			echo "=============================================="
			echo ''

			if [ $DestroyAllContainers = 'Y' ] || [ $DestroyContainers = 'y' ]
			then
				DestroyContainers=$(CheckContainersExist)
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
		sudo ovs-vsctl show

		echo ''
		echo "=============================================="
		echo "Done: Delete OpenvSwitch bridges.             "
		echo "=============================================="
		echo ''

		sudo rm -f /etc/systemd/system/ora*c*.service
		sudo rm -f /etc/systemd/system/oel*c*.service
		sudo rm -f /etc/network/if-up.d/openvswitch/*
		sudo rm -f /etc/network/if-down.d/openvswitch/*
		cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele
		sudo rm -rf facter openvswitch epel lxc selinux
		sudo rm -f /etc/orabuntu-lxc-release

		# GLS 20170925 Oracle Linux OVS and LXC are built from source.    This step deletes the source build directories.
		# GLS 20170925 Ubuntu Linux OVS and LXC are build from packages.  This step is not necessary on Ubuntu Linux.

		echo "=============================================="
		echo "Uninstall lxc packages...                     "
		echo "=============================================="
		echo ''

		sudo yum -y remove lxc lxc-libs

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
		echo "Re-run anylinux-services.sh after reboot...   "
		echo "=============================================="

		sleep 5
	
		sudo reboot
		exit

	fi

# GLS 20170919 Oracle Linux Specific Code Block 1 BEGIN

	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''

	sudo yum clean all
	sudo yum -y install wget tar gzip
 	mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/epel
  	cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/epel
	if   [ $Release -eq 7 ]
	then
  		wget --timeout=3 --tries=3 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  		sudo rpm -ivh epel-release-latest-7.noarch.rpm 
 	elif [ $Release -eq 6 ] 
	then
  		wget --timeout=3 --tries=3 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
  		sudo rpm -ivh epel-release-latest-6.noarch.rpm 
	fi
	sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
	cd /home/ubuntu/Downloads/orabuntu-lxc-master

	sudo yum -y install debootstrap perl libvirt bash-completion bash-completion-extras
	sudo yum -y install lxc libcap-devel libcgroup wget bridge-utils

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Start LXC and related services...             "
	echo "=============================================="
	echo ''

	if [ $Release -eq 7 ] 
	then
		sudo systemctl start lxc.service
		sudo systemctl status lxc.service
		echo ''
		sudo systemctl start libvirtd 
		sudo systemctl status libvirtd
	fi

	echo ''
	echo "=============================================="
	echo "LXC and related services started.             "
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

# GLS 20170919 Oracle Linux Specific Code Block 1 END

# GLS 20170919 Oracle Linux Specific Code Block 2 BEGIN

if [ ! -f /etc/orabuntu-lxc-release ]
then
	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''

	sudo yum -y install wget tar gzip libtool
 	mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/epel
  	cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/epel
	if [ $Release -eq 7 ] 
	then
  		wget --timeout=3 --tries=3 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
  		sudo rpm -ivh epel-release-latest-7.noarch.rpm 
 	elif [ $Release -eq 6 ] 
	then
  		wget --timeout=3 --tries=3 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
  		sudo rpm -ivh epel-release-latest-6.noarch.rpm 
	fi
	sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
	cd /home/ubuntu/Downloads/orabuntu-lxc-master

	sudo yum -y install debootstrap perl libvirt
	sudo yum -y install lxc libcap-devel libcgroup wget bridge-utils

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Run: sudo libtool --finish /usr/lib64         "
	echo "=============================================="
	echo ''

	sudo libtool --finish /usr/lib64

	echo ''
	echo "=============================================="
	echo "Done: sudo libtool --finish /usr/lib64        "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Start LXC and related services...             "
	echo "=============================================="
	echo ''

	if [ $Release -eq 7 ] 
	then
		sudo systemctl start lxc.service
		sudo systemctl status lxc.service
		echo ''
		sudo systemctl start libvirtd 
		sudo systemctl status libvirtd
	fi

	echo ''
	echo "=============================================="
	echo "LXC and related services started.             "
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
fi
	
sleep 5

clear

# GLS 20170927 credit yairchu 
function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetLXCVersion {
        lxc-create --version
}
LXCVersion=$(GetLXCVersion)

if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion $LxcVersion) ]
then
	echo ''
	echo "=============================================="
	echo "Done: Install required LXC package.           "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Upgrade LXC from Source on $LF Linux $RL      "
	echo "=============================================="

	sleep 5
	
	clear

	function GetLXCVersion {
        	lxc-create --version
	}
	LXCVersion=$(GetLXCVersion)

#	echo 'LXCVersion = '$LXCVersion #debug only
#	echo 'LxcVersion = '$LxcVersion #debug only

	while [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion $LxcVersion) ]
	do
		if [ $Release -eq 7 ]
		then
			echo ''
			echo "=============================================="
			echo "Install required packages and prepare...      "
			echo "=============================================="
			echo ''

			sleep 5

			sudo touch /etc/rpm/macros
			sudo yum -y install rpm-build wget openssl-devel gcc make docbook2X xmlto docbook automake graphviz libtool
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc
			
			echo ''
			echo "=============================================="
			echo "Done: Install required packages and prepare.  "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Untar source code and build LXC RPM...        "
			echo "=============================================="
			echo ''

			sleep 5
			
			wget --timeout=3 --tries=3 https://linuxcontainers.org/downloads/lxc/lxc-"$LxcVersion".tar.gz
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p lxc-"$LxcVersion".tar.gz /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild/SOURCES/.
			tar -zxvf lxc-"$LxcVersion".tar.gz
			cp -p lxc-"$LxcVersion"/lxc.spec /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/.
			sudo sed -i '/bash_completion/d' /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/lxc.spec
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc

			function CheckMacrosFile {
				cat /etc/rpm/macros | grep _unpackaged_files_terminate_build | sort -u | grep -c 0
			}
			MacrosFile=$(CheckMacrosFile)

			if [ $MacrosFile -eq 0 ]
			then
				sudo sh -c "echo '%_unpackaged_files_terminate_build 0' >> /etc/rpm/macros"
			fi
			rpmbuild --define '_topdir /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild' -ba lxc.spec
			
			echo ''
			echo "=============================================="
			echo "Done: Untar source code and build LXC RPM     "
			echo "=============================================="
		
			sleep 5

			clear
	
			echo ''
			echo "=============================================="
			echo "Install LXC RPM's...                          "
			echo "=============================================="
			echo ''

			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild/RPMS/x86_64
			sudo yum -y localinstall *.rpm
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc

			echo ''
			echo "=============================================="
			echo "Done: Install LXC RPM's.                      "
			echo "=============================================="

			sleep 5

			clear
		fi
		if [ $Release -eq 6 ] 
		then
			echo ''
			echo "=============================================="
			echo "Untar source code and build LXC RPM...        "
			echo "=============================================="
			echo ''

			sleep 5

			sudo touch /etc/rpm/macros
			sudo yum -y install rpm-build wget openssl-devel gcc make docbook2X xmlto docbook automake graphviz
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc
			wget --timeout=3 --tries=3 https://linuxcontainers.org/downloads/lxc/lxc-"$LxcVersion".tar.gz
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p lxc-"$LxcVersion".tar.gz /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild/SOURCES/.
			tar -zxvf lxc-"$LxcVersion".tar.gz
			cp -p lxc-"$LxcVersion"/lxc.spec /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/.
			sudo sed -i '/bash_completion/d' /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/lxc.spec
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc

			function CheckMacrosFile {
				cat /etc/rpm/macros | grep _unpackaged_files_terminate_build | sort -u | grep -c 0
			}
			MacrosFile=$(CheckMacrosFile)

			if [ $MacrosFile -eq 0 ]
			then
				sudo sh -c "echo '%_unpackaged_files_terminate_build 0' >> /etc/rpm/macros"
			fi
			rpmbuild --define '_topdir /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild' -ba lxc.spec
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc/rpmbuild/RPMS/x86_64
			sudo yum -y localinstall lxc* > /dev/null 2>&1
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/lxc
		fi
		
		LXCVersion=$(GetLXCVersion)	
	done
	
	if [ $Release -eq 7 ]
	then
		echo ''
		echo "=============================================="
		echo "LXC RPMs built on $LF Linux $RL.              "
		echo "=============================================="
	fi

	sleep 5

	clear

	if [ $Release -eq 6 ]
	then
		echo ''
		echo "=============================================="
		echo "LXC RPMs built on $LF Linux $RL.              " 
		echo "=============================================="
	fi

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

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Display Bridge lxcbr0...                      "
	echo "=============================================="
	echo ''

	sleep 5

	sudo ifconfig lxcbr0

	echo ''
	echo "=============================================="
	echo "Done: Display Bridge lxcbr0                   "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo ''
	echo "=============================================="
	echo "Upgrade LXC from Source complete.             "
	echo "=============================================="
	echo ''

	sleep 5

	clear

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

echo ''
echo "=============================================="
echo "Installation required packages...             "
echo "=============================================="
echo ''

sleep 5

cd /home/ubuntu/Downloads/orabuntu-lxc-master

sudo yum -y install curl ruby tar which	
sudo yum -y install wget tar gzip
sudo yum -y install libcap-devel libcgroup 
sudo yum -y install wget bridge-utils
sudo yum -y install graphviz
sudo yum -y install rpm-build wget
sudo yum -y install openssl-devel
sudo yum -y install bind-utils 
sudo yum -y install net-tools wireless-tools
sudo yum -y install openssh-server uuid sshpass
sudo yum -y install rpm ntp iotop
sudo yum -y install iptables gawk yum-utils

echo ''
echo "=============================================="
echo "Package Installation complete                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Run: sudo libtool --finish /usr/lib64         "
echo "=============================================="
echo ''

sudo libtool --finish /usr/lib64

echo ''
echo "=============================================="
echo "Done: sudo libtool --finish /usr/lib64        "
echo "=============================================="

sleep 5

clear

if [ $Operation != new ]
then
	SwitchList='sw1 sx1'
	for k in $SwitchList
	do
		sleep 5

		clear

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

echo ''
echo "=============================================="
echo "Establish sudo privileges...                  "
echo "=============================================="
echo ''

echo $MultiHostVar4 | sudo -S date

echo ''
echo "=============================================="
echo "Privileges established.                       "
echo "=============================================="

sleep 5

clear

which ovs-vsctl > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo ''
	echo "=============================================="
	echo "Build OpenvSwitch from Source...              "
	echo "=============================================="

	sleep 5

	clear

	mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	touch marker-2.rpm

	function GetOVSPackageCount {
		rpm -qa | grep -c openvswitch
	}
	OVSPackageCount=$(GetOVSPackageCount)

	while [ $OVSPackageCount -lt 2 ]
	do
		echo ''
		echo "=============================================="
		echo "Install required packages and prepare...      "
		echo "=============================================="
		echo ''

		sleep 5
		
		if    [ $Release -eq 6 ]
		then
			sudo yum install -y autoconf automake gcc libtool rpm-build
			sudo yum install -y openssl-devel python-devel kernel-uek-debug-devel kernel-devel 
			sudo yum install -y kernel-uek-devel-`uname -r` redhat-rpm-config kabi-whitelists
			sudo rm /lib/modules/`uname -r`/build
			sudo ln -s /usr/src/kernels/`uname -r` /lib/modules/`uname -r`/build
			sudo sed -i -e '/\[public_ol6_software_collections\]/,/^\[/s/enabled=0/enabled=1/' /etc/yum.repos.d/public-yum-ol6.repo
			sudo yum -y install python27
			source /opt/rh/python27/enable
			python -V
			sudo sed -i -e '/\[public_ol6_software_collections\]/,/^\[/s/enabled=1/enabled=0/' /etc/yum.repos.d/public-yum-ol6.repo
			sleep 5
			wget --timeout=3 --tries=3 http://openvswitch.org/releases/openvswitch-"$OvsVersion".tar.gz
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p openvswitch-"$OvsVersion".tar.gz /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/SOURCES/.

		elif [ $Release -eq 7 ]
		then
			sudo yum -y install rpm-build wget openssl-devel gcc make
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch
			wget --timeout=3 --tries=3 http://openvswitch.org/releases/openvswitch-"$OvsVersion".tar.gz
			mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p openvswitch-"$OvsVersion".tar.gz /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/SOURCES/.
		fi

		echo ''
		echo "=============================================="
		echo "Packages and preparations complete.           "
		echo "=============================================="

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Untar source code and build openvswitch rpm..."
		echo "=============================================="
		echo ''

		sleep 5

		if    [ $Release -eq 6 ]
		then
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/SOURCES
			tar -xzvf openvswitch-"$OvsVersion".tar.gz
			cd openvswitch-"$OvsVersion"
			sudo sed -i '/python >= 2\.7/s/python >= 2\.7/python27/g' /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/SOURCES/openvswitch-"$OvsVersion"/rhel/openvswitch.spec
			sleep 5
			sudo sed -i '/python >= 2\.7/s/python >= 2\.7/python27/' openvswitch.spec
			rpmbuild --define '_topdir /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild' -bb rhel/openvswitch.spec
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/RPMS/x86_64
		
			sleep 5

			clear
	
			echo ''
			echo "=============================================="
			echo "Establish sudo privileges...                  "
			echo "=============================================="
			echo ''

			echo $MultiHostVar4 | sudo -S date

			echo ''
			echo "=============================================="
			echo "Privileges established.                       "
			echo "=============================================="

			sleep 5

			clear

			sudo yum -y localinstall openvswitch* > /dev/null 2>&1
			OVSPackageCount=$(GetOVSPackageCount)
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch

		elif [ $Release -eq 7 ]
		then
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/SOURCES
			tar -zxvf openvswitch-"$OvsVersion".tar.gz
			cp -p openvswitch-"$OvsVersion"/rhel/*.spec /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/.
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch
			rpmbuild --define '_topdir /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild' -ba openvswitch.spec
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/RPMS/x86_64

			sleep 5

			clear
	
			echo ''
			echo "=============================================="
			echo "Establish sudo privileges...                  "
			echo "=============================================="
			echo ''

			echo $MultiHostVar4 | sudo -S date

			echo ''
			echo "=============================================="
			echo "Privileges established.                       "
			echo "=============================================="

			sleep 5

			clear

			sudo yum -y localinstall openvswitch* > /dev/null 2>&1
			OVSPackageCount=$(GetOVSPackageCount)
			cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch
		fi
	done

	if [ $OVSPackageCount -ge 2 ]
	then
		echo ''
		echo "=============================================="
		echo "OpenvSwitch RPMs built on $LF Linux $RL       " 
		echo "=============================================="
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install OpenvSwitch RPM...                    "
	echo "=============================================="
	echo ''

	sleep 5

	cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	sudo yum -y localinstall openvswitch*

	echo ''
	echo "=============================================="
	echo "Install OpenvSwitch RPM completed.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Create OpenvSwitch database...                "
	echo "=============================================="
	echo ''

	cd /usr/local/etc
	sudo mkdir openvswitch
	sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db
	if   [ $Release -eq 7 ]
	then
		sudo systemctl start openvswitch.service
	elif [ $Release -eq 6 ]
	then
		sudo service openvswitch start
	fi

	sudo ls -l /usr/local/etc/openvswitch/conf.db

	echo ''
	echo "=============================================="
	echo "OpenvSwitch database created.                 "
	echo "=============================================="
	
	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Test OpenvSwitch...                           "
	echo "=============================================="
	echo ''

	sudo ovs-vsctl show

	echo ''
	echo "=============================================="
	echo "Test OpenvSwitch complete.                    "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Build OpenvSwitch from Source complete.       "
	echo "=============================================="

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Verify required packages status...            "
echo "=============================================="
echo ''

if [ $Release -eq 7 ] || [ $Release -eq 6 ]
then
function CheckPackageInstalled {
echo 'automake bind-utils bridge-utils curl debootstrap docbook docbook2X facter gawk gcc graphviz gzip iotop iptables libcap-devel libcgroup libvirt libvirt-daemon-driver-lxc lxc-2 lxc-debug lxc-devel lxc-libs make net-tools ntp openssh-server openssl-devel openvswitch-2 openvswitch-debug perl rpm rpm-build ruby sshpass tar uuid wget which xmlto yum'
}
fi

PackageInstalled=$(CheckPackageInstalled)

for i in $PackageInstalled
do
sudo rpm -qa | grep $i | tail -1 | sed 's/^/Installed: /' 
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

sudo tar -vP --extract --file=/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/ubuntu-host.tar /etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh --touch
sudo /etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh

echo ''
echo "=============================================="
echo "Key files backups check complete.             "
echo "==============================================" 

sleep 5

clear

sudo lxc-info -n nsa > /dev/null 2>&1
if [ $? -ne 0 ] && [ $Release -eq 6 ]
then
	sudo reboot
fi

function CheckNameServerExists {
	sudo lxc-ls -f | grep -c "$NameServer"
}
NameServerExists=$(CheckNameServerExists)

if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Create LXC DNS DHCP container...              "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Trying Method 1...                            "
        echo "                                              "
        echo "Patience...download of rootfs takes time...   "
        echo "=============================================="
	echo ''

 	sudo lxc-create -t download -n nsa -- --dist ubuntu --release xenial --arch amd64

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
        then
                sudo lxc-update-config -c /var/lib/lxc/nsa/config
        fi

	echo ''
	echo "=============================================="
	echo "Method 1 complete.                            "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Establish sudo privileges...                  "
	echo "=============================================="
	echo ''

	echo $MultiHostVar4 | sudo -S date

	echo ''
	echo "=============================================="
	echo "Privileges established.                       "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Trying Method 2...                            "
	echo "=============================================="
	echo ''

 	sudo lxc-create -n nsa -t ubuntu -- --release xenial --arch amd64

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
        then
                sudo lxc-update-config -c /var/lib/lxc/nsa/config
        fi

	echo ''
	echo "=============================================="
	echo "Create LXC DNS DHCP container complete.       "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Establish sudo privileges...                  "
	echo "=============================================="
	echo ''

	echo $MultiHostVar4 | sudo -S date

	echo ''
	echo "=============================================="
	echo "Privileges established.                       "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install & configure DNS DHCP LXC container... "
	echo "=============================================="

	echo ''
	sudo touch /var/lib/lxc/nsa/rootfs/etc/resolv.conf
	sudo sed -i '0,/.*nameserver.*/s/.*nameserver.*/nameserver 8.8.8.8\n&/' /var/lib/lxc/nsa/rootfs/etc/resolv.conf
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
 	sudo lxc-attach -n nsa -- sudo apt-get -y install bind9 isc-dhcp-server bind9utils dnsutils openssh-server man

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

	echo ''
	echo "=============================================="
	echo "Establish sudo privileges...                  "
	echo "=============================================="
	echo ''

	echo $MultiHostVar4 | sudo -S date

	echo ''
	echo "=============================================="
	echo "Privileges established.                       "
	echo "=============================================="

	sleep 5

	clear

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

# Unpack customized OS host files for Oracle on LXC host server

function CheckNsaExists {
	sudo lxc-ls -f | grep -c nsa
}
NsaExists=$(CheckNsaExists)
FirstRunNsa=$NsaExists

echo ''
echo "=============================================="
echo "Unpack G1 files $LF Linux $RL                 "
echo "=============================================="
echo ''

sudo tar -P -xvf /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/ubuntu-host.tar --touch

echo ''
echo "=============================================="
echo "Done: Unpack G1 files $LF Linux $RL           "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Unpack G2 files for $LF Linux $RL...          "
echo "=============================================="
echo ''

sudo tar -P -xvf /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/dns-dhcp-host.tar --touch
sudo chmod +x /etc/network/openvswitch/crt_ovs_s*.sh

if [ $MultiHostVar2 = 'Y' ]
then
	sudo rm /var/lib/lxc/nsa/config
fi

echo ''
echo "=============================================="
echo "Done: Unpack G2 files for $LF Linux $RL.      "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Creating /etc/sysctl.d/60-oracle.conf file ..."
echo "=============================================="
echo ''
echo "=============================================="
echo "These values are set automatically based on   "
echo "Oracle best practice guidelines.              "
echo "You can adjust them after installation.       "
echo "=============================================="
echo ''

if [ -r /etc/sysctl.d/60-oracle.conf ]
then
sudo cp -p /etc/sysctl.d/60-oracle.conf /etc/sysctl.d/60-oracle.conf.pre.orabuntu-lxc.bak
sudo rm /etc/sysctl.d/60-oracle.conf
fi

sudo touch /etc/sysctl.d/60-oracle.conf
sudo cat /etc/sysctl.d/60-oracle.conf
sudo chmod +x /etc/sysctl.d/60-oracle.conf

echo 'Linux OS Memory Reservation (in Kb) ... '$OSMemRes 
function GetMemTotal {
sudo cat /proc/meminfo | grep MemTotal | cut -f2 -d':' |  sed 's/  *//g' | cut -f1 -d'k'
}
MemTotal=$(GetMemTotal)
echo 'Memory (in Kb) ........................ '$MemTotal

((MemOracleKb = MemTotal - OSMemRes))
echo 'Memory for Oracle (in Kb) ............. '$MemOracleKb

((MemOracleBytes = MemOracleKb * 1024))
echo 'Memory for Oracle (in bytes) .......... '$MemOracleBytes

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

sudo sh -c "echo '# New Stack Settings'                       > /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.ipv4.conf.default.rp_filter=0'         >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.ipv4.conf.all.rp_filter=0'             >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.ipv4.ip_forward=1'                     >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo '# Oracle Settings'                         >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'kernel.shmall = $shmall'                   >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'kernel.shmmax = $shmmax'                   >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'kernel.shmmni = 4096'                      >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'kernel.sem = 250 32000 100 128'            >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'fs.file-max = 6815744'                     >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'fs.aio-max-nr = 1048576'                   >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.ipv4.ip_local_port_range = 9000 65500' >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.core.rmem_default = 262144'            >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.core.rmem_max = 4194304'               >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.core.wmem_default = 262144'            >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'net.core.wmem_max = 1048576'               >> /etc/sysctl.d/60-oracle.conf"
sudo sh -c "echo 'kernel.panic_on_oops = 1'                  >> /etc/sysctl.d/60-oracle.conf"

echo ''
echo "=============================================="
echo "Created /etc/sysctl.d/60-oracle.conf file ... "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Display /etc/sysctl.d/60-oracle.conf          "
echo "=============================================="
echo ''

sudo sysctl -p /etc/sysctl.d/60-oracle.conf

echo ''
echo "=============================================="
echo "Displayed /etc/sysctl.d/60-oracle.conf file.  "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Create 60-oracle.service in systemd...        "
echo "=============================================="
echo ''

if [ ! -f /etc/systemd/system/60-oracle.service ]
then
sudo sh -c "echo '[Unit]'                                    			 > /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'Description=60-oracle Service'            			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'After=network.target'                     			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo ''                                         			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo '[Service]'                                			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'Type=oneshot'                             			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'User=root'                                			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'RemainAfterExit=yes'                      			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'ExecStart=/usr/sbin/sysctl -p /etc/sysctl.d/60-oracle.conf'	>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo ''                                         			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo '[Install]'                                			>> /etc/systemd/system/60-oracle.service"
sudo sh -c "echo 'WantedBy=multi-user.target'               			>> /etc/systemd/system/60-oracle.service"

sudo chmod 644 /etc/systemd/system/60-oracle.service
sudo systemctl enable 60-oracle
fi

sudo cat /etc/systemd/system/60-oracle.service

echo ''
echo "=============================================="
echo "Created 60-oracle.service in systemd.         "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Creating /etc/security/limits.d/70-oracle.conf"
echo "=============================================="
echo ''
echo "=============================================="
echo "These values are set automatically based on   "
echo "Oracle best practice guidelines.              "
echo "You can adjust them after installation.       "
echo "=============================================="
echo ''

sudo touch /etc/security/limits.d/70-oracle.conf
sudo chmod +x /etc/security/limits.d/70-oracle.conf

# Oracle Kernel Parameters

sudo sh -c "echo '#                                        '  > /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo '# Oracle DB Parameters                   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo '#                                        ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'oracle	soft	nproc       2047   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'oracle	hard	nproc      16384   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'oracle	soft	nofile      1024   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'oracle	hard	nofile     65536   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'oracle	soft	stack      10240   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'oracle	hard	stack      10240   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo '* 	soft 	memlock  9873408           ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo '* 	hard 	memlock  9873408           ' >> /etc/security/limits.d/70-oracle.conf"

# Oracle Grid Infrastructure Kernel Parameters
	
sudo sh -c "echo '#                                        ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo '# Oracle GI Parameters                   ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo '#                                        ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'grid	soft	nproc       2047           ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'grid	hard	nproc      16384           ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'grid	soft	nofile      1024           ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'grid	hard	nofile     65536           ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'grid	soft	stack      10240           ' >> /etc/security/limits.d/70-oracle.conf"
sudo sh -c "echo 'grid	hard	stack      10240           ' >> /etc/security/limits.d/70-oracle.conf"

echo "=============================================="
echo "Display /etc/security/limits.d/70-oracle.conf "
echo "=============================================="
echo ''
sudo cat /etc/security/limits.d/70-oracle.conf
echo ''
echo "=============================================="
echo "Created /etc/security/limits.d/70-oracle.conf "
echo "Sleeping 10 seconds for settings review ...   "
echo "=============================================="
echo ''

sleep 10

clear

if [ $NameServerExists -eq 0  ]
then
	if [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Unpacking LXC nameserver custom files...      "
		echo "=============================================="
		echo ''
	
		sudo tar -P -xvf /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/dns-dhcp-cont.tar --touch

		echo ''
		echo "=============================================="
		echo "Custom files unpack complete                  "
		echo "=============================================="
	fi

	sleep 10

	clear

	echo ''
	echo "=============================================="
	echo "Customize nameserver & domains ...            "
	echo "=============================================="
	echo ''

	function GetHostName {
		echo $HOSTNAME | cut -f1 -d'.'
	}
	HostName=$(GetHostName)

	if [ -n $Domain1 ] && [ $MultiHostVar2 = 'Y' ]
	then
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/network/openvswitch/crt_ovs_sw1.sh
	fi
		
	if [ -n $Domain2 ] && [ $MultiHostVar2 = 'Y' ]
	then
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/network/openvswitch/crt_ovs_sw1.sh
	fi

	if [ $MultiHostVar2 = 'N' ]
	then
		# Remove the extra nameserver line used for DNS DHCP setup and add the required nameservers.
	
		sudo sed -i '/8.8.8.8/d' /var/lib/lxc/nsa/rootfs/etc/resolv.conf
		sudo sed -i '/nameserver/c\nameserver 10.207.39.2' /var/lib/lxc/nsa/rootfs/etc/resolv.conf
		sudo sh -c "echo 'nameserver 10.207.29.2' >> /var/lib/lxc/nsa/rootfs/etc/resolv.conf"
		sudo sh -c "echo 'search orabuntu-lxc.com consultingcommandos.us' >> /var/lib/lxc/nsa/rootfs/etc/resolv.conf"

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
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.consultingcommandos.us
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/config
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/etc/hostname
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/etc/hosts
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /etc/network/openvswitch/strt_nsa.sh
			sudo mv /var/lib/lxc/nsa /var/lib/lxc/$NameServer
			sudo mv /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1 /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1
			sudo mv /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1 /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1
			sudo mv /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1 /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1
			sudo mv /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1 /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1
			sudo mv /etc/network/openvswitch/strt_nsa.sh /etc/network/openvswitch/strt_$NameServer.sh
		fi

		if [ -n $Domain1 ]
		then
			# GLS 20151221 Settable Domain feature added
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/NetworkManager/dnsmasq.d/local
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain1
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain1
		fi

		if [ -n $Domain2 ]
		then
			# GLS 20151221 Settable Domain feature added
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/NetworkManager/dnsmasq.d/local
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain2
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain2
		fi
	fi

	# Cleanup duplicate search lines in /etc/resolv.conf if Orabuntu-LXC has been re-run
	sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/resolv.conf

	sudo cat /etc/resolv.conf

	sleep 5

	echo ''
	echo "=============================================="
	echo "Customize nameserver & domains complete.      "
	echo "=============================================="
fi

sleep 5

clear

sudo chmod 755 /etc/network/openvswitch/*.sh

if   [ $Release -eq 7 ]
then

	function GetMultiHostVar3 {
		echo $MultiHost | cut -f3 -d':'
	}
	MultiHostVar3=$(GetMultiHostVar3)

	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sx1.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw1.sh

	SwitchList='sw1 sx1'
	for k in $SwitchList
	do
		echo ''
		echo "=============================================="
		echo "Installing OpenvSwitch $k...                  "
		echo "=============================================="
		echo ''

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
                	sudo sh -c "echo 'Wants=network-online.target'				>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'After=network-online.target sw1.service'		>> /etc/systemd/system/$k.service"
		fi
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'Type=oneshot'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/crt_ovs_$k.sh' 	>> /etc/systemd/system/$k.service"
			sudo sh -c "echo 'ExecStop=/usr/bin/ovs-vsctl del-br $k'                >> /etc/systemd/system/$k.service"
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'WantedBy=multi-user.target'				>> /etc/systemd/system/$k.service"

			echo ''
			echo "=============================================="
			echo "Starting OpenvSwitch $k ...                   "
			echo "=============================================="
			echo ''
	
       			sudo chmod 644 /etc/systemd/system/$k.service
			sudo systemctl daemon-reload
       			sudo systemctl enable $k.service
			sudo service $k start
			sudo service $k status

			echo ''
			echo "=============================================="
			echo "Started OpenvSwitch $k.                       "
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
elif [ $Release -eq 6 ]
then
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

if [ $OnVm1 = 'N' ] && [ $OnVm2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Activating NetworkManager dnsmasq service ... "
	echo "=============================================="
	echo ''

	# So that settings in /etc/NetworkManager/dnsmasq.d/local & /etc/NetworkManager/NetworkManager.conf take effect.

	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g"			/etc/resolv.conf
	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g"	/etc/resolv.conf
	sudo cat /etc/resolv.conf
	sudo sed -i '/plugins=ifcfg-rh/a dns=dnsmasq' /etc/NetworkManager/NetworkManager.conf
	echo ''

	sudo service NetworkManager restart

	function CheckResolvReady {
		sudo cat /etc/resolv.conf | grep -c 'nameserver 127\.0\.0\.1'
	}
	ResolvReady=$(CheckResolvReady)
	echo ''
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
		sudo service sw1 restart
	else
		echo ''
		echo "=============================================="
		echo "NetworkManager didn't set nameserver 127.0.0.1"
		echo "which is the setting required for NM dnsmasq. "
		echo "=============================================="
	fi

	# sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1' >> /etc/resolv.conf"
	sudo cat /etc/resolv.conf
	echo ''

	echo "=============================================="
	echo "NetworkManager dnsmasq activated.             "
	echo "=============================================="
fi

sleep 5

clear

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
	sudo sed -i "/secret/c\key rndc-key { algorithm hmac-md5; $KeySecret }" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
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
		sudo sh -c "echo 'Type=oneshot'                     				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'User=root'                        				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'RemainAfterExit=yes'              				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_$NameServer.sh start'	>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/strt_$NameServer.sh stop'	>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo ''                                 				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo '[Install]'                        				>> /etc/systemd/system/$NameServer.service"
		sudo sh -c "echo 'WantedBy=multi-user.target'       				>> /etc/systemd/system/$NameServer.service"
		sudo chmod 644 /etc/systemd/system/$NameServer.service
		sudo systemctl enable $NameServer

		echo ''
		echo "=============================================="
		echo "Created $NameServer Onboot Service.           "
		echo "=============================================="
	fi
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Checking OpenvSwitch sw1...                   "
echo "=============================================="
echo ''

sudo service sw1 stop
sleep 2
sudo systemctl start sw1
sleep 2
echo ''
ifconfig sw1
echo ''
sudo service sw1 status

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
echo ''

sudo service sx1 stop
sleep 2
sudo systemctl start sx1
sleep 2
echo ''
ifconfig sx1
echo ''
sudo service sx1 status

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

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ] && [ $MultiHostVar2 = 'N' ]
then
        sudo lxc-update-config -c /var/lib/lxc/$NameServer/config
fi

if [ $MultiHostVar2 = 'N' ] && [ $OnVm1 = 'N' ] && [ $OnVm2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Starting LXC container and testing DNS...     "
	echo "=============================================="
	echo ''

	if [ -n $NameServer ]
	then
		sudo service sw1 restart > /dev/null 2>&1
		sudo service sx1 restart > /dev/null 2>&1
		sudo lxc-stop -n $NameServer  > /dev/null 2>&1
		sudo lxc-start -n $NameServer > /dev/null 2>&1
		nslookup $NameServer
		if [ $? -ne 0 ]
		then
			echo "DNS is NOT RUNNING with correct status!"
		fi
	else
		sudo lxc-start -n nsa > /dev/null 2>&1
		nslookup nsa
		if [ $? -ne 0 ]
		then
			echo "DNS is NOT RUNNING with correct status!"
		fi
	fi

	echo "=============================================="
	echo "LXC container restarted & DNS tested.         "
	echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Checking and Configuring MultiHost Settings..."
echo "=============================================="
echo ''

if [ $MultiHostVar2 = 'N' ]
then
	function GetMultiHostVar3 {
		echo $MultiHost | cut -f3 -d':'
	}
	MultiHostVar3=$(GetMultiHostVar3)

#	GLS 20170904 Switches sx1 and sw1 are set earlier so they are not set here.

	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw2.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw3.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw4.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw5.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw6.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw7.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw8.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw9.sh

	echo ''
	echo "=============================================="
	echo "Unpack SCST Linux SAN Files...                "
	echo "=============================================="
	echo ''

	sudo tar -P -xvf /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files.tar --touch -C /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives
	sleep 2
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files/create-scst-oracle.sh
		
	echo ''
	echo "=============================================="
	echo "Done: Unpack SCST Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Setting ubuntu user password in $NameServer..."
	echo "=============================================="
	echo ''

	sudo touch /home/ubuntu/.ssh/known_hosts
	sudo lxc-attach -n $NameServer -- usermod --password `perl -e "print crypt('ubuntu','ubuntu');"` ubuntu
	ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 10.207.39.2
#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"
	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "date; uname -a"
	
	echo ''
	echo "=============================================="
	echo "Done: Set ubuntu password in $NameServer.     "
	echo "=============================================="

fi

if [ $MultiHostVar2 = 'Y' ]
then
	function GetMultiHostVar2 {
		echo $MultiHost | cut -f2 -d':'
	}
	MultiHostVar2=$(GetMultiHostVar2)

	function GetMultiHostVar3 {
		echo $MultiHost | cut -f3 -d':'
	}
	MultiHostVar3=$(GetMultiHostVar3)

#	GLS 20170904 Switches sx1 and sw1 are set earlier (around lines 1988,1989) so they are not set here.

	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw2.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw3.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw4.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw5.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw6.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw7.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw8.sh
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /etc/network/openvswitch/crt_ovs_sw9.sh
	
	echo ''
	echo "=============================================="
	echo "Unpack SCST Linux SAN Files...                "
	echo "=============================================="
	echo ''

	sudo tar -P -xvf /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files.tar -C /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives	
	sudo sed -i "s/SWITCH_IP/$MultiHostVar3/g" /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files/create-scst-oracle.sh
		
	echo ''
	echo "=============================================="
	echo "Done: Unpack SCST Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

#	sudo route add -net 192.220.39.0/24 gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1
#	sudo route add -net 192.221.39.0/24 gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1
# 	sudo route add -net 192.222.39.0/24 gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1
#  	sudo route add -net 192.223.39.0/24 gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1
#  	sudo route add -net 172.230.40.0/24 gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1
#  	sudo route add -net 172.231.40.0/24 gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1
#   	sudo route add -net 10.207.39.0/24  gw 10.207.39.$MultiHostVar3 dev sw1 >/dev/null 2>&1

	function GetMultiHostVar5 {
	echo $MultiHost | cut -f5 -d':'
	}
	MultiHostVar5=$(GetMultiHostVar5)

	function GetMultiHostVar6 {
	echo $MultiHost | cut -f6 -d':'
	}
	MultiHostVar6=$(GetMultiHostVar6)

	if [ $GRE = 'Y' ]
	then
		sudo sed -i "/route add -net/s/#/ /"				/etc/network/openvswitch/crt_ovs_sw1.sh	
		sudo sed -i "/REMOTE_GRE_ENDPOINT/s/#/ /"			/etc/network/openvswitch/crt_ovs_sw1.sh	
		sudo sed -i "s/REMOTE_GRE_ENDPOINT/$MultiHostVar5/g"		/etc/network/openvswitch/crt_ovs_sw1.sh

		function CheckGre0Exists {
			sudo ovs-vsctl show | grep gre0 | wc -l
		}
		Gre0Exists=$(CheckGre0Exists)

		if [ $Gre0Exists -gt 0 ]
		then
			sudo ovs-vsctl del-port gre0
		fi

		function CheckGre1Exists {
			sudo ovs-vsctl show | grep gre1 | wc -l
		}
		Gre1Exists=$(CheckGre1Exists)

		if [ $Gre1Exists -gt 0 ]
		then
			sudo ovs-vsctl del-port gre1
		fi

		sudo ovs-vsctl add-port sw1 gre0 -- set interface gre0 type=gre options:remote_ip=$MultiHostVar5

 		sudo sed -i "s/MultiHostVar6/$MultiHostVar6/g" 	/etc/network/openvswitch/setup_gre_and_routes.sh
#		sudo sed -i "s/MultiHostVar3/$MultiHostVar3/g" 	/etc/network/openvswitch/setup_gre_and_routes.sh
#		sudo sed -i "s/MHV3/MultiHostVar3/g"		/etc/network/openvswitch/setup_gre_and_routes.sh
#		sudo sed -i "s/MHV6/MultiHostVar6/g"		/etc/network/openvswitch/setup_gre_and_routes.sh

		sudo chmod 775 /etc/network/openvswitch/setup_gre_and_routes.sh

		echo ''
		echo "=============================================="
		echo "Setup GRE & Routes on $MultiHostVar5...       "
		echo "=============================================="
		echo ''
	
		sudo service sw1 restart
		sudo service sx1 restart

		sudo chmod 777 /etc/network/openvswitch/setup_gre_and_routes.sh

		sudo touch /home/ubuntu/.ssh/known_hosts
		ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $MultiHostVar5
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 date
		if [ $? -eq 0 ]
		then
			sshpass -p ubuntu scp -p /etc/network/openvswitch/setup_gre_and_routes.sh ubuntu@$MultiHostVar5:~/.
		fi
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" ls -l ~/setup_gre_and_routes.sh"
		if [ $? -eq 0 ]
		then
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" ~/setup_gre_and_routes.sh"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" service sw1 restart"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" /etc/orabuntu-lxc-scripts/stop_containers.sh"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" /etc/orabuntu-lxc-scripts/start_containers.sh"
		fi

		function GetShortHost {
			uname -n | cut -f1 -d'.'
		}
		ShortHost=$(GetShortHost)

		function CheckHostnameLookup {
			nslookup -timeout=2 $HOSTNAME.$Domain1 | grep Address | grep -v '#' | wc -l
		}
		HostnameLookup=$(CheckHostnameLookup)

		if [ $HostnameLookup -eq 0 ]
		then		
			echo ''
			echo "=============================================="
			echo "Create ADD DNS $Domain1 $ShortHost...         "
			echo "=============================================="
			echo ''

			sudo sh -c "echo 'echo \"server 10.207.39.2'								    	>  /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"
			sudo sh -c "echo 'update add $ShortHost.orabuntu-lxc.com 3600 IN A 10.207.39.$MultiHostVar3'		    	>> /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"
			sudo sh -c "echo 'update add $MultiHostVar3.39.207.10.in-addr.arpa 3600 IN PTR $ShortHost.orabuntu-lxc.com' 	>> /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"
			sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"
			sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_add_$ShortHost.sh"

			sudo chmod 777 					/etc/network/openvswitch/nsupdate_add_$ShortHost.sh
			sudo ls -l     					/etc/network/openvswitch/nsupdate_add_$ShortHost.sh
			sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"	/etc/network/openvswitch/nsupdate_add_$ShortHost.sh
			sudo cat					/etc/network/openvswitch/nsupdate_add_$ShortHost.sh
	
			sudo service sw1 restart
			sudo service sx1 restart

			sudo touch /home/ubuntu/.ssh/known_hosts
			ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 10.207.39.2
			sudo ifconfig sw1 mtu $MultiHostVar7
			sudo ifconfig sx1 mtu $MultiHostVar7
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar6 "sudo -S <<< "ubuntu" ifconfig sw1 mtu $MultiHostVar7"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar6 "sudo -S <<< "ubuntu" ifconfig sx1 mtu $MultiHostVar7"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
			sshpass -p ubuntu scp -p /etc/network/openvswitch/nsupdate_add_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
			echo "apparently this one has problem..."
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_add_$ShortHost.sh"
		fi
		
		if [ $OnVm1 = 'N' ] && [ $OnVm2 = 'N' ]
		then
			sudo sh -c "echo 'sudo ifconfig sw1 mtu $MultiHostVar7'		>  /etc/network/openvswitch/set_mtu.sh"
			sudo sh -c "echo 'sudo ifconfig sx1 mtu $MultiHostVar7'	    	>> /etc/network/openvswitch/set_mtu.sh"
			sudo sh -c "echo 'sudo ifconfig olivex mtu $MultiHostVar7'    	>> /etc/network/openvswitch/set_mtu.sh"
			sudo sh -c "echo 'sudo ifconfig olivew mtu $MultiHostVar7'    	>> /etc/network/openvswitch/set_mtu.sh"
			sudo chmod 777 /etc/network/openvswitch/set_mtu.sh
			sshpass -p ubuntu scp -p /etc/network/openvswitch/set_mtu.sh ubuntu@$MultiHostVar5:~/.
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ifconfig eth0 mtu $MultiHostVar7"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ifconfig eth1 mtu $MultiHostVar7"
			sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" ~/set_mtu.sh"
		fi
	fi
fi

# GLS 20161118 This section for any tweaks to the unpacked files from archives.
sudo rm /etc/network/if-up.d/orabuntu-lxc-net

echo ''
echo "=============================================="
echo "MultiHost Settings Completed.                 "
echo "=============================================="

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
echo "Verify existence of Oracle and Grid users...  "
echo "=============================================="
echo ''

sudo useradd -u 1098 grid 		>/dev/null 2>&1
sudo useradd -u 500 oracle 		>/dev/null 2>&1
sudo groupadd -g 1100 asmadmin		>/dev/null 2>&1
sudo usermod -a -G asmadmin grid	>/dev/null 2>&1

id grid
id oracle

echo ''
echo "=============================================="
echo "Existence of Oracle and Grid users verified.  "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Create RSA key if it does not already exist   "
echo "=============================================="
echo ''

if [ ! -e ~/.ssh/id_rsa.pub ]
then
# ssh-keygen -t rsa
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

if [ -e ~/.ssh/authorized_keys ]
then
rm ~/.ssh/authorized_keys
fi

touch ~/.ssh/authorized_keys

if [ -e ~/.ssh/id_rsa.pub ]
then
function GetAuthorizedKey {
cat ~/.ssh/id_rsa.pub
}
AuthorizedKey=$(GetAuthorizedKey)

echo 'Authorized Key:'
echo ''
echo $AuthorizedKey 
echo ''
fi

function CheckAuthorizedKeys {
grep -c "$AuthorizedKey" ~/.ssh/authorized_keys
}
AuthorizedKeys=$(CheckAuthorizedKeys)

echo "Results of grep = $AuthorizedKeys"

if [ "$AuthorizedKeys" -eq 0 ]
then
cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

echo ''
echo 'cat of authorized_keys'
echo ''
cat ~/.ssh/authorized_keys

echo ''
echo "=============================================="
echo "Create RSA key completed                      "
echo "=============================================="

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
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.options .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
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

if [ -n $NameServer ] && [ ! -n $Domain1 ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ ! -n $Domain2 ] && [ $MultiHostVar2 = 'N' ]
then
        sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us .' >> /etc/orabuntu-lxc-scripts/crt_links.sh"
        sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us .' >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

sudo sh -c "echo ' ln -sf /etc/sysctl.d/60-oracle.conf .' 			         		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/security/limits.d/70-oracle.conf .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/interfaces .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/NetworkManager/dnsmasq.d/local .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
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
echo "Set SELINUX to permissive...                  "
echo "=============================================="
echo ''

sudo setenforce permissive
sudo sed -i '/SELINUX=enforcing/s/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: uekulele-services-2.sh    "
echo "=============================================="

