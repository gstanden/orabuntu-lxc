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

# Usage:  ./zpool_centos_8.sh

clear

echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
echo "CentOS7 OpenZFS build/install rpm from source."
echo "                                              "
echo "(rpm build takes awhile ... patience)         " 
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install packages ...                          "
echo "=============================================="
echo ''

sudo yum -y update
sudo yum -y install net-tools wget unzip tar
sudo yum -y install epel-release
sudo dnf -y --enablerepo=powertools install python3-packaging
sudo yum -y update
sudo yum -y install epel-release gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python3 python3-devel python3-setuptools python3-cffi libffi-devel git ncompress perl bc cpio sysstat mdadm ksh fio

echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Enable required repos ...                     "
echo "=============================================="
echo ''

sudo yum -y install --enablerepo=epel python3-packaging dkms

echo ''
echo "=============================================="
echo "Done: Enable required repos.                  "
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
echo "Install packages ...                          "
echo "=============================================="
echo ''

sudo yum -y install sysstat mdadm ksh fio

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
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
echo "Finish OpenZFS configuration...               "
echo "=============================================="
echo ''

sudo modprobe zfs
sudo lsmod | grep zfs
sudo systemctl list-unit-files | grep zfs

echo ''
echo "=============================================="
echo "Done: Finish OpenZFS configuration.           "
echo "=============================================="
echo ''

sleep 5

clear
