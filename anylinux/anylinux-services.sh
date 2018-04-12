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
#
#    Controlling script for Orabuntu-LXC

#    Host OS Supported: Oracle Linux 7, RedHat 7, CentOS 7, Fedora 27, Ubuntu 16/17

#    Usage:
#    Passing parameters in from the command line is possible but is not described herein. The supported usage is to configure this file as described below.

#    Create a non-root linux user account that has "SUDO ALL" full administrative privileges
#    Unpack the distribution from github in the "~/Downloads" directory of th user with 'SUDO ALL' privilege.
#    Configure this script and then run "./anylinux-services.sh"

#    All of the following parameters are user-settable.
#    
#    U = User MUST set before running anylinux-services.sh
#    D = User MAY  set before running anylinux-services.sh (DEFAULT VALUES ALREADY SET CAN BE USED)

#    U	SudoPassword    
#    D	GRE		[ N|Y ]
#    D	MajorRelease	[ 7         | 6                   | 5                         | 4           ]
#    D	PointRelease	[ {4,3,2,1} | {9,8,7,6,5,4,3,2,1} | {11,10,9,8,7,6,5,4,3,2,1} | {8,7,6,5,4} ]
#    D	NumCon		[ 2 | Integer > 0 ]
#    D	Domain1		[ urdomain1.com | some-domain1.{com|us|biz|org|info|...} ] (hyphen in domain is OK but NOT required)
#    D	Domain2		[ urdomain2.com | some-domain2.{com|us|biz|org|info|...} ] (hyphen in domain is OK but NOT required)
#    D	NameServer 	[ olive | nameserver ]
#    D	OSMemRes	[ 1024  | Linux OS Memory Reservation (in Kb) ]
#    D	MultiHost	[ new|reinstall|addclones|addrelease ]:[Y|N]:[1|X]:[$SudoPassword]:[Hub-IP|X]:[Spoke-IP|X]:[MTU]:[Hub-SudoPassword|X]:[Spoke-SudoPassword|X]:[Y|N]
#
#    LEGEND MultiHost:
#			[new|reinstall|addclones|addrelease]	Installation mode of Orabuntu-LXC	
#									new	   always used for first Orabuntu-LXC host (physical or VM).
#									reinstall  always used for reinstalling Orabuntu-LXC on any host
#									addclones  add additional containers of a release that ALREADY has an Orabuntu-LXC seed container of that version installed
#									addrelease add container release (for example add Oracle Linux 5.9 containers to a deployment of Oracle Linux 7.3 containers)
#			[N|Y]					multihost flag
#									N always used to install first Orabuntu-LXC host (physical or VM). The first Orabuntu-LXC host is called a "Hub"
#									Y always used to install added Orabuntu-LXC host (physical or VM). The added Orabuntu-LXC host is called a "spoke"
#			[1|X]					IP address 4th triplet flag
#									1 always used to install first Orabuntu-LXC host (physical or VM).
#									X always used to install added Orabuntu-LXC host (physical or VM). Note that 'X' is a LITERAL value NOT a variable.
#			[$SudoPassword]				sudo password of the 'ubuntu' linux account of this local host.  
#									Note 'ubuntu' user for all Orabuntu-LXC hosts must have SUDO ALL privilege.  Tuning of SUDO privs is coming.
#			[X:Hub-IP]				The LAN IP of the first Orabuntu-LXC host (physical or VM)
#									Hub-IP always used to install added Orabuntu-LXC GRE phys host. Note that 'Hub-IP' is a LAN address e.g. 192.168.1.42
#									X always used to install first Orabuntu-LXC VMs if running on Orabuntu-LXC physical host. Note 'X' is a LITERAL NOT a variable.
#									X always used to install added Orabuntu-LXC VMs if running on Orabuntu-LXC physical host. Note 'X' is a LITERAL NOT a variable.
#			[X:Spoke-IP]				The LAN IP of the added Orabuntu-LXC host (physical or VM)
#								Spoke-IP always used to install added Orabuntu-LXC GRE phys host. Note that 'Hub-IP' is a LAN address e.g. 192.168.1.69
#									X always used to install first Orabuntu-LXC VMs if running on Orabuntu-LXC physical host. Note 'X' is a LITERAL NOT a variable.
#									X always used to install added Orabuntu-LXC VMs if running on Orabuntu-LXC physical host. Note 'X' is a LITERAL NOT a variable.
#			[1500]					The MTU that will be used for the OpenvSwitch infrastructure deployment. Typical values are {1420, 1500, 8920, 9000}
#									MTU use 1500 for first Orabuntu-LXC host (physical or VM) aka "hub" host
#									MTU use 1420 for added Orabuntu-LXC host (physical)       aka "gre" host
#									MTU use 1500 for added Orabuntu-LXC host (VM) if running on HUB   Orabuntu-LXC first physical host
#									MTU use 1420 for added Orabuntu-LXC host (VM) if running on SPOKE Orabuntu-LXC added physical host
#									MTU 8920/9000 not tested with this software but could be configured via manual edits to the files. Support on roadmap for MTU 9000.
#			[X:Hub-SudoPassword]			sudo password of the 'ubuntu' linux account of the first Orabuntu-LXC host
#									Hub-SudoPassword always used to install added Orabuntu-LXC phys host (GRE-connected host).
#									X always used to install first Orabuntu-LXC host.
#									X always used to install added Orabuntu-LXC VM host.
#			[X:Spoke-SudoPassword]			sudo password of the 'ubuntu' linux account of the added Orabuntu-LXC host
#									Spoke-SudoPassword always used to install added Orabuntu-LXC phys host (GRE-connected host).
#									X always used to install first Orabuntu-LXC host.
#									X always used to install added Orabuntu-LXC VM host.
#			[N|Y]					GRE Flag
#									N always used to install first Orabuntu-LXC host.
#									N always used to install added Orabuntu-LXC host (VMs)
#									Y always used to install added Orabuntu-LXC host (physical)(GRE-connected host)
#
#	MultiHost Note 1:  MultiHost default value:	MultiHost="new:N:1:$SudoPassword:X:X:1500:X:X:$GRE" (this value is uncommented in the default distribution of Orabuntu-LXC)
			
