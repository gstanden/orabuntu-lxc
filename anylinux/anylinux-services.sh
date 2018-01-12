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

#    v2.4 	GLS 20151224
#    v2.8 	GLS 20151231
#    v3.0 	GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 	GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 	GLS 20170909 Orabuntu-LXC MultiHost
#    v5.33-beta	GLS 20180106 Orabuntu-LXC EE MultiHost Docker AWS S3

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet though (a feature this software does not yet support - it's on the roadmap) to match your subnet manually.

#    Controlling script for orabuntu-lxc

#    Usage:

#    /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services.sh MajorRelease MinorRelease NumCon yourdomain1.com yourdomain2.com YourNewNameserver OSMemRes(Kb

#    Example
#    /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services.sh $1 $2 $3 $4            $5                $6      $7  
#    /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services.sh  7  3  4  urdomain1.com urdomain2.com     olive   1024

#    Example explanation:

#    Create containers with Oracle Enterprise Linux 7.3 OS version.
#    Create four clones of the seed (oel73) container.                      The clones will be named {ora73c10, ora73c11, ora73c12, ora73c13}.
#    Define the domain for cloned containers as "urdomain1.com".            Be sure to include backslash before any "." dots.
#    Define the domain for   seed containers as "urdomain2.com".            Be sure to include backslash before any "." dots.
#    Define the nameserver for the "urdomain1.com" domain to be "olive".  (FQDN:  "olive.urdomain1.com").
#    Define MultiHost:  

#	For new install on 1st host:  MultiHost='new:N:1:0' ([Operation][MultiHost][SwitchIP][BumpIndex][Host1-IP][Host2-IP]
#	For reinstall   on 1st host:  MultiHost='reinstall:N:1'
#	For addclone    on 1st host:  MultiHost='addclones:N:1'

#	For new install on 2nd host:  MultiHost='new:Y:4:<ipaddr of 1st host>:<ipaddr of 2nd host>'
#	For reinstall   on 2nd host:  MultiHost='reinstall:Y:4:<ipaddr of 1st host>:<ipaddr of 2nd host>'
#	For new install on 2nd host:  MultiHost='addclones:Y:4:<ipaddr of 1st host>:<ipaddr of 2nd host>'

#    Oracle Enteprise Linux OS versions OEL5, OEL6, and OEL7 are currently supported.

#    v2.4 GLS 20151224
#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container
#    v4.4 GLS 20170609 Enhancements to clone additional functionality and multiple host
#    v5.0 GLS 20170909 EE MultiHost Docker S3

SudoPassword=ubuntu

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
	echo "References and Acknowledgements orabuntu-lxc  "
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
	echo 'The online publications of many authors and bloggers helped to make orabuntu-lxc possible.'
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

echo ''
echo "=============================================="
echo "Display Installation Parameters ...           "
echo "=============================================="
echo ''

echo 'Linux Flavor              = '$LinuxFlavor    
echo 'Linux Release             = '$RedHatVersion
echo 'Linux Base Release        = '$Release
MajorRelease=$1
if [ -z $1 ]
then
	MajorRelease=7
fi
echo 'Oracle Linux MajorRelease = '$MajorRelease

PointRelease=$2
if [ -z $2 ]
then
	PointRelease=3
fi
echo 'Oracle Linux PointRelease = '$PointRelease

NumCon=$3
if [ -z $3 ]
then
	NumCon=2
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
	NameServer=olive
fi
echo 'NameServer                = '$NameServer

OSMemRes=$7
if [ -z $7 ]
then
	OSMemRes=1024
fi
echo 'OSMemRes                  = '$OSMemRes 

MultiHost=$8
if [ -z $8 ]
then

	# Set the GRE value to [ Y or N ].
	# GRE is always 'N' on the first Orabuntu-LXC host install.
	
	GRE=N

	# In this section below you uncomment the MultiHost parameter for the specific use case as described below.
	# Better documentation is coming soon.

	# ('X' means value is not used so just leave it set to 'X')

	# First Orabuntu-LXC host (physical or virtual):
	# (Note:  values for first Orabuntu-LXC host should normally not be changed from the following)

	#MultiHost="new:N:1:$SudoPassword:X:X:1500:X:X:$GRE"
	#MultiHost="reinstall:N:1:$SudoPassword:X:X:1500:X:X:$GRE"

	# Additional Orabuntu-LXC physical hosts (physical or virtual  hosts over GRE):
	# (Note: reading from left to right the first IP is the First Orabuntu-LXC host (MTU 1500) and the second IP is the Orabuntu-LXC GRE host (MTU 1420)
	# (Note: the passwords in the 8 and 9 fields are the "ubuntu" user with password "ubuntu" on the remote GRE host).
	# (Note: for now, you MUST use the "ubuntu" user on the remote GRE host with password "ubuntu" also).

	#MultiHost="new:Y:X:$SudoPassword:192.168.1.10:192.168.1.16:1420:ubuntu:ubuntu:$GRE"
	#MultiHost="reinstall:Y:X:$SudoPassword:192.168.1.10:192.168.1.5:1420:ubuntu:ubuntu:$GRE"

	# Additional Orabuntu-LXC virtual hosts (VM is on an Orabuntu-LXC physical host AND VM is on the Orabuntu-LXC OpenvSwitch network):

		# VM is on the first Orabuntu-LXC physical host (MTU 1500):
		# (Note: Set GRE to "N" in this use case).

		#MultiHost="new:Y:X:$SudoPassword:X:X:1500:X:X:$GRE"
		#MultiHost="reinstall:N:X:$SudoPassword:X:X:1500:X:X:$GRE"

		# VM is on a GRE Orabuntu-LXC hosts (physical or virtual) (MTU 1420):
		# (Note: Set GRE to "N" in this use case).

		 MultiHost="new:Y:X:$SudoPassword:X:X:1420:X:X:$GRE"
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

LxcOvsVersion=$9
if [ -z $9 ]
then
	LxcOvsVersion="2.0.5:2.5.4"
fi
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

echo 'GRE                       = '$GRE

echo ''
echo "=============================================="
echo "Display Installation Parameters complete.     "
echo "=============================================="

sleep 5

clear

function GetMultiHostVar7 {
	echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)

if [ $MultiHostVar7 -ne 1500 ]
then
	function GetVirtualInterfaces {
       		ifconfig | grep enp | cut -f1 -d':' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	VirtualInterfaces=$(GetVirtualInterfaces)
	subnet="10.207.29 10.207.39"
	for j in $subnet
	do
       		for i in $VirtualInterfaces
       		do
                	function CheckVirtualInterfaceMtu {
                        	ifconfig $i | grep -B1 "$j" | grep mtu | cut -f5 -d' '
                	}
                	VirtualInterfaceMtu=$(CheckVirtualInterfaceMtu)
                	function GetCharCount {
                        	echo $VirtualInterfaceMtu | wc -c
                	}
                	CharCount=$(GetCharCount)
                	if [ $CharCount -eq 5 ]
                	then
#                        	if [ $VirtualInterfaceMtu -ne 1420 ]
#                        	then
					echo ''
					echo "=============================================="
					echo "Set NIC $i to MTU $MultiHostVar7...           "
					echo "=============================================="
					echo ''

                                	sudo ifconfig $i mtu 1420
					ifconfig $i

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

					sudo sh -c "echo '[Unit]'					 > /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'Description=$i-mtu'				>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'After=network-online.target'			>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo ''						>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo '[Service]'					>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'Type=idle'					>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'User=root'					>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'RemainAfterExit=yes'				>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'ExecStart=/usr/sbin/ifconfig $i mtu 1420'	>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'ExecStop=/usr/sbin/ifconfig $i mtu 1500'	>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo ''						>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo '[Install]'					>> /etc/systemd/system/$i-mtu.service"
					sudo sh -c "echo 'WantedBy=network-online.target'		>> /etc/systemd/system/$i-mtu.service"
					sudo systemctl enable $i-mtu.service
					sudo systemctl daemon-reload
					sudo cat /etc/systemd/system/$i-mtu.service

					echo ''
					echo "=============================================="
					echo "Done: Create $i-mtu manager systemd service.  "
					echo "=============================================="

					sleep 5

					clear
#                        	fi
                	fi
        	done
	done
fi

if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -ge 22 ]
then
	echo ''
	echo "=============================================="
	echo "Set Package Manager dnf $LinuxFlavor $RL.     "
	echo "=============================================="
	echo ''

	sudo sed -i "s/yum -y install/dnf -y install/g" 			/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh
	sudo sed -i "s/yum -y erase/dnf -y erase/g" 				/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh
	sudo sed -i "s/yum -y localinstall/dnf -y localinstall/g" 		/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh
	sudo sed -i "s/yum clean all/dnf clean all/g" 				/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh
	sudo sed -i "s/yum provides/dnf provides/g" 				/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh
	sudo sed -i "s/yum-utils/dnf-utils/g" 					/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh
	sudo sed -i "s/yum -y install/dnf -y install/g"				/home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services-1.sh
	sudo sed -i "s/yum-utils/dnf-utils/g"					/home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services-1.sh
	sudo sed -i "s/yum-complete-transaction/dnf-complete-transaction/g"	/home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services-1.sh
	grep yum 								/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/uekulele-services-[012345].sh | egrep -v 'yum.repos.d|yum.oracle.com'
	
	echo ''
	echo "=============================================="
	echo "Done: Set Package Manager dnf $LinuxFlavor $RL"
	echo "=============================================="
	echo ''
		
	sleep 5

	clear
fi

/home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $NumCon $MultiHost $LxcOvsVersion

exit


