#!/bin/bash

clear

echo ''
echo "=============================================="
echo "Install ZFS...                                "
echo "                                              "
echo "(some steps take awhile ... patience)         " 
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
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum-config-manager --enable epel 
sudo yum repolist
sudo yum -y install dkms
sudo rpm -Uvh http://download.zfsonlinux.org/epel/zfs-release.el`cat /etc/oracle-release | cut -f5 -d' ' | sed 's/\./_/'`.noarch.rpm 2>/dev/null

sleep 5

sudo yum -y install zfs

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Verify packages ...                           "
echo "=============================================="
echo ''

sudo rpm -qa | grep zfs

echo ''
echo "=============================================="
echo "Done: Verify packages.                        "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "modprobe zfs and list-unit-files...           "
echo "=============================================="
echo ''

sudo modprobe zfs
sudo systemctl list-unit-files | grep zfs

echo ''
echo "=============================================="
echo "Done: modprobe zfs and list-unit-files.       "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Done: Install ZFS.                            "
echo "=============================================="
echo ''