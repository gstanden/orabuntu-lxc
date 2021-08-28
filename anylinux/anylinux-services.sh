#!/bin/bash

#    Copyright 2015-2021 Gilbert Standen
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
#    v7.0-AMIDE-beta	GLS 20210428 Orabuntu-LXC AmazonS3 Multi-Host LXD Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#    See CONFIG file for user-settable configuration variables.

MultiHost=$1

function GetGREValue {
	echo $MultiHost | cut -f10 -d':'
}
GREValue=$(GetGREValue)

function GetDistDir {
	pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

function GetGroup {
	id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
	id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D'  /etc/resolv.conf

# GLS 20180112
# User-settable subnets added
# Set numeric values to valid ip address triplets.  
# Typically private addresses in the ranges 10, 172, or 192 ranges would be used but the software will allow any valid IP address ranges.
# If left commented, the address ranges are set automatically.
# This subnet code is beta so checking and exception handlers are not coded yet.  BE SURE the nets are valid format before running.  Some caveats:
#             The nets SeedNet1, BaseNet1, etc. should ALL BE DIFFERENT subnets.
#             Not all possible combinations have been tested; some could be non-complimentary
#             DO NOT USE well-known multicast subnets such as 224.x.x.x and also probably best to not use 169.x.x.x
#	      Any subnet triplets will be allowed, but in general these are typically private ipv4 address spaces as defined here: https://en.wikipedia.org/wiki/Private_network
# GLS 20180112

# Set these (optional) before running anylinux-serivces.sh 

# Custom Subnets Begin

# pgroup1 begin
# user-settable parameters group 1 begin
# set the values for the subnet triplets (e.g. 172.29.108)
# Orabuntu-LXC v7 please use the new variable configuration file ./anylinux/CONFIG referenced below.

#	SeedNet1='SeedNet1Fwd:172.29.108'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	BaseNet1='BaseNet1Fwd:10.209.53'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	StorNet1='StorNet1Fwd:10.210.107'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	StorNet2='StorNet2Fwd:10.211.107'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS

#	ExtrNet1='172.200.11'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	ExtrNet2='172.201.11'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	ExtrNet3='192.168.19'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	ExtrNet4='192.168.20'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	ExtrNet5='192.168.21'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
#	ExtrNet6='192.168.22'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS

# Orabuntu-LXC v7 uses a centralized variable configuration file ./anylinux/CONFIG referenced below.

SeedNet1=$(source "$DistDir"/anylinux/CONFIG; echo $SeedNet1)
BaseNet1=$(source "$DistDir"/anylinux/CONFIG; echo $BaseNet1)
StorNet1=$(source "$DistDir"/anylinux/CONFIG; echo $StorNet1)
StorNet2=$(source "$DistDir"/anylinux/CONFIG; echo $StorNet2)
ExtrNet1=$(source "$DistDir"/anylinux/CONFIG; echo $ExtrNet1)
ExtrNet2=$(source "$DistDir"/anylinux/CONFIG; echo $ExtrNet2)
ExtrNet3=$(source "$DistDir"/anylinux/CONFIG; echo $ExtrNet3)
ExtrNet4=$(source "$DistDir"/anylinux/CONFIG; echo $ExtrNet4)
ExtrNet5=$(source "$DistDir"/anylinux/CONFIG; echo $ExtrNet5)
ExtrNet6=$(source "$DistDir"/anylinux/CONFIG; echo $ExtrNet6)

# pgroup1 end
# user-settable parameters group 1 end
# Custom Subnets End

clear

echo ''
echo "=============================================="
echo "Script:  anylinux-services.sh                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "==============================================" 
echo "Establish sudo privileges...                  "
echo "=============================================="
echo ''

echo $SudoPassword | sudo -S date

echo ''
echo "==============================================" 
echo "Privileges established.                       "
echo "=============================================="

sleep 5

clear

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

if   [ $LinuxFlavor = 'Oracle' ]
then
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
	if   [ $OracleDistroRelease -eq 7 ] || [ $OracleDistroRelease -eq 6 ]
	then
		CutIndex=7

	elif [ $OracleDistroRelease -eq 8 ]
	then
		CutIndex=6
	fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
	UbuntuMajorVersion=0
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
	if   [ $LinuxFlavor = 'Red' ]
        then
                function GetRedHatVersion {
                        sudo cat /etc/redhat-release | rev | cut -f2 -d' ' | cut -f2 -d'.'
                }
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
        fi
	RedHatVersion=$(GetRedHatVersion)
        RHV=$RedHatVersion
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
	UbuntuMajorVersion=0
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
	if   [ $RedHatVersion -ge 28 ]
	then
		Release=8
        elif [ $RedHatVersion -ge 19 ] && [ $RedHatVersion -le 27 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
        RL=$Release
	RHV=$RedHatVersion
	SubDirName=uekulele
	UbuntuMajorVersion=0
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Pop_OS' ]
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
	SubDirName=orabuntu
	Release=0
fi

# Check if firewalld.conf file exists.

function GetFwd1 {
	sudo find / -name firewalld.conf 2>/dev/null | wc -l
}
Fwd1=$(GetFwd1)

# Get FirewallBackend [ iptables | nftables ]

if [ $Fwd1 -gt 0 ]
then
	function GetFwdConfFilename {
		sudo find / -name firewalld.conf 2>/dev/null
	}
	FwdConfFilename=$(GetFwdConfFilename)

	function GetFwdBackend {
		sudo grep FirewallBackend $FwdConfFilename | grep FirewallBackend | grep -v '#' | cut -f2 -d'='
	}
	FwdBackend=$(GetFwdBackend)
fi

# Check if firewalld package is installed.

if [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'Fedora' ]
then
	echo ''
	echo "==============================================" 
	echo "Install libvirt ...                           "
	echo "=============================================="
	echo ''

	sudo yum -y install libvirt

	echo ''
	echo "==============================================" 
	echo "Done: Install libvirt                         "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	function GetFwd2 {
		sudo rpm -qa | grep -c firewalld
	}

elif [ $LinuxFlavor = 'Ubuntu' ]
then
	function GetFwd2 {
		sudo dpkg -l | grep -c firewalld
	}
fi
Fwd2=$(GetFwd2)

# Check if firewalld service is running.

function GetFwd3 {
	sudo firewall-cmd --state 2>/dev/null | grep -i 'running'
}
Fwd3=$(GetFwd3)

if [ $? -eq 0 ]
then
	function GetFirewalldBackend {
		sudo grep 'nftables' /etc/firewalld/firewalld.conf | grep FirewallBackend | grep -vc '#'
	}
	FirewalldBackend=$(GetFirewalldBackend)
else
	FirewalldBackend=0
fi

if [ $Fwd1 -ge 1 ] && [ $Fwd2 -ge 1 ] && [ $Fwd3 = 'running' ]
then
	if   [ $LinuxFlavor = 'CentOS' ]
	then
		Zone=trusted

	elif [ $LinuxFlavor = 'Fedora' ]
	then
		Zone=trusted

	elif [ $LinuxFlavor = 'Oracle' ]
	then
		Zone=trusted

	elif [ $LinuxFlavor = 'Red' ]
	then
		Zone=trusted
	fi

	echo ''
	echo "=============================================="
	echo "Set firewalld rules for dhcp and dns...       "
	echo "=============================================="
	echo ''

 	sudo firewall-cmd --zone=$Zone --permanent --add-service=dhcp
 	sudo firewall-cmd --zone=$Zone --permanent --add-service=dns
 	sudo firewall-cmd --zone=$Zone --permanent --add-service=https 
 	sudo firewall-cmd --zone=$Zone --permanent --add-port=587/tcp
 	sudo firewall-cmd --zone=$Zone --permanent --add-port=443/tcp

	sudo firewall-cmd --zone=$Zone --permanent --add-protocol=gre
 	sudo firewall-cmd --zone=$Zone --permanent --add-interface=gre_sys
	sudo firewall-cmd --zone=$Zone --permanent --add-port=6081/udp
	sudo firewall-cmd --zone=$Zone --permanent --add-interface=genev_sys_6081
 	sudo firewall-cmd --zone=$Zone --permanent --add-port=4789/udp
 	sudo firewall-cmd --zone=$Zone --permanent --add-interface=vxlan_sys_4789

	sudo firewall-cmd --zone=$Zone --permanent --add-interface=sw1
	sudo firewall-cmd --zone=$Zone --permanent --add-interface=sw1a
	sudo firewall-cmd --zone=$Zone --permanent --add-interface=sx1
	sudo firewall-cmd --zone=$Zone --permanent --add-interface=sx1a
	sudo firewall-cmd --zone=$Zone --permanent --add-interface=lxcbr0
	sudo firewall-cmd --zone=$Zone --permanent --add-interface=lxdbr0

#	GLS 20210827 Opens up all ports.  Useful for debugging.  Not recommended for production.
#	sudo firewall-cmd --zone=$Zone --permanent --add-port=1024-65000/udp
#	sudo firewall-cmd --zone=$Zone --permanent --add-port=1024-65000/tcp

	sudo firewall-cmd --zone=$Zone --permanent --add-masquerade
	sudo firewall-cmd --reload
	sudo firewall-cmd --list-services
	sudo firewall-cmd --get-active-zones
	sudo firewall-cmd --get-default-zone

	echo ''
	echo "=============================================="
	echo "Done: Set firewalld rules for dhcp and dns.   "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

: ' Commented Out Start ----------------------------------------------------------

if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -ge 31 ]
then
	echo ''
	echo "=============================================="
	echo "Install package grubby ...                    "
	echo "=============================================="
	echo ''

	sudo yum -y install grubby
	
	echo ''
	echo "=============================================="
	echo "Install package grubby ...                    "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	function GetCGH {
		sudo grubby --info=ALL | grep -c 'systemd.unified_cgroup_hierarchy=0'
	}
	CGH=$(GetCGH)
fi

if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -ge 31 ]
then
	if [ $FirewalldBackend -eq 1 ] || [ $CGH -eq 0 ]
	then
		echo ''
		echo "=============================================="
		echo "                                              "
		echo "              !!  NOTICE !!                   "
		echo "                                              "
		echo "      Fedora 31 & higher use cgroupv2         "
		echo " Orabuntu-LXC supports only cgroupv1 installs "
		echo "                                              "
		echo " This issue is documented extensively:        "
		echo "                                              "
		echo "    https://fedoramagazine.org/docker-and-fedora-32/"
		echo "    https://poweruser.blog/how-to-install-docker-on-fedora-32-f2606c6934f1"
		echo "    https://fedoraproject.org/wiki/Changes/CGroupsV2"
		echo "    https://www.redhat.com/sysadmin/fedora-31-control-group-v2"
		echo "                                              "
		echo " In particular:                               "
		echo "                                              "
		echo "     https://linuxcontainers.org/lxc/news/    "
		echo "     See note at above linuxcontainers.org:   "
		echo "    'LXC 4 lacks support for pure cgroupv2'   "
		echo "     https://wiki.debian.org/LXC/CGroupV2     "
		echo "                                              "
		echo "  Orabuntu-LXC can switch Fedora to cgroupv1  "
		echo " Answer Y below to prepare Fedora for install "
		echo "                                              "
		echo "              !! IMPORTANT !!                 "
		echo "                                              "
		echo "   VALIDATE CHANGES TO KERNEL AND FIREWALL    "
		echo "       ON TEST OR DEVELOPMENT FIRST!!         "
		echo "                                              "
		echo "  THE CHANGES THAT ARE ABOUT TO BE MADE ARE:  "
		echo "                                              "
		echo "  1.  Edit /etc/firewalld/firewalld.conf to   "
		echo "      use FirewallBackend=iptables            "
		echo "  2.  Run the following command to switch to  "
		echo "      cgroupv1:                               "
		echo "                                              "
		echo '  sudo grubby --update-kernel=ALL             '
		echo '  --args="systemd.unified_cgroup_hierarchy=0" '
		echo "                                              "
		echo "   To REJECT this update ANSWER 'N' below.    "
		echo "   To ACCEPT this update ANSWER 'Y' below.    "
		echo "                                              "
		echo "   Answer 'Y' will cause AUTOMATIC UPDATE!    "
		echo "   Answer 'Y' will cause AUTOMATIC REBOOT!    "
		echo "                                              "
		echo " After reboot login again as 'root' & re-run: "
		echo "                                              "
		echo "      'anylinux-services.HUB.HOST.sh'         "
		echo "                    or                        "
		echo "      'anylinux-services.GRE.HOST.sh'         "
		echo "                                              "
		echo "=============================================="
		echo "                                              "
		read -e -p "Fedora $RedHatVersion Re-Config [Y/N]   " -i "N" F8Update
		echo "                                              "
		echo "=============================================="
		echo ''

	        if [ $F8Update = 'Y' ]
        	then
                	sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"
                	echo ''
                	sudo sed -i 's/=nftables/=iptables/g' /etc/firewalld/firewalld.conf
                	echo ''
                	sleep 5
                	sudo reboot
		fi
	
	elif [ $FirewalldBackend -eq 0 ] || [ $CGH -gt 0 ]
	then
		echo ''
        	echo "=============================================="
		echo "$LinuxFlavor $RHV running iptables/cgroupv1.  "
        	echo "=============================================="
		echo ''

		sleep 5

		clear
	fi
fi

if [ $LinuxFlavor = 'Red' ] && [ $Release -ge 8 ]
then
	if [ $FirewalldBackend -eq 1 ] 
	then
		echo ''
		echo "=============================================="
		echo "                                              "
		echo "              !!  NOTICE !!                   "
		echo "                                              "
		echo "      RedHat 8 & higher use nftables          "
		echo "    Orabuntu-LXC supports only iptables       "
		echo "                                              "
		echo "              !! IMPORTANT !!                 "
		echo "                                              "
		echo "        VALIDATE CHANGES TO FIREWALL          "
		echo "       ON TEST OR DEVELOPMENT FIRST!!         "
		echo "                                              "
		echo "  THE CHANGES THAT ARE ABOUT TO BE MADE ARE:  "
		echo "                                              "
		echo "  1.  Edit /etc/firewalld/firewalld.conf to   "
		echo "      use FirewallBackend=iptables            "
		echo "                                              "
		echo "   To REJECT this update ANSWER 'N' below.    "
		echo "   To ACCEPT this update ANSWER 'Y' below.    "
		echo "                                              "
		echo "   Answer 'Y' will cause AUTOMATIC UPDATE!    "
		echo "   Answer 'Y' will cause AUTOMATIC REBOOT!    "
		echo "                                              "
		echo " After reboot login again as 'root' & re-run: "
		echo "                                              "
		echo "      'anylinux-services.HUB.HOST.sh'         "
		echo "                    or                        "
		echo "      'anylinux-services.GRE.HOST.sh'         "
		echo "                                              "
		echo "=============================================="
		echo "                                              "
		read -e -p "RedHat $RedHatVersion Re-Config [Y/N]   " -i "N" R8Update
		echo "                                              "
		echo "=============================================="
		echo ''

	        if [ $R8Update = 'Y' ]
        	then
                	sudo sed -i 's/=nftables/=iptables/g' /etc/firewalld/firewalld.conf
                	echo ''
                	sleep 5
                	sudo reboot
		fi
	
	elif [ $FirewalldBackend -eq 0 ] 
	then
		echo ''
        	echo "=============================================="
		echo "$LinuxFlavor $RHV running iptables/cgroupv1.  "
        	echo "=============================================="
		echo ''

		sleep 5

		clear
        fi
fi

' Commented Out End ---------------------------------------------------

cp -p GNU3 "$DistDir"/"$SubDirName"/archives/.
cp -p GNU3 "$DistDir"/"$SubDirName"/.
cp -p GNU3 "$DistDir"/.
cp -p COPYING "$DistDir"/"$SubDirName"/archives/.
cp -p COPYING "$DistDir"/"$SubDirName"/.
cp -p COPYING "$DistDir"/.

if [ ! -f /etc/orabuntu-lxc-terms ]
then
	echo ''
	echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
	echo '"We have just folded space from lx. Many machines on lx. New machines. Better than those on Richesse."'
	echo '                                                                                                      '
	echo '                         -- Third Stage Navigator, from DUNE by Frank Herbert                         '
	echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "References and Acknowledgements Orabuntu-LXC  "
	echo "=============================================="
	echo ''
	echo 'Gilbert Standen' 
	echo 'gilbert@orabuntu-lxc.com'
	echo ''
	echo "=============================================="
	echo "The Orabuntu-LXC Github Project:              "
	echo "https://github.com/gstanden/orabuntu-lxc      " 
	echo "=============================================="
	echo ''
	echo 'The online publications of many authors and bloggers helped to make Orabuntu-LXC possible.'
	echo 'Links may go stale.  I will try to keep them up to date if possible.'
	echo ''
	echo "1.  'The Unknown Posters' (i.e. StackExchangers, StackOverflowers, UnixStackExchangers, etc.)"
	echo "2.  'VirtualBox' Jean Jacques Sarton https://www.virtualbox.org/wiki/Advanced_Networking_Linux"
	echo "3.  'The New Stack' Venu Murthy http://thenewstack.io/solving-a-common-beginners-problem-when-pinging-from-an-openstack-instance/"
	echo "4.  'Big Dino' Lee Hutchinson https://blog.bigdinosaur.org/running-bind9-and-isc-dhcp/"
	echo "5.  'Techie in IT' Sokratis Galiatsis https://sokratisg.net/2012/03/31/ubuntu-precise-dnsmasq/"
	echo "6.  'OpenvSwitch Examples' Jaret Pfluger https://github.com/jpfluger/examples/blob/master/ubuntu-14.04/openvswitch.md"
	echo "7.  'Howto run local scripts on systemstartup and/or shutdown' xaos52 (The Good Doctor) http://crunchbang.org/forums/viewtopic.php?id=14453"
	echo "8.  'Enable LXC neworking in Debian Jessie, Fedora 21 and others' Flockport https://www.flockport.com/enable-lxc-networking-in-debian-jessie-fedora-and-others/"
	echo "9.  'Creating an IP Tunnel using GRE on Linux' http://www.cnblogs.com/popsuper1982/p/3800548.html/"
	echo "10. 'When Should You Use a GRE Tunnel' https://supportforums.adtran.com/thread/1408/"
	echo "11. 'Connecting OVS Bridges with Patch Ports' Scott Lowe https://blog.scottlowe.org/2012/11/27/connecting-ovs-bridges-with-patch-ports/"
	echo "12. 'Make systemd service last service on boot' SimonPe https://superuser.com/questions/544399/how-do-you-make-a-systemd-service-as-the-last-service-on-boot"
	echo "13. 'Temporarily increase sudo timeout' Rockallite https://serverfault.com/questions/266039/temporarily-increasing-sudos-timeout-for-the-duration-of-an-install-script"
	echo "14. 'Failed to allocate peer tty device #1552' Christian Brauner https://github.com/lxc/lxc/issues/1552"
	echo "15. 'LXC ERROR: Unable to fetch GPG key from keyserver' Simos https://discuss.linuxcontainers.org/t/lxc-error-unable-to-fetch-gpg-key-from-keyserver/5434/2"
	echo "16. 'Apply patch when asked File to patch what should I do?' Kaz https://unix.stackexchange.com/questions/307487/apply-patch-when-asked-file-to-patch-what-should-i-do"
	echo "17. 'Re: [ovs-discuss] Build OpenvSwitch on Oracle Linux 8' Gilbert Standen https://www.mail-archive.com/ovs-discuss@openvswitch.org/msg06322.html"
	echo "18. 'DNS Not Resolving under Network [CentOS8] #957' lfiraza https://github.com/docker/for-linux/issues/957"
	echo "19. 'Firewalld CentOS 7 Masquerading' lzap https://serverfault.com/questions/623297/firewalld-centos-7-masquerading"
	echo "20. 'How do I read a variable from a file? (Ask Ubuntu)' Jesse Nickles https://askubuntu.com/questions/367136/how-do-i-read-a-variable-from-a-file"
	echo "21. 'Run process under group on solaris (StackExchange)' meuh https://unix.stackexchange.com/questions/402996/run-process-under-group-on-solaris"
	echo "22. 'Fedora 32: Error Could not resolve host' Humble https://www.humblec.com/fedora-32-error-could-not-resolve-host-while-building-docker-containers/"
	echo "23. 'Bug 1454584 - firewall-cmd generates bad iptables rule for GRE' gorshkov https://bugzilla.redhat.com/show_bug.cgi?id=1454584"
	echo ''
	echo "Acknowledgements"
	echo ''
        echo "1.  Mary Standen			(mother)	(1934-2016)"
        echo "2.  Yelena Belyaeva-Standen		(spouse)	(1943-2020)"
        echo "3.  Allen the Cat			(cat)		(2001-2018)"
        echo "4.  Noah the (replacement) Cat		(cat)		(2018-    )"
	echo ''
	echo "For their patience and support during the long hours worked in the past and the long hours to be worked in the future for Orabuntu-LXC."
	echo "Mary Standen my mother always raised me to put mission first and work first."
	echo ''
	echo "=============================================="
	echo "References and Acknowledgements End           "
	echo "=============================================="
	echo ''

	sleep 10

	clear
fi

sleep 5

clear

if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 6 ]
then
	function GetKernelVersion {
		uname -r | cut -f1 -d'.'
	}
	KernelVersion=$(GetKernelVersion)

	if [ $KernelVersion -eq 2 ]
	then
		echo ''
	     	echo "=============================================="
		echo "                                              "
		echo "CentOS stock 2.x kernels do not adequately    "
		echo "support cgroupfs for Orabuntu-LXC install.    "
		echo "                                              "
		echo "To install Orabuntu-LXC it is necessary to    "
		echo "upgrade to the "elrepo" kernel.               "
		echo "                                              "
		echo "          !!!!!  WARNING !!!!!                "
		echo "                                              "
		echo "Kernel upgrades can have unexpected effects   "
		echo "on applications with kernel dependencies.     "
		echo "                                              "
		echo "Do NOT upgrade your kernel if this is a PROD  "
		echo "(production) host or if this host is in any   "
		echo "way directly-related to production operations."
		echo "                                              "
		echo "Instead, first, run the Orabuntu-LXC installer"
		echo "and upgrade the kernel on an exact development"
		echo "copy of production and do a full system and   "
		echo "user acceptance test (UAT) of all the apps    "
		echo "running on this upgraded elrepo kernel.  If   "
		echo "those tests are successful, then Orabuntu-LXC "
		echo "and the elrepo kernel can be installed on the "
		echo "CentOS 6 production server.                   "
		echo "                                              "
		echo "Reminder that this is GNU3 software and that  "
		echo "this software is provided under the terms of  "
		echo "that license.  Please read and familiarize    "
		echo "with the GNU3 license before installing       "
		echo "Orabuntu-LXC on a production CentOS 6 server  "
        	echo "                                              "
        	echo "=============================================="
        	echo "                                              "
		read -e -p   "Upgrade to elrepo kernel ? [Y/N]              " -i "N" install_elrepo_kernel
        	echo "                                              "
        	echo "=============================================="

        	sleep 5

        	clear

		if [ $install_elrepo_kernel = 'Y' ] || [ $install_elrepo_kernel = 'y' ]
		then
			echo ''
			echo "==============================================" 
			echo "Install ELREPO 4.x kernel for CentOS 6 ...    "
			echo "=============================================="
			echo ''

			#GLS 20180405 Credit: Gerald Clark https://www.centos.org/forums/viewtopic.php?t=3155
			sudo sed -i 's/DEFAULTKERNEL=kernel/DEFAULTKERNEL=kernel-ml/g' /etc/sysconfig/kernel
			
			#GLS 20180405 Credit: https://portal.cloudunboxed.net/knowledgebase/17/Installing-the-latest-mainline-kernel-on-CentOS-6-and-7.html
			sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
			sudo rpm -Uvh http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm
			sudo yum --enablerepo=elrepo-kernel install kernel-ml

			echo ''
			echo "==============================================" 
			echo "Done: Install ELREPO 4.x kernel for CentOS 6. "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "==============================================" 
			echo "Host Reboot in 5 seconds...                   "
			echo "=============================================="
			echo ''
			echo "==============================================" 
			echo "After reboot re-run Orabuntu-LXC installer.   "
			echo "=============================================="
			echo ''
			
			sleep 5

			sudo reboot

			sleep 5
		else
			echo ''
			echo "==============================================" 
			echo "                                              "
			echo "   CentOS kernel version fails requirements.  "
			echo "       Orabuntu-LXC cannot be installed.      "
			echo "                  Exiting.                    "
			echo "                                              "
			echo "=============================================="
			exit
		fi
	else
		echo ''
		echo "==============================================" 
		echo "CentOS kernel version meets requirements.     "
		echo "=============================================="
	fi
