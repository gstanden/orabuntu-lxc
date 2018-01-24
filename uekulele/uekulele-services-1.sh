#!/bin/bash

#    Copyright 2015-2018 Gilbert Standen
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
#    along with Orabuntu-LXC.  If not, see <http://www.gnu.org/licenses/>.

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

clear

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
DistDir=$9

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

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

function CheckSystemdResolvedInstalled {
        sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

function CheckLxcNetRunning {
	sudo systemctl | grep lxc-net | grep 'loaded active exited' | wc -l
}
LxcNetRunning=$(CheckLxcNetRunning)

function CheckNetworkManagerRunning {
	ps -ef | grep NetworkManager | grep -v grep | wc -l
}
NetworkManagerRunning=$(CheckNetworkManagerRunning)

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
        CutIndex=7
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                CutIndex=7
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                CutIndex=4
        fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        if [ $RedHatVersion -ge 19 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Ubuntu' ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
        LF=$LinuxFlavor
        RL=$UbuntuVersion
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

function GetOperation {
echo $MultiHost | cut -f1 -d':'
}
Operation=$(GetOperation)

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

echo ''
echo "=============================================="
echo "Done: edit sshd_config.                       "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Restart sshd...                               "
echo "=============================================="
echo ''

sudo service sshd restart

echo ''
echo "=============================================="
echo "Done: Restart sshd.                           "
echo "=============================================="

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
		sudo rm -f /etc/network/openvswitch/strt_ora*c*.sh
		sudo rm -f /etc/network/if-up.d/openvswitch/*
		sudo rm -f /etc/network/if-down.d/openvswitch/*
		cd /opt/olxc/"$DistDir"/uekulele
		sudo rm -rf facter openvswitch lxc selinux
		if [ $LinuxFlavor != 'Fedora' ]
		then
			sudo rm -rf epel
		fi
		sudo rm -f /etc/orabuntu-lxc-release

		# GLS 20170925 Oracle Linux OVS and LXC are built from source.    This step deletes the source build directories.
		# GLS 20170925 Ubuntu Linux OVS and LXC are build from packages.  This step is not necessary on Ubuntu Linux.

		echo "=============================================="
		echo "Remove dns=none parameter from NM conf...     "
		echo "=============================================="

		sudo sed -i '/dns=none/d' /etc/NetworkManager/NetworkManager.conf
		sudo systemctl daemon-reload

		echo ''
		echo "=============================================="
		echo "Done Remove dns=none parameter from NM conf.  "
		echo "=============================================="
		echo ''

		echo "=============================================="
		echo "Uninstall lxc packages...                     "
		echo "=============================================="
		echo ''

		sudo systemctl disable dnsmasq
		sudo yum -y erase lxc lxc-libs dnsmasq
		sudo rm -f /etc/sysconfig/lxc-net	> /dev/null 2>&1
		sudo rm -f /etc/dnsmasq.conf		> /dev/null 2>&1

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

	if [ -f /etc/dnsmasq.conf ]
	then
		sudo mv /etc/dnsmasq.conf /etc/dnsmasq.olxc.1
	fi
	sudo yum clean all

	sudo yum -y install wget tar gzip libtool

        DocBook2X=0
        DocBook2XInstalled=0
        m=1
        while [ $DocBook2X -eq 0 ] || [ $DocBook2XInstalled -eq 0 ] && [ $m -le 5 ]
        do
                if [ $LinuxFlavor != 'Fedora' ]
                then
                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel
                        if   [ $Release -eq 7 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                                sudo rpm -ivh epel-release-latest-7.noarch.rpm
                        elif [ $Release -eq 6 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
                                sudo rpm -ivh epel-release-latest-6.noarch.rpm
                        fi
                        sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
                        sudo yum -y install docbook2X
                fi

                function VerifyDocBook2X {
                        yum provides docbook2X | grep -c docbook2X
                }
                DocBook2X=$(VerifyDocBook2X)

                function CheckDocBook2XInstalled {
                        rpm -qa | grep -c docbook2X
                }
                DocBook2XInstalled=$(CheckDocBook2XInstalled)

                if [ $DocBook2X -gt 0 ] && [ $DocBook2XInstalled -gt 0 ]
                then
                        echo ''
                        echo "=============================================="
                        echo 'epel configuration and installs successful.   '
                        echo "=============================================="
                        echo ''
                elif [ $DocBook2X -eq 0 ] || [ $DocBook2XInstalled -eq 0 ]
                then
                        echo ''
                        echo "=============================================="
                        echo 'epel failure ... retrying epel configuration. '
                        echo "=============================================="
                        echo ''
                fi
                m=$((m+1))
        done

	cd /opt/olxc/"$DistDir"

	sudo yum -y install debootstrap perl bash-completion bash-completion-extras dnsmasq libvirt
	sudo yum -y install lxc libcap-devel libcgroup wget bridge-utils lsb

	if [ $LinuxFlavor = 'Fedora' ]
	then
		sudo yum -y install lxc-templates lxc-extra libvirt gpg
	fi

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
		sudo systemctl daemon-reload
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

	if [ -f /etc/dnsmasq.conf ]
	then
		sudo mv /etc/dnsmasq.conf /etc/dnsmasq.olxc.1
	fi
	sudo yum -y install wget tar gzip libtool

        DocBook2X=0
        DocBook2XInstalled=0
        m=1

        while [ $DocBook2X -eq 0 ] || [ $DocBook2XInstalled -eq 0 ] && [ $m -le 5 ]
        do
                if [ $LinuxFlavor != 'Fedora' ]
                then
                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel
                        if   [ $Release -eq 7 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                                sudo rpm -ivh epel-release-latest-7.noarch.rpm
                        elif [ $Release -eq 6 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
                                sudo rpm -ivh epel-release-latest-6.noarch.rpm
                        fi
                        sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
                        sudo yum -y install docbook2X
                fi

                function VerifyDocBook2X {
                        yum provides docbook2X | grep -c docbook2X
                }
                DocBook2X=$(VerifyDocBook2X)

                function CheckDocBook2XInstalled {
                        rpm -qa | grep -c docbook2X
                }
                DocBook2XInstalled=$(CheckDocBook2XInstalled)

                if [ $DocBook2X -gt 0 ] && [ $DocBook2XInstalled -gt 0 ]
                then
                        echo ''
                        echo "=============================================="
                        echo 'epel configuration and installs successful.   '
                        echo "=============================================="
                        echo ''
                        sleep 1
                elif [ $DocBook2X -eq 0 ] || [ $DocBook2XInstalled -eq 0 ]
                then
                        echo ''
                        echo "=============================================="
                        echo 'epel failure ... retrying epel configuration. '
                        echo "=============================================="
                        echo ''
                        sleep 1
                fi
                m=$((m+1))
        done

	cd /opt/olxc/"$DistDir"

	sudo yum -y install debootstrap perl bash-completion bash-completion-extras dnsmasq libvirt
	sudo yum -y install lxc libcap-devel libcgroup wget bridge-utils lsb

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
		sudo systemctl daemon-reload
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
			sudo yum -y install rpm-build wget openssl-devel gcc make docbook2X xmlto automake graphviz libtool
			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc
			sudo chown -R $Owner:$Group /opt/olxc
			cd /opt/olxc/"$DistDir"/uekulele/lxc
			
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
	
			ping -c 10 linuxcontainers.org
			echo ''
			nslookup linuxcontainers.org
			echo ''
			wget --timeout=5 --tries=10 https://linuxcontainers.org/downloads/lxc/lxc-"$LxcVersion".tar.gz
			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			sudo chown -R $Owner:$Group /opt/olxc/
			cp -p lxc-"$LxcVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/SOURCES/.
			tar -zxvf lxc-"$LxcVersion".tar.gz
			cp -p lxc-"$LxcVersion"/lxc.spec /opt/olxc/"$DistDir"/uekulele/lxc/.
			sudo sed -i '/bash_completion/d' /opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			cd /opt/olxc/"$DistDir"/uekulele/lxc

			function CheckMacrosFile {
				cat /etc/rpm/macros | grep _unpackaged_files_terminate_build | sort -u | grep -c 0
			}
			MacrosFile=$(CheckMacrosFile)

			if [ $MacrosFile -eq 0 ]
			then
				sudo sh -c "echo '%_unpackaged_files_terminate_build 0' >> /etc/rpm/macros"
			fi
			rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild" -ba lxc.spec
			
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

			cd /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/RPMS/x86_64
			if [ $LinuxFlavor = 'CentOS' ]
			then
				sudo yum -y erase lxc-libs
			fi
			sleep 5
			sudo yum -y localinstall *.rpm
			cd /opt/olxc/"$DistDir"/uekulele/lxc

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
			sudo yum -y install rpm-build wget openssl-devel gcc make docbook2X xmlto automake graphviz
			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc
			sudo chown -R $Owner:$Group /opt/olxc
			cd /opt/olxc/"$DistDir"/uekulele/lxc
			wget --timeout=5 --tries=10 https://linuxcontainers.org/downloads/lxc/lxc-"$LxcVersion".tar.gz
			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			sudo chown -R $Owner:$Group /opt/olxc
			cp -p lxc-"$LxcVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/SOURCES/.
			tar -zxvf lxc-"$LxcVersion".tar.gz
			cp -p lxc-"$LxcVersion"/lxc.spec /opt/olxc/"$DistDir"/uekulele/lxc/.
			sudo sed -i '/bash_completion/d' /opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			cd /opt/olxc/"$DistDir"/uekulele/lxc

			function CheckMacrosFile {
				cat /etc/rpm/macros | grep _unpackaged_files_terminate_build | sort -u | grep -c 0
			}
			MacrosFile=$(CheckMacrosFile)

			if [ $MacrosFile -eq 0 ]
			then
				sudo sh -c "echo '%_unpackaged_files_terminate_build 0' >> /etc/rpm/macros"
			fi
			rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild" -ba lxc.spec
			cd /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/RPMS/x86_64
			sudo yum -y localinstall lxc* > /dev/null 2>&1
			cd /opt/olxc/"$DistDir"/uekulele/lxc
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
	echo "Display Bridge for LXC ...                    "
	echo "=============================================="
	echo ''

	sleep 5

	if [ $LinuxFlavor != 'CentOS' ]
	then
		sudo ifconfig lxcbr0
	else
		sudo ifconfig virbr0
		if [ $? -eq 0 ]
		then
			sudo sed -i "s/lxcbr0/virbr0/g" /etc/lxc/default.conf
		fi
	fi

	echo "=============================================="
	echo "Done: Display Bridge for LXC                  "
	echo "=============================================="

	sleep 5

	clear

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

cd /opt/olxc/"$DistDir"

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

if [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Fedora' ]
then
	sudo yum -y install lsb
fi

echo ''
echo "=============================================="
echo "Package Installation complete                 "
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

	mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
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
			sudo yum -y install autoconf automake gcc libtool rpm-build
			sudo yum -y install openssl-devel python-devel kernel-uek-debug-devel kernel-devel 
			sudo yum -y install kernel-uek-devel-`uname -r` redhat-rpm-config kabi-whitelists
			sudo rm /lib/modules/`uname -r`/build
			sudo ln -s /usr/src/kernels/`uname -r` /lib/modules/`uname -r`/build
			sudo sed -i -e '/\[public_ol6_software_collections\]/,/^\[/s/enabled=0/enabled=1/' /etc/yum.repos.d/public-yum-ol6.repo
			sudo yum -y install python27
			source /opt/rh/python27/enable
			python -V
			sudo sed -i -e '/\[public_ol6_software_collections\]/,/^\[/s/enabled=1/enabled=0/' /etc/yum.repos.d/public-yum-ol6.repo
			sleep 5
			wget --timeout=5 --tries=10 http://openvswitch.org/releases/openvswitch-"$OvsVersion".tar.gz
			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p openvswitch-"$OvsVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES/.

		elif [ $Release -eq 7 ]
		then
			sudo yum -y install rpm-build wget openssl-devel gcc make
			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			wget --timeout=5 --tries=10 http://openvswitch.org/releases/openvswitch-"$OvsVersion".tar.gz
			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p openvswitch-"$OvsVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES/.
		fi

		echo ''
		echo "=============================================="
		echo "Packages and preparations complete.           "
		echo "=============================================="

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Untar source code and build openvswitch RPM..."
		echo "=============================================="
		echo ''

		sleep 5

		if    [ $Release -eq 6 ]
		then
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES
			tar -xzvf openvswitch-"$OvsVersion".tar.gz
			cd openvswitch-"$OvsVersion"
			sudo sed -i '/python >= 2\.7/s/python >= 2\.7/python27/g' /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES/openvswitch-"$OvsVersion"/rhel/openvswitch.spec
			sleep 5
			sudo sed -i '/python >= 2\.7/s/python >= 2\.7/python27/' openvswitch.spec
			rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild" -bb rhel/openvswitch.spec
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
		
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
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch

		elif [ $Release -eq 7 ]
		then
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES
			tar -zxvf openvswitch-"$OvsVersion".tar.gz
			cp -p openvswitch-"$OvsVersion"/rhel/*.spec /opt/olxc/"$DistDir"/uekulele/openvswitch/.
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild" -ba openvswitch.spec
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64

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
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
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
	echo "Install OpenvSwitch RPMs...                   "
	echo "=============================================="
	echo ''

	sleep 5

	cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
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
	if [ $LinuxFlavor != 'Fedora' ]
	then
		function CheckPackageInstalled {
			echo 'automake bind-utils bridge-utils curl debootstrap docbook docbook2X facter gawk gcc graphviz gzip iotop iptables libcap-devel libcgroup lsb-core lxc lxc-2 lxc-debug lxc-devel lxc-libs make net-tools ntp openssh-server openssl-devel openvswitch-2 openvswitch-debug perl rpm rpm-build ruby sshpass tar uuid wget which xmlto yum-utils'
		}
	else
		function CheckPackageInstalled {
			echo 'automake bind-utils bridge-utils curl debootstrap docbook docbook2X facter gawk gcc graphviz gzip iotop iptables libcap-devel libcgroup lsb-core lxc lxc-2 lxc-debug lxc-devel lxc-libs make net-tools ntp openssh-server openssl-devel openvswitch-2 openvswitch-debug perl rpm rpm-build ruby sshpass tar uuid wget which xmlto yum-utils'
		}
	fi
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

sudo tar -v --extract --file=/opt/olxc/"$DistDir"/uekulele/archives/ubuntu-host.tar -C / etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh --touch
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

if   [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'N' ]
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
 	sudo lxc-attach -n nsa -- sudo apt-get -y install bind9 isc-dhcp-server bind9utils dnsutils openssh-server man awscli sshpass

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

if [ -f /etc/dnsmasq.conf ]
then
	sudo cp -p /etc/dnsmasq.conf /etc/dnsmasq.conf.olxc.2
	sudo rm -f /etc/dnsmasq.conf
fi
sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/ubuntu-host.tar -C / --touch

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

sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-host.tar -C / --touch
sudo chmod +x /etc/network/openvswitch/crt_ovs_s*.sh

if [ $MultiHostVar2 = 'Y' ] && [ -f /var/lib/lxc/nsa/config ]
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
	
		sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-cont.tar -C / --touch
#		sudo sed -i '/nameserver/d' /etc/resolv.conf

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
                        sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/root/crontab.txt
                        sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/root/ns_backup_update.lst
                        sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/root/ns_backup_update.sh
                        sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/root/ns_backup.start.sh
                        sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/root/dns-sync.sh

			sudo sed -i "/nsa/s/nsa/$NameServer/g" /etc/network/openvswitch/strt_nsa.sh
			sudo mv /var/lib/lxc/nsa /var/lib/lxc/$NameServer
			sudo mv /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1 /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1
			sudo mv /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1 /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1
			sudo mv /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1 /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1
			sudo mv /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1 /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1
			sudo mv /etc/network/openvswitch/strt_nsa.sh /etc/network/openvswitch/strt_$NameServer.sh
                        echo "/var/lib/lxc/$NameServer"                                          > /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1"        >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1"    >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1"        >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1"    >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
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
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.lst
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
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.lst
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

if   [ $MultiHostVar3 = 'X' ] && [ $GRE = 'Y' ] && [ $MultiHostVar2 = 'Y' ]
then
#	echo ''
#	echo "=============================================="
#	echo "Get sx1 IP address...                         "
#	echo "=============================================="
#	echo ''

	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"

	Sx1Index=201
	function CheckHighestSx1IndexHit {
		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 nslookup -timeout=5 10.207.29.$Sx1Index | grep 'name =' | wc -l
	}
	HighestSx1IndexHit=$(CheckHighestSx1IndexHit)

	while [ $HighestSx1IndexHit = 1 ]
	do
       	 	Sx1Index=$((Sx1Index+1))
       	 	HighestSx1IndexHit=$(CheckHighestSx1IndexHit)
	done

 	sleep 5

#	clear

#	echo ''
#	echo "=============================================="
#	echo "Get sw1 IP address.                           "
#	echo "=============================================="
#	echo ''

	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"

	Sw1Index=201
	function CheckHighestSw1IndexHit {
		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 nslookup -timeout=5 10.207.39.$Sw1Index | grep 'name =' | wc -l
	}
	HighestSw1IndexHit=$(CheckHighestSw1IndexHit)

	while [ $HighestSw1IndexHit = 1 ]
	do
       	 	Sw1Index=$((Sw1Index+1))
       	 	HighestSw1IndexHit=$(CheckHighestSw1IndexHit)
	done

#	sleep 5

#	clear
elif [ $MultiHostVar3 = 'X' ]  && [ $GRE = 'N' ] && [ $MultiHostVar2 = 'Y' ]
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

if   [ $Release -eq 7 ]
then
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
	echo "Ensure Networks up...                         "
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

# if [ $SystemdResolvedInstalled -eq 0 ] && [ $NMResolv -eq 0 ] && [ $GNS1 -eq 0 ]
# then
# 	echo ''
#  	echo "=============================================="
#  	echo "Activating NetworkManager dnsmasq service ... "
#  	echo "=============================================="
#  	echo ''

#  	# So that settings in /etc/NetworkManager/dnsmasq.d/local & /etc/NetworkManager/NetworkManager.conf take effect.

#  	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g"			/etc/resolv.conf
#  	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g"	/etc/resolv.conf
#  	sudo cat /etc/resolv.conf
#  	sudo sed -i '/plugins=ifcfg-rh/a dns=none' /etc/NetworkManager/NetworkManager.conf
#  	sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/NetworkManager/NetworkManager.conf
#  	echo ''

#  	sudo service NetworkManager restart
#  	sudo service sw1 restart	

#  	function CheckResolvReady {
#  		sudo cat /etc/resolv.conf | grep -c 'nameserver 127\.0\.0\.1'
#  	}
#  	ResolvReady=$(CheckResolvReady)
#  	echo ''
#  	NumResolvReadyTries=0
#  	while [ $ResolvReady -ne 1 ] && [ $NumResolvReadyTries -lt 60 ]
#   	do
#  		ResolvReady=$(CheckResolvReady)
#  		((NumResolvReadyTries=NumResolvReadyTries+1))
#  		sleep 1
#  		echo 'NumResolvReadyTries = '$NumResolvReadyTries
#  	done

#  	if [ $ResolvReady -eq 1 ]
#  	then
#  		echo ''
#  		sudo service sw1 restart
#  	else
#  		echo ''
#  		echo "=============================================="
#  		echo "NetworkManager didn't set nameserver 127.0.0.1"
#  		echo "which is the setting required for NM dnsmasq. "
#  		echo "=============================================="
#  	fi

#  	# sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1' >> /etc/resolv.conf"
#  	sudo cat /etc/resolv.conf
#  	echo ''

#  	echo "=============================================="
#  	echo "NetworkManager dnsmasq activated.             "
#  	echo "=============================================="
#  fi

# sleep 5

# clear

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

	echo "/etc/systemd/system/$NameServer.service" >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
	sudo cp -p /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst ~/nameserver.lst
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

if [ $GRE = 'Y' ] || [ $MultiHostVar3 -eq 1 ]
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

	if [ -n $NameServer ]
	then
 		sudo service sw1 restart
 		sudo service sx1 restart
		sudo lxc-stop  -n $NameServer > /dev/null 2>&1
		sudo lxc-copy  -n $NameServer -N $NameServer-bk0 > /dev/null 2>&1
		sudo lxc-start -n $NameServer > /dev/null 2>&1
	fi

	echo ''
	echo "=============================================="
	echo "Done: Start LXC DNS DHCP container.           "
	echo "=============================================="
fi

sleep 5

clear

if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'Y' ] && [ $GRE = 'Y' ]
then
        echo ''
        echo "=============================================="
        echo "Replicate nameserver $NameServer...           "
        echo "=============================================="
        echo ''

        sudo chown $Owner:$Group /home/$Owner/Manage-Orabuntu
        sudo chmod 775 /opt/olxc/"$DistDir"/orabuntu/archives/nameserver_copy.sh
        /opt/olxc/"$DistDir"/uekulele/archives/nameserver_copy.sh $MultiHostVar5 $MultiHostVar6 $MultiHostVar8 $MultiHostVar9 $NameServer
        sudo lxc-copy -n $NameServer -N $NameServer-bk0

        echo ''
        echo "=============================================="
        echo "Done: Replicate nameserver $NameServer.       "
        echo "=============================================="
        echo ''
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
#	GLS 20170904 Switches sx1 and sw1 are set earlier so they are not set here.

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

	sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/scst-files.tar -C /opt/olxc	--touch
#	sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/scst-files.tar -C /		--touch
	sleep 2
	sudo mv /opt/olxc/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files /opt/olxc/home/"$Owner"/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files
	sudo chown $Owner:$Group /opt/olxc/home/orabuntu/Downloads/orabuntu-lxc-master/uekulele/archives/
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /opt/olxc/"$DistDir"/uekulele/archives/scst-files/create-scst-oracle.sh
		
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

	sudo lxc-attach -n $NameServer -- usermod --password `perl -e "print crypt('ubuntu','ubuntu');"` ubuntu
	ssh-keygen -R 10.207.39.2
#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"
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

	sudo lxc-attach -n $NameServer -- crontab /root/crontab.txt
	sudo lxc-attach -n $NameServer -- crontab -l
	sudo lxc-attach -n $NameServer -- mkdir -p /root/backup-lxc-container/$NameServer/updates
	sudo lxc-attach -n $NameServer -- tar -cvzPf /root/backup-lxc-container/$NameServer/updates/backup_"$NameServer"_ns_update.tar.gz /root/ns_backup_update.lst

	sudo tar -v --extract --file=/opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-cont.tar -C / var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-sync.service
	sudo mv /var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-sync.service /var/lib/lxc/$NameServer/rootfs/etc/systemd/system/dns-sync.service

	sudo lxc-attach -n $NameServer -- systemctl enable dns-sync
	sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/fwd.$Domain1
	sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/rev.$Domain1
	sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/fwd.$Domain2
	sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/rev.$Domain2
	sudo lxc-attach -n $NameServer -- chown root:bind /var/lib/bind
	sudo lxc-attach -n $NameServer -- chmod 775 /var/lib/bind
               
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

	sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/scst-files.tar -C /opt/olxc	--touch
#	sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/scst-files.tar -C /		--touch
#	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /opt/olxc/"$DistDir"/uekulele/archives/scst-files/create-scst-oracle.sh
		
	echo ''
	echo "=============================================="
	echo "Done: Unpack SCST Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

#       sudo service sw1 restart
#       sudo service sx1 restart

	if [ $GRE = 'Y' ]
	then
		sudo sed -i "/route add -net/s/#/ /"				/etc/network/openvswitch/crt_ovs_sw1.sh	
		sudo sed -i "/REMOTE_GRE_ENDPOINT/s/#/ /"			/etc/network/openvswitch/crt_ovs_sw1.sh	
		sudo sed -i "s/REMOTE_GRE_ENDPOINT/$MultiHostVar5/g"		/etc/network/openvswitch/crt_ovs_sw1.sh

#		function GetGrePortName {
#			sudo ovs-vsctl show | grep -B3 "$MultiHostVar5" | grep Port | sed 's/  *//g' | cut -f2 -d'"'
#		}
#		GrePortName=$(GetGrePortName)

#		function GetGrePortNameStringLen {
#			echo $GrePortName | wc -c
#		}
#		GrePortNameStringLen=$(GetGrePortNameStringLen)

#		if [ $GrePortNameStringLen -gt 1 ]
#		then
#			function CheckGreExists {
#				sudo ovs-vsctl show | grep $GrePortName | wc -l
#			}
#			GreExists=$(CheckGreExists)
#
#			if [ $GreExists -gt 0 ]
#			then
#				sudo ovs-vsctl del-port $GrePortName
#			fi
#		fi

		sudo ovs-vsctl add-port sw1 gre$Sw1Index -- set interface gre$Sw1Index type=gre options:remote_ip=$MultiHostVar5

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

 		sudo sed -i "s/MultiHostVar6/$MultiHostVar6/g" 	/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
 		sudo sed -i "s/MultiHostVar3/$Sw1Index/g" 	/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

		sudo chmod 777 /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

                sleep 5

                clear

                echo ''
                echo "=============================================="
                echo "Setup GRE & Routes on $MultiHostVar5...       "
                echo "=============================================="
                echo ''
	
#		sudo service sw1 restart
#		sudo service sx1 restart

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

		function GetShortHost {
			uname -n | cut -f1 -d'.'
		}
		ShortHost=$(GetShortHost)

		sudo ifconfig sw1 mtu $MultiHostVar7
		sudo ifconfig sx1 mtu $MultiHostVar7

		nslookup -timeout=5 $HOSTNAME.$Domain1 > /dev/null 2>&1
		if [ $? -eq 1 ]
		then		
			echo ''
			echo "=============================================="
			echo "Create ADD DNS $ShortHost.$Domain1...         "
			echo "=============================================="
			echo ''

			sudo sh -c "echo 'echo \"server 10.207.39.2'								    	>  /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
			sudo sh -c "echo 'update add $ShortHost.orabuntu-lxc.com 3600 IN A 10.207.39.$Sw1Index'		    		>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
			sudo sh -c "echo 'update add $Sw1Index.39.207.10.in-addr.arpa 3600 IN PTR $ShortHost.orabuntu-lxc.com' 		>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
			sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
			sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"

			sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh
			sudo ls -l     						/etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh
			sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"		/etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh

			echo ''
			echo "=============================================="
			echo "Create DEL DNS $ShortHost.$Domain1...         "
			echo "=============================================="
			echo ''

			sudo sh -c "echo 'echo \"server 10.207.39.2'								    	>  /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
			sudo sh -c "echo 'update delete $ShortHost.orabuntu-lxc.com. A'					    		>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
			sudo sh -c "echo 'update delete $Sw1Index.39.207.10.in-addr.arpa. PTR'				 		>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
			sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
			sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"

			sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh
			sudo ls -l     						/etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh
			sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"		/etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh

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

		nslookup -timeout=5 $HOSTNAME.$Domain2 > /dev/null 2>&1
		if [ $? -eq 1 ]
		then		
			echo ''
			echo "=============================================="
			echo "Create ADD DNS $ShortHost.$Domain2 ...        "
			echo "=============================================="
			echo ''

			sudo sh -c "echo 'echo \"server 10.207.29.2'								    	>  /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
			sudo sh -c "echo 'update add $ShortHost.consultingcommandos.us 3600 IN A 10.207.29.$Sx1Index'		    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
			sudo sh -c "echo 'update add $Sx1Index.29.207.10.in-addr.arpa 3600 IN PTR $ShortHost.consultingcommandos.us' 	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
			sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
			sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
			sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"

			sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh
			sudo ls -l     						/etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh
			sudo sed -i "s/consultingcommandos\.us/$Domain2/g"	/etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh

			echo ''
			echo "=============================================="
			echo "Create DEL DNS $ShortHost.$Domain2...         "
			echo "=============================================="
			echo ''

			sudo sh -c "echo 'echo \"server 10.207.29.2'				    		>  /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
			sudo sh -c "echo 'update delete $ShortHost.consultingcommandos.us. A'  			>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
			sudo sh -c "echo 'send'							    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
			sudo sh -c "echo 'update delete $Sx1Index.29.207.10.in-addr.arpa. PTR' 			>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
			sudo sh -c "echo 'send'							    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
			sudo sh -c "echo 'quit'							    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
			sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'			    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"

			sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh
			sudo ls -l     						/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh
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
        systemd-resolve --status | head -6 | tail -5

        echo ''
        echo "=============================================="
        echo "Done: Restart systemd-resolved.               "
        echo "=============================================="
        echo ''

        sleep 5

        clear

elif [ $LxcNetRunning -ge 1 ] 
then
        echo ''
        echo "=============================================="
        echo "Restart service lxc-net...                    "
        echo "=============================================="
        echo ''

	function GetDhcpRange {
        	cat /etc/sysconfig/lxc-net | grep LXC_DHCP_RANGE | cut -f2 -d'=' | sed 's/"//g' 
	}       
	DhcpRange=$(GetDhcpRange)
	DHR="$DhcpRange"
	sudo sed -i "s/DHCP-RANGE-OLXC/dhcp-range=$DHR/" /etc/dnsmasq.conf
        sudo service lxc-net restart 
        sleep 2
        sudo service lxc-net status

        echo ''
        echo "=============================================="
        echo "Done: Restart service lxc-net.                "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

# GLS 20161118 This section for any tweaks to the unpacked files from archives.
if [ $Release -ge 6 ]
then
	sudo rm /etc/network/if-up.d/orabuntu-lxc-net
fi

echo ''
echo "=============================================="
echo "MultiHost Settings Completed.                 "
echo "=============================================="

sleep 5

clear

SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)
NetworkManagerRunning=$(CheckNetworkManagerRunning)

# echo 'SystemdResolvedInstalled =  '$SystemdResolvedInstalled
# echo 'Trigger Value            =  0'
# echo 'NetworkManagerRunning    =  '$NetworkManagerRunning
# echo 'Trigger Value            >= 1'
# echo 'GRE                      =  '$GRE
# echo 'Trigger Value            =  Y'
# echo 'MultiHostVar2            =  '$MultiHostVar2
# echo 'Trigger Value            =  N'

# sleep 10

if [ $SystemdResolvedInstalled -eq 0 ] && [ $NetworkManagerRunning -ge 1 ]
then
	if [ $GRE = 'Y' ] || [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Configure NetworkManager with dnsmasq...      "
		echo "=============================================="
		echo ''

		function GetDhcpRange {
			cat /etc/sysconfig/lxc-net | grep LXC_DHCP_RANGE | cut -f2 -d'=' | sed 's/"//g' 
		}
		DhcpRange=$(GetDhcpRange)

		function GetListenAddress {
			cat /etc/sysconfig/lxc-net | grep LXC_ADDR | cut -f2 -d'=' | sed 's/"//g'
		}
		ListenAddress=$(GetListenAddress)

		function GetDnsmasqPid {
			ps -eo pid,comm | grep dnsmasq | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f1 -d' '
		}
		DnsmasqPid=$(GetDnsmasqPid)

#		sudo kill -9 $DnsmasqPid > /dev/null 2>&1

		DHR="$DhcpRange"
		LFL="/var/lib/misc/dnsmasq.lxcbr0.leases"
		ADR="$ListenAddress"
		PFL="/var/run/lxc/dnsmasq.pid"
		CFL="/etc/dnsmasq.conf"

		sudo sed -i '/plugins=ifcfg-rh/a dns=none' /etc/NetworkManager/NetworkManager.conf
		sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/NetworkManager/NetworkManager.conf
		sudo yum -y install dnsmasq
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/dnsmasq.conf
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/dnsmasq.conf
		sudo sed -i '/LXC_DHCP_CONFILE/s/#//' /etc/sysconfig/lxc-net
		sudo sed -i 's/^[ \t]*//' /etc/dnsmasq.conf
		sudo sed -i "/LXC_DHCP_CONFILE/s/LXC_DHCP_CONFILE=\/etc\/lxc\/dnsmasq.conf/LXC_DHCP_CONFILE=\/etc\/dnsmasq.conf/" /etc/sysconfig/lxc-net
		sudo sed -i "s/DHCP-RANGE-OLXC/dhcp-range=$DHR/" /etc/dnsmasq.conf
		sudo service NetworkManager restart
		sleep 5
		sudo systemctl daemon-reload
		sudo rm -f /etc/resolv.conf
		sudo sh -c "echo 'nameserver 127.0.0.1' 			>  /etc/resolv.conf"
		sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1' 	>> /etc/resolv.conf"
		function GetDhcpRange {
        		cat /etc/sysconfig/lxc-net | grep LXC_DHCP_RANGE | cut -f2 -d'=' | sed 's/"//g' 
		}       
		DhcpRange=$(GetDhcpRange)
		DHR="$DhcpRange"
		sudo sed -i "s/DHCP-RANGE-OLXC/dhcp-range=$DHR/" /etc/dnsmasq.conf
		sudo service lxc-net restart
 		sudo service lxc-net status
		echo ''
		sleep 2
		nslookup $NameServer
#		nslookup 10.207.39.2
#		nslookup 10.207.29.2
#		nslookup yum.oracle.com
		ping -c 3 $NameServer
#		ping -c 3 yum.oracle.com
	
		echo ''
		echo "=============================================="
		echo "Done: Configure NetworkManager with dnsmasq.  "
		echo "=============================================="
		echo ''
	fi
fi

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

