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
echo "EPEL install python-packaging & dkms ...      "
echo "=============================================="
echo ''

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm --enablerepo=epel python-packaging dkms

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

sudo yum -y install unzip wget openssh-server net-tools bind-utils

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

sudo yum -y install gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel 

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

sudo yum -y install zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python python2-devel python-setuptools python-cffi libffi-devel git ncompress

echo ''
echo "=============================================="
echo "Done: Install Group 3 packages.               "
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
echo "Clone OpenZFS git repo...                     "
echo "=============================================="
echo ''

git clone https://github.com/openzfs/zfs
cd ./zfs
git checkout master

echo ''
echo "=============================================="
echo "Done: Clone OpenZFS git repo.                 "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Run autogen and configure...                  "
echo "=============================================="
echo ''

sh autogen.sh
./configure

echo ''
echo "=============================================="
echo "Done: Run autogen and configure.              "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "make rpm ...                                  "
echo "=============================================="
echo ''

sleep 5

make rpm

echo ''
echo "=============================================="
echo "Done: make rpm.                               "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install additional packages ...               "
echo "=============================================="
echo ''

sudo yum -y install sysstat mdadm ksh fio

echo ''
echo "=============================================="
echo "Done: Install additional packages.            "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install OpenZFS packages...                   "
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

sudo zpool create $1 mirror /dev/sdb /dev/sdc
sudo zpool list

echo ''
echo "=============================================="
echo "Done: Create zpool.                           "
echo "=============================================="
echo ''