fi

if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 7 ]
then
	sudo yum -y remove  unbound-libs-1.6.6-5*  > /dev/null 2>&1
	sudo yum -y install unbound-libs-1.6.6-1*  > /dev/null 2>&1
	sudo yum -y install unbound-devel-1.6.6-1* > /dev/null 2>&1
fi

echo ''
echo "=============================================="
echo "Display Installation Parameters ...           "
echo "=============================================="
echo ''

echo 'Linux Host Flavor         = '$LinuxFlavor    

if [ $LinuxFlavor != 'Ubuntu' ] && [ $LinuxFlavor != 'Pop_OS' ]
then
	echo 'Linux Host Release        = '$RedHatVersion
	echo 'Linux Host Base Release   = '$Release
else
	echo 'Linux Host Release        = '$UbuntuVersion
	echo 'Linux Host Base Release   = '$UbuntuMajorVersion
fi

# pgroup2 begin
# user-settable parameters group 2 begin
# set the value between 'then' and 'fi'

	MajorRelease=$8
	if [ -z $8 ]
	then
	#	MajorRelease=8
		MajorRelease=$(source "$DistDir"/anylinux/CONFIG; echo $MajorRelease)
	fi

	# -------------------------------------------------------------
	# GLS 20210220              MUST use Oracle Linux 8 Container with cgroupv2
	# GLS 20210313 Reconfirmed: MUST use Oracle Linux 8 Container with cgroupv2
	# GLS 20210818 Reference:   https://discuss.linuxcontainers.org/t/centos-7-containers-dont-get-an-ipv4-address/11287/5

	if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -ge 31 ]
	then
		MajorRelease=8
	fi

	# GLS 20210220 
	# -------------------------------------------------------------

	# -------------------------------------------------------------
	# GLS 20210220 MUST use Oracle Linux 7 (OL7) Container with OL6 

	if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 6 ] && [ $MajorRelease -eq 8 ]
	then
		MajorRelease=7
	fi

	if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 6 ] && [ $MajorRelease -eq 6 ]
	then
		MajorRelease=7
	fi

	# GLS 20210220 
	# -------------------------------------------------------------

	echo 'Oracle Container Release  = '$MajorRelease

	PointRelease=$2
	PointRelease=$(source "$DistDir"/anylinux/CONFIG; echo $PointRelease)
	
	if [ -z $2 ]
	then
		if   [ $MajorRelease -eq 8 ]
		then
			PointRelease=4

		elif [ $MajorRelease -eq 7 ] 
		then

			if [ $Release -eq 6 ]
			then
				PointRelease=3
			else
				PointRelease=9
			fi
	
		elif [ $MajorRelease -eq 6 ]
		then
			PointRelease=3
		fi
	fi
	
	echo 'Oracle Container Version  = '$MajorRelease.$PointRelease

	NumCon=$3
	if [ -z $3 ]
	then
		NumCon=4
		NumCon=$(source "$DistDir"/anylinux/CONFIG; echo $NumCon)
	fi
	echo 'Oracle Container Count    = '$NumCon

	Domain1=$4
	if [ -z $4 ]
	then
		Domain1=urdomain1.com
		Domain1=$(source "$DistDir"/anylinux/CONFIG; echo $Domain1)
	fi
	echo 'Domain1                   = '$Domain1

	Domain2=$5
	if [ -z $5 ]
	then
		Domain2=urdomain2.com
		Domain2=$(source "$DistDir"/anylinux/CONFIG; echo $Domain2)
	fi
	echo 'Domain2                   = '$Domain2

	NameServer=$6
	if [ -z $6 ]
	then
		NameServer=afns1
		NameServer=$(source "$DistDir"/anylinux/CONFIG; echo $NameServer)
	fi
	echo 'NameServer                = '$NameServer

	OSMemRes=$7
	if [ -z $7 ]
	then
		OSMemRes=1024
		OSMemRes=$(source "$DistDir"/anylinux/CONFIG; echo $OSMemRes)
	fi
	echo 'OSMemRes                  = '$OSMemRes 

