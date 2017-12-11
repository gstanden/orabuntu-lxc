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

#    Controlling script for orabuntu-lxc
#    Gilbert Standen 20151224 gilstanden@hotmail.com

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
#    v5.0 GLS 20170909 uekulele multihost for Oracle Linux 

SudoPassword=ubuntu
GRE=N

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
	LF=$LinuxFlavor
	RL=$Release
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
	#MultiHost="new:N:1:$SudoPassword:192.168.1.82:192.168.1.93:1500:ubuntu:ubuntu:$GRE"
	 MultiHost="new:Y:6:$SudoPassword:10.207.39.15:10.207.39.16:1500:ubuntu:ubuntu:$GRE"
	#MultiHost="reinstall:N:1:$SudoPassword:192.168.1.32:192.168.1.68:1500:ubuntu:ubuntu:$GRE"
	#MultiHost="reinstall:Y:4:$SudoPassword:192.168.1.32:192.168.1.68:1500:ubuntu:ubuntu:$GRE"
	#MultiHost="addclones"
fi
echo 'MultiHost                 = '$MultiHost

# GLS 20170924 Currently Orabuntu-LXC for Ubuntu Linux just uses the LXC package(s) provided by Canonical Ltd. and does not have an option to build LXC from source.
# GLS 20170924 Including an option to upgrade LXC from source over the Canonical LXC packages on Ubuntu Linux is on the roadmap but not yet available.
# GLS 20170924 Currently Orabuntu-LXC for Oracle Linux does build LXC from source.  You can use this parameter to set what version it will build.

LxcOvsVersion=$9
if [ -z $9 ]
then
	LxcOvsVersion="2.1.1:2.5.4"
fi
if   [ $LinuxFlavor = 'RedHat' ]
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

sleep 10

clear

/home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/anylinux-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $NumCon $MultiHost $LxcOvsVersion

exit


