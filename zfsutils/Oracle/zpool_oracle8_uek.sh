#!/bin/bash

# Usage:  ./zpool_oracle8_uek.sh [olxc-001|olxc-002|olxc-003|...] lun1 lun2

clear

PoolName=$1
Lun1Name=$2
Lun2Name=$3

echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
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
echo "Create ZFS Storage...                         "
echo "=============================================="
echo ''

sudo zpool create $PoolName mirror $Lun1Name $Lun2Name

sudo zpool list
sudo zpool status

echo ''
echo "=============================================="
echo "Done: Create ZFS Storage.                     "
echo "=============================================="
echo ''

sleep 5

clear