# pgroup2 end
# user-settable parameters group 2 end

# MultiHost=$1

if [ -z $1 ]
then
	# First Orabuntu-LXC host (physical or virtual):

	GRE=N
	MultiHost="new:N:1:X:X:X:1500:X:X:$GRE"				# <-- default value for first Orabuntu-LXC host install ("hub" host).
	# MultiHost="reinstall:N:1:$SudoPassword:X:X:1500:X:X:$GRE"	# <-- reinstall value for first Orabuntu-LXC host install ("hub" host).

	# ('X' means value is not used so just leave it set to 'X')
	# Additional Orabuntu-LXC physical hosts (physical or virtual  hosts over GRE):
	# (Note: reading from left to right the first IP is the First Orabuntu-LXC host (MTU 1500) and the second IP is the Orabuntu-LXC GRE host (MTU 1420)
	# (Note: the passwords in the 8 and 9 fields are the "ubuntu" user with password "ubuntu" on the remote GRE host).
	# (Note: for now, you MUST use the "ubuntu" user on the remote GRE host with password "ubuntu" also).

	#MultiHost="new:Y:X:$SudoPassword:192.168.1.10:192.168.1.16:1420:ubuntu:ubuntu:$GRE"
	#MultiHost="reinstall:Y:X:$SudoPassword:192.168.7.32:192.168.7.21:1420:ubuntu:ubuntu:$GRE"

	# Additional Orabuntu-LXC virtual hosts (VM is on an Orabuntu-LXC physical host AND VM is on the Orabuntu-LXC OpenvSwitch network):

		# VM is on the first Orabuntu-LXC physical host (MTU 1500):
		# (Note: Set GRE to "N" in this use case).

		#MultiHost="new:Y:X:$SudoPassword:X:X:1500:X:X:$GRE"
		#MultiHost="reinstall:N:X:$SudoPassword:X:X:1500:X:X:$GRE"

		# VM is on a GRE Orabuntu-LXC hosts (physical or virtual) (MTU 1420):
		# (Note: Set GRE to "N" in this use case).

		#MultiHost="new:Y:X:$SudoPassword:X:X:1420:X:X:$GRE"
		#MultiHost="reinstall:Y:X:$SudoPassword:X:X:1420:X:X:$GRE"

	# Adding additional clones of a specific Oracle Linux container release (seed Orabuntu-LXC container for that version must ALREADY exist)

	#MultiHost="addclones"

	# Adding additional Oracle Linux container release versions to an existing Orabuntu-LXC host (physical or virtual)

	#MultiHost="addrelease:N:X:$SudoPassword:X:X:1420:X:X:$GRE"
