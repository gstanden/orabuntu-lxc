#!/bin/bash

# Usage:  	./zpool_fedora_22.sh [olxc-001|olxc-002|olxc-003|...]

# Credits:	https://medium.com/@AndrzejRehmann/preparing-fedora-26-laptop-with-zfs-and-encryption-zfs-part-5-1e17820b40a4

clear

echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
echo "(should work for Fedora 22-29)                "
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
echo "Install packages...                           "
echo "=============================================="
echo ''

sudo dnf -y install gpg
sudo dnf -y install http://download.zfsonlinux.org/fedora/zfs-release$(rpm -E %dist).noarch.rpm

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
echo "=============================================="
echo ''

sleep 5

clear
 
echo ''
echo "=============================================="
echo "Configure gpg key...                          "
echo "=============================================="
echo ''

gpg --quiet --with-fingerprint /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
 
echo ''
echo "=============================================="
echo "Done: Configure gpg key.                      "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install packages ...                          "
echo "=============================================="
echo ''

sudo dnf -y install kernel-devel dkms
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
echo "Configure ZFS ...                             "
echo "=============================================="
echo ''

sudo systemctl preset zfs-import-cache zfs-import-scan zfs-mount zfs-share zfs-zed zfs.target
sudo dkms status
sudo modprobe zfs
sudo systemctl list-unit-files | grep zfs

echo ''
echo "=============================================="
echo "Done: Configure ZFS.                          "
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
echo "Done: Create ZFS Storage.                     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Verify ZFS Storage...                         "
echo "=============================================="
echo ''

sudo zpool list
sudo zpool status

echo ''
echo "=============================================="
echo "Done: Verify ZFS Storage.                     "
echo "=============================================="
echo ''

