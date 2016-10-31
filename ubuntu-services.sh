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

# v2.4 GLS 20151224
# v2.8 GLS 20151231
# v3.0 GLS 20160710 Updates for Ubuntu 16.04
# v4.0 GLS 20161025 DNS DHCP services moved into an LXC container

clear

if [ ! -f /etc/orabuntu-lxc-release ]
then
	echo ''
	echo '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++'
	echo '"We have just folded space from Ix. Many machines on Ix. New machines. Better than those on Richesse."'
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
	echo 'gilstanden@hotmail.com'
	echo ''
	echo "=============================================="
	echo "The Orabuntu-LXC Github Project:              "
	echo "https://github.com/gstanden/orabuntu-lxc      " 
	echo "=============================================="
	echo ''
	echo 'The online publications of many authors and bloggers helped to make orabuntu-lxc possible.'
	echo 'Links may go stale.  I will try to keep them up to date if possible.'
	echo ''
	echo "1. 'The Unknown Posters' (i.e. StackExchangers, StackOverflowers, UnixStackExchangers, etc.)"
	echo "2. 'VirtualBox' Jean Jacques Sarton https://www.virtualbox.org/wiki/Advanced_Networking_Linux"
	echo "3. 'The New Stack' Venu Murthy http://thenewstack.io/solving-a-common-beginners-problem-when-pinging-from-an-openstack-instance/"
	echo "4. 'Big Dino' Lee Hutchinson https://blog.bigdinosaur.org/running-bind9-and-isc-dhcp/"
	echo "5. 'Techie in IT' Sokratis Galiatsis https://sokratisg.net/2012/03/31/ubuntu-precise-dnsmasq/"
	echo "6. 'OpenvSwitch Examples' Jaret Pfluger https://github.com/jpfluger/examples/blob/master/ubuntu-14.04/openvswitch.md"
	echo "7. 'Howto run local scripts on systemstartup and/or shutdown' xaos52 (The Good Doctor) http://crunchbang.org/forums/viewtopic.php?id=14453"
	echo ''
	echo "Acknowledgements"
	echo ''
	echo "1.  Mary Standen (mother)"
	echo "2.  Yelena Belyaeva-Standen (spouse)"
	echo ''
	echo "For their patience and support during the long hours worked in the past and the long hours to be worked in the future for Orabuntu-LXC."
	echo ''
	echo "=============================================="
	echo "References and Acknowledgements End           "
	echo "=============================================="
	echo ''

	sleep 10

	clear
fi

echo ''
echo "=============================================="
echo "Establish sudo privileges ...                 "
echo "=============================================="
echo ''

sudo date

echo ''
echo "=============================================="
echo "Establish sudo privileges successful.         "
echo "=============================================="
echo ''

sleep 5

clear

# Controlling script for orabuntu-lxc
# Gilbert Standen 20151224 gilstanden@hotmail.com

# Usage:

# ~/Downloads/orabuntu-lxc-master/ubuntu-services.sh MajorRelease MinorRelease NumCon yourdomain1.com yourdomain2.com YourNewNameserver LinuxOSMemoryReservation(Kb)

# Example
# ~/Downloads/orabuntu-lxc-master/ubuntu-services-sh $1 $2 $3  $4                $5              $6      $7
# ~/Downloads/orabuntu-lxc-master/ubuntu-services.sh  6  7  4  bostonlox.com realcrumpets.info p70ns01 1024

# Example explanation:

# Create containers with Oracle Enterprise Linux 6.7 OS version.
# Create four clones of the seed (oel67) container.  The clones will be named {ora67c10, ora67c11, ora67c12, ora67c13}.
# Define the domain for cloned containers as "orabuntu-lxc.com".  Be sure to include backslash before any "." dots.
# Define the nameserver for the "orabuntu-lxc.com" domain to be "stlns01" (FQDN:  "stlns01.orabuntu-lxc.com").

# Oracle Enteprise Linux OS versions OEL5, OEL6, and OEL7 are currently supported.

echo ''
echo "=============================================="
echo "Display Installation Parameters ...           "
echo "=============================================="
echo ''

if [ -z $1 ]
then
MajorRelease=7
fi
echo 'Oracle Linux MajorRelease = '$MajorRelease

if [ -z $2 ]
then
PointRelease=2
fi
echo 'Oracle Linux PointRelease = '$PointRelease

if [ -z $3 ]
then
NumCon=4
fi
echo '# of Oracle Containers    = '$NumCon

if [ -z $4 ]
then
Domain1=bostonlox.com
fi
echo 'Domain1                   = '$Domain1

if [ -z $5 ]
then
Domain2=realcrumpets.info
fi
echo 'Domain2                   = '$Domain2

if [ -z $6 ]
then
NameServer=bosns
fi
echo 'NameServer                = '$NameServer

if [ -z $7 ]
then
LinuxOSMemoryReservation=1024
fi
echo 'LinuxOSMemoryReservation  = '$LinuxOSMemoryReservation 

echo ''
echo "=============================================="
echo "Display Installation Parameters complete.     "
echo "=============================================="

sleep 5

clear

/bin/bash ~/Downloads/orabuntu-lxc-master/ubuntu-services-0.sh
clear
/bin/bash ~/Downloads/orabuntu-lxc-master/ubuntu-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $LinuxOSMemoryReservation
clear
/bin/bash ~/Downloads/orabuntu-lxc-master/ubuntu-services-2.sh $MajorRelease $PointRelease $Domain1
clear
/bin/bash ~/Downloads/orabuntu-lxc-master/ubuntu-services-3.sh $MajorRelease $PointRelease
clear
/bin/bash ~/Downloads/orabuntu-lxc-master/ubuntu-services-4.sh $MajorRelease $PointRelease $NumCon ora$MajorRelease$PointRelease
clear
/bin/bash ~/Downloads/orabuntu-lxc-master/ubuntu-services-5.sh $MajorRelease $PointRelease


