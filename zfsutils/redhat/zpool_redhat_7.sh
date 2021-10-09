#!/bin/bash
#
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
#    v7.0-ELENA-beta    GLS 20210428 Enterprise LXD Edition New AMIDE

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC

# Usage:  ./zpool_redhat_7.sh [olxc-001|olxc-002|olxc-003|...] (or use your own ZFS pool naming scheme)

clear

PoolName=$1

function CheckZpoolExists {
	sudo zpool list | grep -c $PoolName
}
ZpoolExists=$(CheckZpoolExists)

if [ $ZpoolExists -ne 0 ]
then
	clear
	echo ''
	echo "=============================================="
	echo "The zpool $PoolName already exists:           "
	echo ''
	sudo zpool list
	echo ''
	echo "Change zpool name or destroy existing zpool:  "
	echo ''
	echo "(sudo zpool destroy $PoolName)                "
	echo ''
	echo "Script is exiting ...                         "
	echo "=============================================="
	echo ''
	exit
fi

echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
echo "RedHat OpenZFS build/install rpm from source."
echo "                                              "
echo "(rpm build takes awhile ... patience)         " 
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Establish sudo...                             "
echo "=============================================="
echo ''

trap "exit" INT TERM; trap "kill 0" EXIT; sudo -v || exit $?; sleep 1; while true; do sleep 60; sudo -nv; done 2>/dev/null &
sudo date

echo ''
echo "=============================================="
echo "Done: Establish sudo.                         "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Get EPEL latest ...                           "
echo "=============================================="
echo ''

function CheckEpelInstalled {
	rpm -qa | grep -c epel-release
}
EpelInstalled=$(CheckEpelInstalled)

if [ $EpelInstalled -eq 0 ]
then
	n=1
	Epel1=1
	while [ $Epel1 -ne 0 ] && [ $n -le 5 ]
	do
		sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
		Epel1=`echo $?`
		n=$((n+1))
		sleep 5
	done
else
	sudo rpm -qa | grep epel-release
fi

echo ''
echo "=============================================="
echo "Done: Get EPEL latest.                        "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "EPEL install python-packaging & dkms ...      "
echo "=============================================="
echo ''

n=1
Dkms1=1
while [ $Dkms1 -ne 0 ] && [ $n -le 5 ]
do
	sudo yum -y install --enablerepo=epel python-packaging dkms
	Dkms1=`echo $?`
	n=$((n+1))
	sleep 5
done

echo ''
echo "=============================================="
echo "Done: EPEL install python-packaging & dkms    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Enable OPTIONAL and EXTRA repos...            "
echo "=============================================="
echo ''

sudo subscription-manager repos --enable rhel-7-server-optional-rpms --enable rhel-7-server-extras-rpms
OpEx1=`echo $?`
if [ $OpEx1 -ne 0 ]
then
	echo 'There appears to be an issue with your RedHat subscription configuration.'
	echo 'Read README.redhat in this directory and correct RedHat subscription issue, then rerun this script.'
	echo 'Exiting this script ...'
	exit
fi

echo ''
echo "=============================================="
echo "Enable OPTIONAL and EXTRA repos...            "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install Group 1 packages ...                  "
echo "=============================================="
echo ''

n=1
Grp1=1
while [ $Grp1 -ne 0 ] && [ $n -le 5 ]
do
	sudo yum -y install unzip wget openssh-server net-tools bind-utils
	Grp1=`echo $?`
	n=$((n+1))
	sleep 5
done

if [ $Grp1 -ne 0 ]
then
	echo 'Install Group 1 packages failed ...'
	echo 'Fix issue and retry zpool_redhat_7.sh'
	echo 'Exiting script ...'
	exit
fi

echo ''
echo "=============================================="
echo "Done: Install Group 1 packages.               "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install Group 2 packages ...                  "
echo "=============================================="
echo ''

n=1
Grp2=1
while [ $Grp2 -ne 0 ] && [ $n -le 5 ]
do
	sudo yum -y install gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel 
	Grp2=`echo $?`
	n=$((n+1))
	sleep 5
done

if [ $Grp2 -ne 0 ]
then
	echo 'Install Group 2 packages failed ...'
	echo 'Fix issue and retry zpool_redhat_7.sh'
	echo 'Exiting script ...'
	exit
fi

echo ''
echo "=============================================="
echo "Done: Install Group 2 packages.               "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install Group 3 packages ...                  "
echo "=============================================="
echo ''

