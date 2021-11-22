#!/bin/bash

# Usage:  ./zpool_oracle7_uek.sh [olxc-001|olxc-002|olxc-003|...]

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

sudo yum -y install kernel-uek-devel-$(uname -r) kernel-devel yum-utils
sleep 5
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum-config-manager --enable ol7_developer_EPEL
sudo yum repolist
sudo yum -y install dkms
sudo rpm -Uvh http://download.zfsonlinux.org/epel/zfs-release.el`cat /etc/oracle-release | cut -f5 -d' ' | sed 's/\./_/'`.noarch.rpm

sleep 5

sudo yum -y install -y zfs
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