#	Subnets (See subnets section below for more information)
#
#    D	SeedNet1
#    D	BaseNet1
#    D	StorNet1
#    D	StorNet2
#    D	ExtrNet1
#    D	ExtrNet2
#    D	ExtrNet3
#    D	ExtrNet4
#    D	ExtrNet5
#    D	ExtrNet6

# Set these before running anylinux-services.sh
# Leave GRE set to N for first Orabuntu-LXC host install

sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D'  /etc/resolv.conf

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

	SeedNet1='SeedNet1Fwd:172.29.108'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	BaseNet1='BaseNet1Fwd:10.209.53'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	StorNet1='StorNet1Fwd:10.210.107'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	StorNet2='StorNet2Fwd:10.211.107'	# UNCOMMENT LINE IF USING CUSTOM SUBNETS

	ExtrNet1='172.26.11'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	ExtrNet2='172.27.11'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	ExtrNet3='192.168.19'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	ExtrNet4='192.168.20'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	ExtrNet5='192.168.21'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS
	ExtrNet6='192.168.22'			# UNCOMMENT LINE IF USING CUSTOM SUBNETS

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
	SubDirName=uekulele
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                function GetRedHatVersion {
                        sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
                }
                RedHatVersion=$(GetRedHatVersion)
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
                RedHatVersion=$(GetRedHatVersion)
        fi
        RHV=$RedHatVersion
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
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
	SubDirName=uekulele
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
fi

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
	echo ''
	echo "Acknowledgements"
	echo ''
	echo "1.  Mary Standen		(mother) (1934-2016)"
	echo "2.  Yelena Belyaeva-Standen 	(spouse)"
	echo "3.  Allen the Cat 		(cat)"
	echo ''
	echo "For their patience and support during the long hours worked in the past and the long hours to be worked in the future for Orabuntu-LXC."
	echo "Mary Standen my mother always raised me to put mission first and work first."
	echo ''
	echo "=============================================="
	echo "References and Acknowledgements End           "
	echo "=============================================="
	echo ''

	sleep 5

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

if [ $LinuxFlavor != 'Ubuntu' ] && [ $LinuxFlavor != 'Pop_OS' ]
then
	echo ''
	echo "==============================================" 
	echo "Install libvirt ...                           "
	echo "=============================================="
	echo ''

	sleep 5

	sudo yum -y install libvirt

	echo ''
	echo "==============================================" 
	echo "Done: Install libvirt ...                     "
	echo "=============================================="

	sleep 5

	clear
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
		MajorRelease=6
	fi
	# echo 'Oracle Container Release  = '$MajorRelease

	PointRelease=$2
	if [ -z $2 ]
	then
		PointRelease=6
	fi
	echo 'Oracle Container Version  = '$MajorRelease.$PointRelease

	NumCon=$3
	if [ -z $3 ]
	then
		NumCon=3
	fi
	echo 'Oracle Container Count    = '$NumCon

	Domain1=$4
	if [ -z $4 ]
	then
		Domain1=urdomain1.com
	fi
	echo 'Domain1                   = '$Domain1

	Domain2=$5
	if [ -z $5 ]
	then
		Domain2=urdomain2.com
	fi
	echo 'Domain2                   = '$Domain2

	NameServer=$6
	if [ -z $6 ]
	then
		NameServer=afns1
	fi
	echo 'NameServer                = '$NameServer

	OSMemRes=$7
	if [ -z $7 ]
	then
		OSMemRes=1024
	fi
	echo 'OSMemRes                  = '$OSMemRes 

