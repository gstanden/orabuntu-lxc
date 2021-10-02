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
echo "Configure Required Repos ...                  "
echo "=============================================="
echo ''

sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum config-manager --enable epel
source /etc/os-release
sudo dnf install https://zfsonlinux.org/epel/zfs-release.el${VERSION_ID/./_}.noarch.rpm
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

echo ''
echo "=============================================="
echo "Done: Configure Required Repos.               "
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
sudo dnf -y install kernel-devel gpg
sudo dnf -y install zfs

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Verify ZFS Install...                         "
echo "=============================================="
echo ''

sudo modprobe zfs
sudo systemctl list-unit-files | grep zfs


echo ''
echo "=============================================="
echo "Done: Verify ZFS Install.                     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Create ZFS Storage...                         "
echo "=============================================="
echo ''

sudo zpool create $1 mirror /dev/sdb /dev/sdc

echo ''
echo "=============================================="
echo "Create ZFS Storage...                         "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Verify ZFS Pool...                            "
echo "=============================================="
echo ''

sudo zpool list
sudo zpool status

echo ''
echo "=============================================="
echo "Done: Verify ZFS Pool.                        "
echo "=============================================="
echo ''
echo "=============================================="
echo "Done: Create ZFS Storage.                     "
echo "=============================================="
echo ''
