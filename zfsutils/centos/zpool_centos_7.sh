#!/bin/bash

# Usage:  ./zpool_centos_8.sh [olxc-001|olxc-002|olxc-003|...]

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
echo "Install packages ...                          "
echo "=============================================="
echo ''

sudo yum -y install unzip wget openssh-server net-tools bind-utils
sudo yum -y install epel-release gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-devel-$(uname -r) python python2-devel python-setuptools python-cffi libffi-devel git ncompress

echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Enable required repos ...                     "
echo "=============================================="
echo ''

sudo yum -y install --enablerepo=epel python-packaging dkms

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


