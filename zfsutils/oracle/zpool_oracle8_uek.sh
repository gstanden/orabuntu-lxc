#!/bin/bash

# Usage:  ./zpool_oracle8_uek.sh [olxc-001|olxc-002|olxc-003|...] lun1 lun2

clear

PoolName=$1
Lun1Name=$2
Lun2Name=$3

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
sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum-config-manager --enable epel 
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

echo ''
echo "=============================================="
echo "Update strt_scst.sh file if it exists...      "
echo "=============================================="
echo ''

if [ -f /etc/network/openvswitch/strt_scst.sh ]
then
        function WhichModprobe {
                which modprobe
        }
        ModProbe=$(WhichModprobe)

        function WhichSudo {
                which sudo
        }
        Sudo=$(WhichSudo)

        function WhichZpool {
                which zpool
        }
        Zpool=$(WhichZpool)

        function WhichSleep {
                which sleep 
        }
        Sleep=$(WhichSleep)

	sudo sh -c "echo '$Sleep 10'			>> /etc/network/openvswitch/strt_scst.sh"
        sudo sh -c "echo '$ModProbe zfs'		>> /etc/network/openvswitch/strt_scst.sh"
        sudo sh -c "echo '$Zpool import $PoolName' 	>> /etc/network/openvswitch/strt_scst.sh"
	sudo cat /etc/network/openvswitch/strt_scst.sh
fi

echo ''
echo "=============================================="
echo "Done: Update strt_scst.sh file if it exists.  "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Update stop_scst.sh file if it exists.        "
echo "=============================================="
echo ''

if [ -f /etc/network/openvswitch/stop_scst.sh ]
then
	function GetZpool2 {
        	echo $Zpool | sed 's/\//\\\//g'
	}
	Zpool2=$(GetZpool2)


	sudo sed -i "s/bash/&\nzpool export $POOL/" 	/etc/network/openvswitch/stop_scst.sh
	sudo sed -i "s/zpool/$Zpool2/" 			/etc/network/openvswitch/stop_scst.sh
fi

echo ''
echo "=============================================="
echo "Done: Update stop_scst.sh file if it exists.  "
echo "=============================================="
echo ''


