#!/bin/bash

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

clear

echo ''
echo "=============================================="
echo "Display Install Settings...                   "
echo "=============================================="
echo ''

         PreSeed=$1
      LXDCluster=$2
             GRE=$3
         Release=$4
       MultiHost=$5
LXDStorageDriver=$6

echo "PreSeed       = "$1
echo "LXDCluster    = "$2
echo "GRE           = "$3
echo "Release       = "$4
echo "StorageDriver = "$6

# Reference
# /etc/network/openvswitch/preseed.sw1a.zfs.001.lxd.cluster
# /etc/network/openvswitch/preseed.sw1a.zfs.002.lxd.cluster
# /etc/network/openvswitch/preseed.sw1a.btr.001.lxd.cluster
# /etc/network/openvswitch/preseed.sw1a.btr.002.lxd.cluster

echo ''
echo "=============================================="
echo "Done: Display Install Settings.               "
echo "=============================================="
echo ''

sleep 5

clear

if   [ $PreSeed = 'Y' ] && [ $Release -ge 7 ]
then
	echo ''
	echo "=============================================="
	echo "Run LXD Init (takes awhile...patience...)     "
	echo "=============================================="
	echo ''

	m=1; n=1
	while [ $m -eq 1 ]
	do
		sleep 120
		if   [ $LXDCluster = 'N' ]
		then
			cat /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd | lxd init --preseed
			if [ $? -ne 0 ]
			then
				m=1
			else
				m=0
			fi

		elif [ $LXDCluster = 'Y' ]
		then
			if   [ $GRE = 'N' ]
			then
				if [ $LXDStorageDriver = 'zfs' ]
				then
					cat /etc/network/openvswitch/preseed.sw1a.zfs.001.lxd.cluster | lxd init --preseed
					if [ $? -ne 0 ]
					then
						m=1
					else
						m=0
					fi

				elif [ $LXDStorageDriver = 'btrfs' ]
				then
					cat /etc/network/openvswitch/preseed.sw1a.btr.001.lxd.cluster | lxd init --preseed
					if [ $? -ne 0 ]
					then
						m=1
					else
						m=0
					fi
				fi

			elif [ $GRE = 'Y' ]
			then
				if [ $n -le 10 ]
				then
					if [ $LXDStorageDriver = 'zfs' ]
					then
						cat /etc/network/openvswitch/preseed.sw1a.zfs.002.lxd.cluster | lxd init --preseed
						if [ $? -ne 0 ]
						then
							m=1
						else
							m=0
						fi
						n=$((n+1))

					elif [ $LXDStorageDriver = 'btrfs' ]
					then
						cat /etc/network/openvswitch/preseed.sw1a.btr.002.lxd.cluster | lxd init --preseed
						if [ $? -ne 0 ]
						then
							m=1
						else
							m=0
						fi
						n=$((n+1))
					fi
				else
					sudo lxd init
					
					if [ $? -ne 0 ]
					then
						m=1
					else
						m=0
					fi
				fi
			sleep 60
			fi
		fi
	done

	echo "/var/lib/snapd/snap/bin/lxc cluster list" | sg lxd

	echo ''
	echo "=============================================="
	echo "Done: Run LXD Init.                           "
	echo "=============================================="
	echo ''

	sleep 5

	clear

elif [ $PreSeed = 'E' ]
then
	m=1
	while [ $m -eq 1 ]
	do
		sleep 120
		sudo cat 	/etc/network/openvswitch/lxd-init-node1.sh
		sudo chmod +x 	/etc/network/openvswitch/lxd-init-node1.sh
				/etc/network/openvswitch/lxd-init-node1.sh
		if [ $? -ne 0 ]
		then
			m=1
		else
			m=0
		fi
	done

	echo ''
	echo "=============================================="
	echo "Done: Run LXD Init.                           "
	echo "=============================================="
	echo ''

	sleep 5

	clear
else
	lxd init --auto
	
	echo ''
	echo "=============================================="
	echo "Done: Run LXD Init.                           "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Done: Configure LXD                           "
echo "=============================================="
echo ''

sleep 5

clear