n=1
Grp3=1
while [ $Grp3 -ne 0 ] && [ $n -le 5 ]
do
	sudo yum -y install zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python python2-devel python-setuptools python-cffi libffi-devel git ncompress
	Grp3=`echo $?`
	n=$((n+1))
	sleep 5
done

if [ $Grp3 -ne 0 ]
then
	echo 'Install Group 3 packages failed ...'
	echo 'Fix issue and retry zpool_redhat_7.sh'
	echo 'Exiting script ...'
	exit
fi

echo ''
echo "=============================================="
echo "Done: Install Group 3 packages.               "
echo "=============================================="
echo ''

sleep 5

clear

if [ ! -d zfs ]	
then
 	echo ''
	echo "=============================================="
	echo "Clone OpenZFS git repo...                     "
	echo "=============================================="
	echo ''

	n=1
	Git1=1
	while [ $Git1 -ne 0 ] && [ $n -le 5 ]
	do
		git clone https://github.com/openzfs/zfs
		Git1=`echo $?`
		n=$((n+1))
		sleep 5
	done

	if [ $Git1 -ne 0 ]
	then
		echo 'git clone ZFS failed ...'
		echo 'Fix issue and retry zpool_redhat_7.sh'
		echo 'Exiting script ...'
		exit
	fi
fi

cd ./zfs

n=1
Git2=1
while [ $Git2 -ne 0 ] && [ $n -le 5 ]
do
	git checkout master >/dev/null 2>&1
	Git2=`echo $?`
	n=$((n+1))
	sleep 5
done

if [ $Git2 -ne 0 ]
then
	echo 'git checkout ZFS failed ...'
	echo 'Fix issue and retry zpool_redhat_7.sh'
	echo 'Exiting script ...'
	exit

	echo ''
	echo "=============================================="
	echo "Done: Clone OpenZFS git repo.                 "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

function GetRpmCount {
	ls -l *.rpm 2>/dev/null | grep -cv src
}
RpmCount=$(GetRpmCount)

which zpool >/dev/null 2>&1
ZpCmp=`echo $?`

if [ $ZpCmp -ne 0 ] && [ $RpmCount -lt 15 ]
then
	echo ''
	echo "=============================================="
	echo "Run autogen and configure...                  "
	echo "=============================================="
	echo ''

	sh autogen.sh
	Stat1=`echo $?`
	if [ $Stat1 -ne 0 ]
	then
		echo 'The autogen step failed.'
		echo 'Address issue and retry zpool_redhat_7.sh'
		exit
	fi

	./configure
	Stat2=`echo $?`
	if [ $Stat2 -ne 0 ]
	then
		echo 'The configure step failed.'
		echo 'Address issue and retry zpool_redhat_7.sh'
		exit
	fi

	echo ''
	echo "=============================================="
	echo "Done: Run autogen and configure.              "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "make rpm (takes a minute or two...patience)   "
	echo "=============================================="
	echo ''

	sleep 5

	make rpm
	Make1=`echo $?`
	if [ $Make1 -ne 0 ]
	then
		echo 'The make rpm step failed'
		echo 'Address issue and retry zpool_redhat_7.sh'
		exit
	fi

	echo ''
	echo "=============================================="
	echo "Done: make rpm.                               "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Install Group 4 packages ...                  "
echo "=============================================="
echo ''

n=1
Grp4=1
while [ $Grp4 -ne 0 ] && [ $n -le 5 ]
do
	sudo yum -y install sysstat mdadm ksh fio
	Grp4=`echo $?`
	n=$((n+1))
	sleep 5
done

echo ''
echo "=============================================="
echo "Done: Install Group 4 packages.               "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install OpenZFS packages (takes awhile...)    "
echo "=============================================="
echo ''

sudo rpm -ivh *.rpm

echo ''
echo "=============================================="
echo "Done: Install OpenZFS packages.               "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Run modprobe zfs and lsmod...                 "
echo "=============================================="
echo ''

sudo modprobe zfs
sudo lsmod | grep zfs

echo ''
echo "=============================================="
echo "Done: Run modprobe zfs and lsmod.             "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "List ZFS unit files...                        "
echo "=============================================="
echo ''

sudo systemctl list-unit-files | grep zfs

echo ''
echo "=============================================="
echo "Done: List ZFS unit files.                    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Create zpool...                               "
echo "=============================================="
echo ''

sudo zpool create $PoolName mirror /dev/sdb /dev/sdc
sudo zpool list

echo ''
echo "=============================================="
echo "Done: Create zpool.                           "
echo "=============================================="
echo ''