fi
echo 'MultiHost                 = '$MultiHost

# GLS 20170924 Currently Orabuntu-LXC for Ubuntu Linux just uses the LXC package(s) provided by Canonical Ltd. and does not have an option to build LXC from source.
# GLS 20170924 Including an option to upgrade LXC from source over the Canonical LXC packages on Ubuntu Linux is on the roadmap but not yet available.
# GLS 20170924 Currently Orabuntu-LXC for Oracle Linux does build LXC from source.  You can use this parameter to set what version it will build.

# pgroup3 begin
# user-settable parameter group 3 begin
# set the value between 'then' and 'fi'

	LxcOvsVersion=$9
	if [ -z $9 ] && [ $LinuxFlavor != 'Fedora' ]
	then
	#	LxcOvsVersion="2.0.8:2.5.4"
               	LxcOvsVersion="2.1.1:2.5.4"

		if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Red' ]
		then
               		LxcOvsVersion="3.0.4:2.12.1"
		fi
			
		if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Oracle' ]
		then
               		LxcOvsVersion="3.0.4:2.12.1"
		fi
			
		if [ $Release -eq 8 ] && [ $LinuxFlavor = 'CentOS' ]
		then
               		LxcOvsVersion="3.0.4:2.12.1"
		fi
			
		if [ $Release -eq 7 ] && [ $LinuxFlavor = 'Red' ]
		then
               		LxcOvsVersion="3.0.4:2.12.1"
		fi
			
		if [ $Release -eq 7 ] && [ $LinuxFlavor = 'Oracle' ]
		then
               		LxcOvsVersion="3.0.4:2.12.1"
		fi
			
		if [ $Release -eq 7 ] && [ $LinuxFlavor = 'CentOS' ]
		then
               		LxcOvsVersion="3.0.4:2.12.1"
		fi
			
		if [ $Release -eq 6 ] && [ $LinuxFlavor = 'Oracle' ]
		then
               	#	LxcOvsVersion="2.0.8:2.5.4"
               		LxcOvsVersion="2.0.8:2.5.4"
		fi
		
		if [ $Release -eq 6 ] && [ $LinuxFlavor = 'CentOS' ]
		then
               	#	LxcOvsVersion="2.0.8:2.5.4"
               		LxcOvsVersion="2.1.1:2.5.4"
		fi
	fi

	if [ -z $9 ] && [ $LinuxFlavor = 'Fedora' ]
	then
		if     [ $RedHatVersion -ge 19 ] && [ $RedHatVersion -le 21 ]
		then
			LxcOvsVersion="2.0.9:2.5.4"   # Do NOT change 2.0.9 version of LXC here.  Must use 2.0.9 for now.

		elif   [ $RedHatVersion -ge 22 ] && [ $RedHatVersion -le 28 ]
		then
			LxcOvsVersion="3.0.4:2.12.1"  # Do NOT change 3.0.4 version of LXC here.  Must use 3.0.4 for now.

		elif [ $RedHatVersion -ge 29 ]
		then
		#	LxcOvsVersion="4.0.10:2.16.0" # GLS Most recent versions LXC/OVS as of 20210820
		#	LxcOvsVersion="4.0.10:2.10.0" # GLS Default Fedora 29 openvswitch strongly recommended.  Latest LXC.
			LxcOvsVersion="3.0.4:2.10.0"  # GLS Default Fedora 29 repo default versions (fastest install)
		fi
	fi

