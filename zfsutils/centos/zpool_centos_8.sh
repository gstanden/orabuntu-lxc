#!/bin/bash

# Usage:  ./zpool_centos_8.sh [olxc-001|olxc-002|olxc-003|...]

clear

echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
echo "                                              "
echo "(some steps take awhile ... patience)         " 
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

sudo yum -y install yum-utils
sudo dnf -y install epel-release
sudo yum config-manager --enable epel
sudo dnf install -y  http://download.zfsonlinux.org/epel/zfs-release.el8_4.noarch.rpm
rpm -qa | grep zfs
sudo dnf install -y kernel-devel zfs
sudo modprobe zfs
sudo systemctl list-unit-files | grep zfs

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
echo "=============================================="
echo ''

sleep 5

echo ''
echo "=============================================="
echo "Create ZFS Storage...                         "
echo "=============================================="
echo ''

sudo zpool create $1 mirror /dev/sdb /dev/sdc

sudo zpool list
sudo zpool status

echo ''
echo "=============================================="
echo "Done: Create ZFS Storage.                     "
echo "=============================================="
echo ''