# pgroup2 end
# user-settable parameters group 2 end

MultiHost=$1
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
                	LxcOvsVersion="2.0.8:2.5.4"
	fi

	# Fedora MUST leave Lxc version at 2.0.9 but can change Ovs version.

	if [ -z $9 ] && [ $LinuxFlavor = 'Fedora' ]
	then
		if [ $RedHatVersion -eq 27 ]
		then
			LxcOvsVersion="2.0.9:2.5.4"  # Do NOT change 2.0.9 version of LXC here.  Must use 2.0.9 for now.
		fi
	fi

# pgroup3 end
# user-settable parameters group 3 end

if   [ $LinuxFlavor = 'RedHat' ] || [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Fedora' ]
then
	echo 'LxcOvsVersion             = '$LxcOvsVersion
elif [ $LinuxFlavor = 'Oracle' ]
then
	echo 'LxcOvsVersion             = '$LxcOvsVersion
elif [ $LinuxFlavor = 'Ubuntu' ]
then
	echo 'LxcOvsVersion             = Latest Canonical Repository Version (via apt-get)'
fi

function GetGREValue {
	echo $MultiHost | cut -f10 -d':'
}
GREValue=$(GetGREValue)

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
        
	Sx1Index=201
        function CheckHighestSx1IndexHit {
        	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" nslookup -timeout=1 $Sx1Net.$Sx1Index" | grep -c 'name =' 
        }
        HighestSx1IndexHit=$(CheckHighestSx1IndexHit)

        while [ $HighestSx1IndexHit = 1 ]
        do
                Sx1Index=$((Sx1Index+1))
                HighestSx1IndexHit=$(CheckHighestSx1IndexHit)
        done

        Sw1Index=201
        function CheckHighestSw1IndexHit {
        	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" nslookup -timeout=1 $Sw1Net.$Sw1Index" | grep -c 'name ='
        }
        HighestSw1IndexHit=$(CheckHighestSw1IndexHit)

        while [ $HighestSw1IndexHit = 1 ]
        do
                Sw1Index=$((Sw1Index+1))
                HighestSw1IndexHit=$(CheckHighestSw1IndexHit)
        done
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
	echo 'RPM libvirt installed     = '`rpm -qa | grep libvirt | grep -v client`
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

			sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServer -k;echo '(Do NOT enter password...Wait...)'"
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
			echo ''

			sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServer -k;echo '(Do NOT enter a password.  Wait...)'; echo '$HOSTNAME pre-install nameserver snapshot' > snap_comment; echo ''; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -c snap_comment; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sleep 5; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -L -C"
			echo ''
			echo "Snapshot of $NameServer created on the Orabuntu-LXC HUB host at $MultiHostVar5."
			echo "Snapshot of $NameServer can be restored to $NameServer if necessary using 'lxc-snapshot -r SnapX -N $NameServer' command."
			sudo rm -f snap_comment

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

		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" lxc-stop -n $NameServer -k;echo '(Do NOT enter a password.  Wait...)'; echo '$HOSTNAME pre-install nameserver snapshot' > snap_comment; echo ''; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -c snap_comment; sudo -S <<< "$MultiHostVar9" lxc-start -n $NameServer; echo ''; sleep 5; sudo -S <<< "$MultiHostVar9" lxc-snapshot -n $NameServer -L -C"
		echo ''
		echo "Snapshot of $NameServer created on the Orabuntu-LXC HUB host at $MultiHostVar5."
		echo "Snapshot of $NameServer can be restored to $NameServer if necessary using 'lxc-snapshot -r SnapX -N $NameServer' command."
		sudo rm -f snap_comment

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

sudo rm  -f /opt/olxc/GNU3
sudo rm -rf /opt/olxc/home

cp -p $DistDir/anylinux/GNU3 /opt/olxc/GNU3

echo "$DistDir/anylinux/vercomp" 						>  "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/anylinux/anylinux-services-1.sh" 				>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/anylinux/dnf2yum" 						>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/archives/nameserver_copy.sh" 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/archives/docker_install_$SubDirName.sh" 		>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-0.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-1.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-2.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-3.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-4.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/$SubDirName-services-5.sh"	 			>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/GNU3"                                                >> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/$SubDirName/COPYING"                                             >> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst
echo "$DistDir/products/$Product"						>> "$DistDir"/"$SubDirName"/archives/"$SubDirName"-services.lst

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
sudo chmod 775 /opt/olxc/"$DistDir"/products/$Product
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