# pgroup3 end
# user-settable parameters group 3 end

if   [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Fedora' ]
then
	echo 'LxcOvsVersion             = '$LxcOvsVersion
elif [ $LinuxFlavor = 'Oracle' ]
then
	echo 'LxcOvsVersion             = '$LxcOvsVersion
elif [ $LinuxFlavor = 'Ubuntu' ]
then
	echo 'LxcOvsVersion             = Latest Canonical Repository Version (via apt-get)'
fi

echo 'GRE                       = '$GREValue

if [ -z $StorNet1 ]
then
	echo 'StorNet1                  = 10.207.40.0'
else
	echo 'StorNet1                  = '$StorNet1 | cut -f2 -d':' | sed 's/^/StorNet1                  = /'
fi

if [ -z $StorNet2 ]
then
	echo 'StorNet2                  = 10.207.41.0'
else
	echo 'StorNet2                  = '$StorNet2 | cut -f2 -d':' | sed 's/^/StorNet2                  = /'
fi

if [ -z $ExtrNet1 ]
then
	echo 'ExtrNet1                  = 172.220.40.0'
else
	echo 'ExtrNet1                  = '$ExtrNet1
fi

if [ -z $ExtrNet2 ]
then
	echo 'ExtrNet2                  = 172.221.40.0'
else
	echo 'ExtrNet2                  = '$ExtrNet2
fi

if [ -z $ExtrNet3 ]
then
	echo 'ExtrNet3                  = 192.210.39.0'
else
	echo 'ExtrNet3                  = '$ExtrNet3
fi

if [ -z $ExtrNet4 ]
then
	echo 'ExtrNet4                  = 192.211.39.0'
else
	echo 'ExtrNet4                  = '$ExtrNet4
fi

if [ -z $ExtrNet5 ]
then
	echo 'ExtrNet5                  = 192.212.39.0'
else
	echo 'ExtrNet5                  = '$ExtrNet5
fi

if [ -z $ExtrNet6 ]
then
	echo 'ExtrNet6                  = 192.213.39.0'
else
	echo 'ExtrNet6                  = '$ExtrNet6
fi

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

function GetMultiHostVar11 {
        echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)
Product=$MultiHostVar11

function GetMultiHostVar12 {
        echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)
LXDValue=$MultiHostVar12

	echo 'LXD                       = '$LXDValue

function GetMultiHostVar13 {
        echo $MultiHost | cut -f13 -d':'
}
MultiHostVar13=$(GetMultiHostVar13)
K8S=$MultiHostVar13

#	echo 'K8S                  	  = '$K8S #Displayed below Docker setting for readability.

function GetMultiHostVar14 {
        echo $MultiHost | cut -f14 -d':'
}
MultiHostVar14=$(GetMultiHostVar14)
PreSeed=$MultiHostVar14

	echo 'LXD Cluster PreSeed       = '$PreSeed

function GetMultiHostVar15 {
        echo $MultiHost | cut -f15 -d':'
}
MultiHostVar15=$(GetMultiHostVar15)
LXDCluster=$MultiHostVar15

	echo 'LXD Cluster               = '$LXDCluster

function GetMultiHostVar16 {
        echo $MultiHost | cut -f16 -d':'
}
MultiHostVar16=$(GetMultiHostVar16)
LXDStorageDriver=$MultiHostVar16

if [ $LXDCluster = 'Y' ]
then
	echo 'LXDStorageDriver          = '$LXDStorageDriver
else
	echo 'LXDStorageDriver          = Unused'
fi

function GetMultiHostVar17 {
        echo $MultiHost | cut -f17 -d':'
}
MultiHostVar17=$(GetMultiHostVar17)
StoragePoolName=$MultiHostVar17

if [ $LXDCluster = 'Y' ]
then
	echo 'StoragePoolName           = '$StoragePoolName
else
	echo 'StoragePoolName           = Unused'
fi

function GetMultiHostVar18 {
        echo $MultiHost | cut -f18 -d':'
}
MultiHostVar18=$(GetMultiHostVar18)
BtrfsLun=$MultiHostVar18

function GetMultiHostVar19 {
        echo $MultiHost | cut -f19 -d':'
}
MultiHostVar19=$(GetMultiHostVar19)
Docker=$MultiHostVar19

function GetMultiHostVar20 {
        echo $MultiHost | cut -f20 -d':'
}
MultiHostVar20=$(GetMultiHostVar20)
TunType=$MultiHostVar20

	echo 'Docker			  = '$Docker
	echo 'K8S                  	  = '$K8S


if [ $LinuxFlavor = 'Oracle' ] && [ $LXDCluster = 'Y' ]
then
	echo 'BtrfsLun                  = '$BtrfsLun
else
	echo 'BtrfsLun		  = Unused'
fi

if   [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'Y' ]
then
	function GetMultiHostVar5 {
		echo $MultiHost | cut -f5 -d':'
	}
	MultiHostVar5=$(GetMultiHostVar5)

	function GetMultiHostVar8 {
		echo $MultiHost | cut -f8 -d':'
	}
	MultiHostVar8=$(GetMultiHostVar8)

	function GetMultiHostVar9 {
		echo $MultiHost | cut -f9 -d':'
	}
	MultiHostVar9=$(GetMultiHostVar9)

	function GetSw1Net {
		echo $BaseNet1 | cut -f2 -d':'
	}
	Sw1Net=$(GetSw1Net)
	
	function GetSx1Net {
		echo $SeedNet1 | cut -f2 -d':'
	}
	Sx1Net=$(GetSx1Net)

	ssh-keygen -R $MultiHostVar5 > /dev/null 2>&1
        sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
        sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
       	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service dnsmasq restart > /dev/null 2>&1"
       
	function GetNameServerShortName {
        	echo $NameServer | cut -f1 -d'-'
	}
	NameServerShortName=$(GetNameServerShortName)

	Sx1Index=201
	function CheckDNSLookup {
		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" getent hosts $Sx1Net.$Sx1Index"
	}
	DNSLookup=$(CheckDNSLookup)
	DNSHit=$?

	if [ $UbuntuMajorVersion -ge 16 ] || [ $Release -ge 6 ]
	then
        	while [ $DNSHit -eq 0 ]
        	do
			Sx1Index=$((Sx1Index+1))
			DNSLookup=$(CheckDNSLookup)
			DNSHit=$?
        	done
	fi
 
	Sw1Index=201
	function CheckDNSLookup {
		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" getent hosts $Sw1Net.$Sw1Index"
	}
	DNSLookup=$(CheckDNSLookup)
	DNSHit=$?

	if [ $UbuntuMajorVersion -ge 16 ] || [ $Release -ge 6 ]
	then
        	while [ $DNSHit -eq 0 ]
        	do
			Sw1Index=$((Sw1Index+1))
			DNSLookup=$(CheckDNSLookup)
			DNSHit=$?
        	done
	fi
fi

if [ -z $SeedNet1 ]
then
	echo 'SeedNet1                  = 10.207.29.0'
else
	echo 'SeedNet1                  = '$SeedNet1 | cut -f2 -d':' | sed 's/^/SeedNet1                  = /'
fi
	
if   [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'Y' ]
then
	echo 'Switch IP (sx1)           = '$Sx1Net.$Sx1Index
fi

if [ -z $BaseNet1 ]
then
	echo 'BaseNet1                  = 10.207.39.0'
else
	echo 'BaseNet1                  = '$BaseNet1 | cut -f2 -d':' | sed 's/^/BaseNet1                  = /'
fi

if   [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'Y' ]
then
	echo 'Switch IP (sw1)           = '$Sw1Net.$Sw1Index
fi

	echo 'DistDir                   = '$DistDir
	echo 'SubDirName                = '$SubDirName
	echo 'Product                   = '$Product

if [ $LinuxFlavor != 'Ubuntu' ] && [ $LinuxFlavor != 'Pop_OS' ]
then
	echo 'RPM libvirt installed     = '`rpm -qa | grep libvirt-[01234567] | grep -v client`
fi

if [ -z $TunType ]
then
	TunType=geneve
	echo 'Tunnel Type		  = '$TunType
else
	echo 'Tunnel Type		  = '$MultiHostVar20
fi

echo ''
echo "=============================================="
echo "Display Installation Parameters complete.     "
echo "=============================================="

sleep 10

clear

function GetMultiHostVar2 {
	echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar3 {
	echo $MultiHost | cut -f3 -d':'
}
MultiHostVar3=$(GetMultiHostVar3)

function GetMultiHostVar7 {
	echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)

sudo yum -y     install net-tools > /dev/null 2>&1
sudo apt-get -y install net-tools > /dev/null 2>&1

if [ $MultiHostVar2 = 'Y' ] && [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Set Interface MTU...                          "
	echo "=============================================="
	echo ''

	function GetVirtualInterfaces {
		sudo ifconfig | grep enp | cut -f1 -d':' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	VirtualInterfaces=$(GetVirtualInterfaces)

	function GetSw1Net {
		echo $BaseNet1 | cut -f2 -d':'
	}
	Sw1Net=$(GetSw1Net)
	
	function GetSx1Net {
		echo $SeedNet1 | cut -f2 -d':'
	}
	Sx1Net=$(GetSx1Net)

	subnet="$Sw1Net $Sx1Net"

	for j in $subnet
	do
		for i in $VirtualInterfaces
       		do
       	        	function CheckVirtualInterfaceMtu {
       	                	sudo ifconfig $i | grep -B1 "$j" | grep mtu | cut -f5 -d' '
       	        	}
       	        	VirtualInterfaceMtu=$(CheckVirtualInterfaceMtu)
       	        	function GetCharCount {
       	                	echo $VirtualInterfaceMtu | wc -c
       	        	}
       	        	CharCount=$(GetCharCount)
       	        	if [ $CharCount -eq 5 ]
       	        	then
       	                	if [ $MultiHostVar7 -ne 1500 ]
       	                	then
					echo ''
					echo "=============================================="
					echo "Set NIC $i to MTU $MultiHostVar7...           "
					echo "=============================================="
					echo ''
	
       	                        	sudo ifconfig $i mtu $MultiHostVar7
					sudo ifconfig $i

					echo "=============================================="
					echo "Done: Set NIC $i to MTU $MultiHostVar7.       "
					echo "=============================================="
				
					sleep 5

					clear
	
					echo ''
					echo "=============================================="
					echo "Create $i-mtu manager systemd service...      "
					echo "=============================================="
					echo ''

					sudo sh -c "echo '[Unit]'						 > /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'Description=$i-mtu'					>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'After=network-online.target'				>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo ''							>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'Type=idle'						>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'ExecStart=/usr/sbin/ifconfig $i mtu $MultiHostVar7'	>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'ExecStop=/usr/sbin/ifconfig $i mtu 1500'		>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo ''							>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'WantedBy=network-online.target'			>> /etc/systemd/system/$i-mtu.service"
					sudo systemctl enable $i-mtu.service
					sudo systemctl daemon-reload
					sudo cat /etc/systemd/system/$i-mtu.service
	
					echo ''
					echo "=============================================="
					echo "Done: Create $i-mtu manager systemd service.  "
					echo "=============================================="
	
					sleep 5

					clear
       	                	fi
       	        	fi
       		done
	done

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Done:  Set Interface MTU...                   "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

if [ $GREValue = 'Y' ] || [ $MultiHostVar3 = 'X' ]
then
	function CheckHubFileSystemTypeExt {
		sshpass -p $MultiHostVar9 ssh -q -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 stat --file-system --format=%T /var/lib/lxc | grep -c ext
	}
	HubFileSystemTypeExt=$(CheckHubFileSystemTypeExt)

	function CheckHubFileSystemTypeXfs {
		sshpass -p $MultiHostVar9 ssh -q -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 stat --file-system --format=%T /var/lib/lxc | grep -c xfs
	}
	HubFileSystemTypeXfs=$(CheckHubFileSystemTypeXfs)

        if [ $HubFileSystemTypeXfs -eq 1 ]
        then
		function GetHubFtype {
			sshpass -p $MultiHostVar9 ssh -q -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" xfs_info / | grep -c ftype=1 | grep '0'" | cut -f2 -d':'
		}
		HubFtype=$(GetHubFtype)

		if   [ ! -z $HubFtype ]
		then
			echo ''
			echo "=============================================="
			echo "NS $NameServer full backup at HUB...          "
			echo "=============================================="
			echo ''

		#	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServer -k;echo '(Do NOT enter password...Wait...)'"
			sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S -p' ' <<< "$MultiHostVar9" lxc-stop -n $NameServer -k"
			sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-copy -n $NameServer -N $NameServer-$HOSTNAME" >/dev/null 2>&1
			sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sudo -S <<< "$MultiHostVar9" lxc-ls -f"
 			
			echo ''
 			echo "$NameServer-$HOSTNAME has been created on the Orabuntu-LXC HUB host at $MultiHostVar5"
 			echo "$NameServer-$HOSTNAME can be restored to $NameServer if necessary using lxc-copy command."

			echo ''
			echo "=============================================="
			echo "Done: NS $NameServer backup at HUB.           "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		elif [ -z $Ftype ]
		then
			echo ''
			echo "=============================================="
			echo "Snapshot Nameserver $NameServer at HUB...     "
			echo "=============================================="

			if [ $Release -ne 6 ] || [ $UbuntuMajorVersion -ge 16 ]
			then
			#	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S -prompt='' <<< "$MultiHostVar9" lxc-stop -n $NameServer -k;echo '(Do NOT enter a password.  Wait...)'; echo '$HOSTNAME pre-install nameserver snapshot' > snap_comment; echo ''; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -c snap_comment; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sleep 5; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -L -C"
				sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S -p' ' <<< "$MultiHostVar9" lxc-stop -n $NameServer -k; echo '$HOSTNAME pre-install nameserver snapshot' > snap_comment; echo ''; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -c snap_comment; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sleep 5; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -L -C"
				echo ''
				echo "Snapshot of $NameServer created on the Orabuntu-LXC HUB host at $MultiHostVar5."
				echo "Snapshot of $NameServer can be restored to $NameServer if necessary using 'lxc-snapshot -r SnapX -N $NameServer' command."
				sudo rm -f snap_comment
			else
				echo "LXC Snapshot not supported on Linux $Release."
			fi

			echo ''
			echo "=============================================="
			echo "Done: Snapshot Nameserver $NameServer at HUB. "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		fi
	fi

	if [ $HubFileSystemTypeExt -eq 1 ]
	then
		echo ''
		echo "=============================================="
		echo "Snapshot Nameserver $NameServer at HUB...     "
		echo "=============================================="
		echo ''

		if [ $Release -ne 6 ] || [ $UbuntuMajorVersion -ge 16 ]
		then
		#	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServer -k;echo '(Do NOT enter a password.  Wait...)'; echo '$HOSTNAME pre-install nameserver snapshot' > snap_comment; echo ''; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -c snap_comment; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sleep 5; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -L -C"
			sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S -p' ' <<< "$MultiHostVar9" lxc-stop -n $NameServer -k; echo '$HOSTNAME pre-install nameserver snapshot' > snap_comment; echo ''; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -c snap_comment; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sleep 5; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -L -C"
			echo ''
			echo "Snapshot of $NameServer created on the Orabuntu-LXC HUB host at $MultiHostVar5."
			echo "Snapshot of $NameServer can be restored to $NameServer if necessary using 'lxc-snapshot -r SnapX -N $NameServer' command."
			sudo rm -f snap_comment
		else
			echo "LXC Snapshot not supported on Linux $Release."
		fi

		echo ''
		echo "=============================================="
		echo "Done: Snapshot Nameserver $NameServer at HUB. "
		echo "=============================================="
		echo ''

		sleep 5

		clear
	fi
fi

SetNets=Y

if [ $SetNets = 'Y' ]
then
	echo ''
	echo "=============================================="
	echo "Get Subnet Regex Strings...                   "
	echo "=============================================="
	echo ''

	cd "$DistDir"/"$SubDirName"/archives

	function GetNets {
		echo "$SeedNet1 $BaseNet1 $StorNet1 $StorNet2"
	}
	Nets=$(GetNets)

	for i in $Nets
	do
		function GetNetNamFwd {
			echo $i | cut -f1 -d':'
		}
		NetNamFwd=$(GetNetNamFwd)
	
		function GetNetNamRev {
			echo $i | cut -f1 -d':' | sed 's/Fwd/Rev/'
		}
		NetNamRev=$(GetNetNamRev)
	
		function GetNetFwd {
			echo $i | cut -f2 -d':'
		}
		NetFwd=$(GetNetFwd)
	
		function GetNetRev {
			echo "$i" | cut -f2 -d':' | awk 'BEGIN{FS="."}{print $4"."$3"."$2"."$1""}' | sed 's/.//'
		}
		NetRev=$(GetNetRev)
	
		if   [ $NetNamFwd = 'SeedNet1Fwd' ]
		then
			SeedNet1F=$NetFwd
		
			function GetNetTriplet {
				echo $NetFwd | sed 's/\.//g'
			}
			NetTriplet=$(GetNetTriplet)
	
			function GetNetDoublet {
				echo $NetFwd | cut -f1,2 -d'.' | sed 's/\.//g'
			}
			NetDoublet=$(GetNetDoublet)
	
			function GetEscaped {
				echo $NetFwd | sed 's/\./\\\\\\\./g'
			}
			Escaped=$(GetEscaped)
	
			SeedNet12=$NetDoublet
			SeedNet13=$NetTriplet
			SeedNet1E=$Escaped
	
		elif [ $NetNamFwd = 'BaseNet1Fwd' ]
		then
			BaseNet1F=$NetFwd
			
			function GetNetTriplet {
				echo $NetFwd | sed 's/\.//g'
			}
			NetTriplet=$(GetNetTriplet)

			function GetNetDoublet {
				echo $NetFwd | cut -f1,2 -d'.' | sed 's/\.//g'
			}
			NetDoublet=$(GetNetDoublet)
	
			function GetEscaped {
				echo $NetFwd | sed 's/\./\\\\\\\./g'
			}
			Escaped=$(GetEscaped)
	
			BaseNet12=$NetDoublet
			BaseNet13=$NetTriplet
			BaseNet1E=$Escaped
	
		elif [ $NetNamFwd = 'StorNet1Fwd' ]
		then
			StorNet1F=$NetFwd
	
		elif [ $NetNamFwd = 'StorNet2Fwd' ]
		then
			StorNet2F=$NetFwd
		fi
	
		if   [ $NetNamRev = 'SeedNet1Rev' ]
		then
			SeedNet1R=$NetRev
	
		elif [ $NetNamRev = 'BaseNet1Rev' ]
		then
			BaseNet1R=$NetRev
	
		elif [ $NetNamRev = 'StorNet1Rev' ]
		then
			StorNet1R=$NetRev
	
		elif [ $NetNamRev = 'StorNet2Rev' ]
		then
			StorNet2R=$NetRev
		fi
	done

	echo 'SeedNet1F = '$SeedNet1F
	echo 'SeedNet1R = '$SeedNet1R
	echo 'SeedNet12 = '$SeedNet12
	echo 'SeedNet13 = '$SeedNet13
	echo 'SeedNet1E = '$SeedNet1E
	echo 'BaseNet1F = '$BaseNet1F
	echo 'BaseNet1R = '$BaseNet1R
	echo 'BaseNet12 = '$BaseNet12
	echo 'BaseNet13 = '$BaseNet13
	echo 'BaseNet1E = '$BaseNet1E
	echo 'StorNet1F = '$StorNet1F
	echo 'StorNet1R = '$StorNet1R
	echo 'StorNet2F = '$StorNet2F
	echo 'StorNet2R = '$StorNet2R

	echo ''	
	echo "=============================================="
	echo "Done: Get Subnet Regex Strings.               "
	echo "=============================================="
	echo ''
fi

sleep 5

clear

echo ''	
echo "=============================================="
echo "Update GNU3 and COPYING in archives...        "
echo "=============================================="
echo ''

sleep 5

cd "$DistDir"/anylinux
"$DistDir"/anylinux/anylinux-services-0.sh $SubDirName $Product
cd "$DistDir"/"$SubDirName"/archives

echo ''	
echo "=============================================="
echo "Done: Update GNU3 and COPYING in archives.    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''	
echo "=============================================="
echo "Archive Orabuntu-LXC scripts...               "
echo "=============================================="
echo ''

if [ ! -d /opt/olxc ]
then
	sudo mkdir -p  /opt/olxc
	sudo chmod 777 /opt/olxc
fi

# sudo rm  -f /opt/olxc/GNU3
# sudo rm -rf /opt/olxc/home
sudo mkdir -p /opt/olxc/home/scst-files
sudo cp -p "$DistDir"/anylinux/vercomp /opt/olxc/home/scst-files/.
sudo chmod +x "$DistDir"/anylinux/vercomp /opt/olxc/home/scst-files/vercomp

cp -p $DistDir/anylinux/GNU3 /opt/olxc/GNU3

echo "$DistDir/anylinux/vercomp" 						>  "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/anylinux/anylinux-services-1.sh" 				>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/anylinux/dnf2yum" 						>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/archives/nameserver_copy.sh" 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/archives/docker_install_$SubDirName.sh" 		>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/archives/lxd_install_$SubDirName.sh" 		>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-0.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-1.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-2.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-3.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-4.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-5.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/GNU3"                                                >> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/COPYING"                                             >> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/products/$Product/$Product"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/products/$Product/$Product.net"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/products/$Product/$Product.cnf"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
# echo "$DistDir/lxcimage/SHA256SUMS"						>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
# echo "$DistDir/lxcimage/oracle6/SHA256SUMS"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
# echo "$DistDir/lxcimage/oracle7/SHA256SUMS"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
# echo "$DistDir/lxcimage/oracle8/SHA256SUMS"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
# echo "$DistDir/lxcimage/nsa/SHA256SUMS"					>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst

cd "$DistDir"/"$SubDirName"/archives

tar -cPf  "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.tar -T "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst --numeric-owner
tar -tvPf "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.tar

echo ''	
echo "=============================================="
echo "Done: Archive Orabuntu-LXC scripts.           "
echo "=============================================="
echo ''

sleep 5

clear

echo ''	
echo "=============================================="
echo "Prepare Orabuntu-LXC Files & Archives...      "
echo "=============================================="
echo ''

# GLS 20180204 Replaced by function GetArchiveNames
# ArchiveNames="dns-dhcp-cont.tar dns-dhcp-host.tar lxc-oracle-files.tar product.tar ubuntu-host.tar scst-files.tar tgt-files.tar $SubDirName-services.tar"

function GetArchiveNames {
	ls *.tar | more | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
ArchiveNames=$(GetArchiveNames)
# echo $ArchiveNames

cp -p GNU3 /opt/olxc/GNU3
	
for i in $ArchiveNames
do
	clear
	
        function GetArchiveShortName {
                echo $i | cut -f1 -d'.'
        }
        ArchiveShortName=$(GetArchiveShortName)
	
	function GetArchiveFileList {
		sudo tar -P -tvf $i | sed 's/  */ /g' | cut -f6 -d' ' | sed 's/$/ /' > "$DistDir"/"$SubDirName"/archives/$ArchiveShortName.lst
	}
	ArchiveFileList=$(GetArchiveFileList)

	sudo cp -p "$DistDir"/"$SubDirName"/archives/$ArchiveShortName.lst /opt/olxc/$ArchiveShortName.lst	

	if [ $i != 'lxc-oracle-files.tar' ] && [ $i != 'product.tar' ]
	then	
		function GetTAR {
			cat /opt/olxc/$ArchiveShortName.lst | cut -f2 -d'/' | sort -u
		}
	else
		function GetTAR {
			cat /opt/olxc/$ArchiveShortName.lst | cut -f1 -d'/' | sort -u
		}
	fi
	TAR=$(GetTAR)

	sudo rm -rf /opt/olxc/"$TAR"

        sudo tar -P -tvf $i | sed 's/  */ /g' | cut -f6 -d' ' > $ArchiveShortName.lst

	function GetArchiveFileVar {
		sudo tar -P -tvf $i | sed 's/  */ /g' | cut -f6 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ArchiveFileVar=$(GetArchiveFileVar)

	if [ ! -f /opt/olxc/"$DistDir"/"$SubDirName"/archives/file-exceptions.txt ]
	then	
		sudo mkdir -p /opt/olxc
		sudo chown $Owner:$Group /opt/olxc
		sudo mkdir -p /opt/olxc/"$DistDir"/"$SubDirName"/archives/
		sudo chown $Owner:$Group /opt/olxc/"$DistDir"/"$SubDirName"/archives/
		sudo cp -p "$DistDir"/"$SubDirName"/archives/file-exceptions.txt /opt/olxc/"$DistDir"/"$SubDirName"/archives/file-exceptions.txt
		sudo sed -i "s/OWNER/$Owner/g" /opt/olxc/"$DistDir"/"$SubDirName"/archives/file-exceptions.txt
	fi

	echo ''	
	echo "=============================================="
	echo "List GNU3 Header Exemptions...                "
	echo "=============================================="
	echo ''

	for j in $ArchiveFileVar
	do
		if   [ ! -d $j ]
		then
			sudo tar -v --extract --file=$i -C /opt/olxc $j > /dev/null 2>&1

			grep $j /opt/olxc/"$DistDir"/"$SubDirName"/archives/file-exceptions.txt
			if [ $? -ne 0 ]
			then
				sudo sh -c "cat /opt/olxc/GNU3 /opt/olxc/$j > /opt/olxc/$j.gnu3"
				sudo chmod --reference /opt/olxc/$j /opt/olxc/$j.gnu3 > /dev/null 2>&1
				sudo chown --reference /opt/olxc/$j /opt/olxc/$j.gnu3 > /dev/null 2>&1
				sudo mv /opt/olxc/$j.gnu3 /opt/olxc/$j
				filename=/opt/olxc/$j
			fi
			if [ $i != 'dns-dhcp-cont.tar' ] && [ $i != 'dns-dhcp-host.tar' ] && [ $i != 'lxc-oracle-files.tar' ] && [ $i != 'product.tar' ] && [ $i != 'ubuntu-host.tar' ]
			then
				sudo chown $Owner:$Group $filename > /dev/null 2>&1
			fi
			filename=/opt/olxc/$j

			if [ $SetNets = 'Y' ] 
			then
 				sudo sed -i "s/10.207.41/$StorNet2F/g"			$filename
				sudo sed -i "s/10.207.40/$StorNet1F/g"			$filename
				sudo sed -i "s/10.207.39/$BaseNet1F/g"			$filename
				sudo sed -i "s/10.207.29/$SeedNet1F/g"			$filename
				sudo sed -i "s/39.207.10/$BaseNet1R/g"			$filename
				sudo sed -i "s/29.207.10/$SeedNet1R/g"			$filename
				sudo sed -i "s/1020729/$SeedNet13/g"			$filename
				sudo sed -i "s/1020739/$BaseNet13/g"			$filename
				sudo sed -i "s/10207/$BaseNet12/g"			$filename
				sudo sed -i "s/10\\\.207\\\.29/$SeedNet1E/g"		$filename
				sudo sed -i "s/10\\\.207\\\.39/$BaseNet1E/g"		$filename
				sudo sed -i "s/172.220.40/$ExtrNet1/g"			$filename
				sudo sed -i "s/172.221.40/$ExtrNet2/g"			$filename
				sudo sed -i "s/192.210.39/$ExtrNet3/g"			$filename
				sudo sed -i "s/192.211.39/$ExtrNet4/g"			$filename
				sudo sed -i "s/192.212.39/$ExtrNet5/g"			$filename
				sudo sed -i "s/192.213.39/$ExtrNet6/g"			$filename
			fi
			if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -ge 22 ] && [ $i = "$SubDirName-services.tar" ]
			then
				sudo sed -i '/lxc-attach/!s/yum -y install/dnf -y install/g'		$filename
				sudo sed -i "s/yum -y erase/dnf -y erase/g" 				$filename
				sudo sed -i "s/yum -y localinstall/dnf -y localinstall/g" 		$filename
				sudo sed -i "s/yum clean all/dnf clean all/g" 				$filename
				sudo sed -i "s/yum provides/dnf provides/g" 				$filename
				sudo sed -i "s/yum-utils/dnf-utils/g" 					$filename
				sudo sed -i "s/yum-complete-transaction//g"				$filename
			fi
		fi
	
	done

	echo ''	
	echo "=============================================="
	echo "Done: List GNU3 Header Exemptions.              "
	echo "=============================================="
	echo ''

	sleep 1

	echo "=============================================="
	echo "Process archive $i...                         "
	echo "=============================================="
	echo ''

	cd /opt/olxc

	if [ $i != 'scst-files.tar' ] && [ $i != 'tgt-files.tar' ]
	then
#		if [ $i = 'dns-dhcp-host.tar' ]
#		then
#			function TweakTAR {
#				echo $TAR | sed 's/var//' | sed 's/^[ \t]*//;s/[ \t]*$//'
#			}
#			TAR=$(TweakTAR)
#		fi

		sudo tar -cf $i $TAR 	--numeric-owner
		sudo tar -tvf $i 	--numeric-owner
	
		echo ''
		echo "=============================================="
		echo "Done: Process archive $i.                     "
		echo "=============================================="
		echo ''

		if [ $i != "$SubDirName-services.tar" ]
		then
			sudo rm -rf $TAR
		fi
	else
		sudo tar -cf $i $TAR	--numeric-owner
		sudo tar -tvf $i	--numeric-owner
	
		echo ''
		echo "=============================================="
		echo "Done: Process archive $i.                     "
		echo "=============================================="
	fi

	cd "$DistDir"/"$SubDirName"/archives

	sleep 5
done

cd /opt/olxc

# sleep 5

sudo cp -p *.lst /opt/olxc/"$DistDir"/"$SubDirName"/archives/.
sudo cp -p *.tar /opt/olxc/"$DistDir"/"$SubDirName"/archives/.

clear

sudo chown -R $Group:$Owner home
sudo tar -xf /opt/olxc/"$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.tar -C /opt/olxc
sudo chown -R $Group:$Owner home
sudo chmod 775 /opt/olxc/"$DistDir"/"$SubDirName"/"$SubDirName"-services-*.sh
sudo chmod 775 /opt/olxc/"$DistDir"/anylinux/*
sudo chmod 775 /opt/olxc/"$DistDir"/products/$Product/$Product
sleep 5

echo ''
echo "=============================================="
echo "Show permissions on /opt/olxc Staging Area ...     "
echo "=============================================="
echo ''

sleep 5

ls -lR /opt/olxc/"$DistDir"/"$SubDirName"

echo ''
echo "=============================================="
echo "Done: Show permissions on /opt/olxc Staging Area   "
echo "=============================================="
echo ''

sleep 5

clear

/opt/olxc/"$DistDir"/anylinux/anylinux-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $NumCon $MultiHost $LxcOvsVersion $DistDir $Product $SubDirName $Sx1Net $Sw1Net
	
exit
