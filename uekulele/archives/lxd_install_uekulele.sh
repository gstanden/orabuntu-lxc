#!/bin/bash

clear

echo ''
echo "=============================================="
echo "Display Install Settings...                   "
echo "=============================================="
echo ''

   PreSeed=$1
LXDCluster=$2
 MultiHost=$3
       GRE=$4
   Release=$5

echo "PreSeed    = "$1
echo "LXDCluster = "$2
echo "MultiHost  = "$3
echo "GRE        = "$4
echo "Release    = "$5

echo ''
echo "=============================================="
echo "Done: Display Install Settings.               "
echo "=============================================="
echo ''

sleep 5

clear

if   [ $Release -ge 8 ]
then
	echo ''
	echo "=============================================="
	echo "Install and Configure LXD...                  "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Configure btrfs Storage ...                   "
	echo "=============================================="
	echo ''

	sudo parted --script /dev/sdb "mklabel gpt"
	sudo parted --script /dev/sdb "mkpart primary 1 100%"
	sudo parted /dev/sdb print
	sudo fdisk -l /dev/sdb | grep sdb | grep -v Disk

	echo ''
	echo "=============================================="
	echo "Done: Configure btrfs Storage.                "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install EPEL ...                              "
	echo "=============================================="
	echo ''

	sudo yum install epel-release

	echo ''
	echo "=============================================="
	echo "Done: Install EPEL.                           "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install and configure snapd...                "
	echo "=============================================="
	echo ''

	sudo yum -y install snapd
	echo ''
	sudo systemctl enable --now snapd.socket
	sudo ln -s /var/lib/snapd/snap /snap >/dev/null 2>&1

	echo ''
	echo "=============================================="
	echo "Done: Install and configure snapd.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install LXD ...                               "
	echo "=============================================="
	echo ''

	sudo snap install lxd
	sudo snap refresh lxd

	echo ''
	echo "=============================================="
	echo "Done: Install LXD.                            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Add current user to LXD group ...             "
	echo "=============================================="
	echo ''

	sudo usermod -a -G lxd ubuntu
	newgrp lxd
	groups

	sleep 5

	echo ''
	echo "=============================================="
	echo "Done: Add current user to LXD group.          "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install required packages ...                 "
	echo "=============================================="
	echo ''

	sudo yum -y install btrfs-progs
	sudo modprobe btrfs

	echo ''
	echo "=============================================="
	echo "Done: Install required packages.              "
	echo "=============================================="
	echo ''

#	sudo /snap/bin/lxd init
#	sudo snap refresh lxd --edge

	echo ''
	echo "=============================================="
	echo "Done: Install and Configure LXD.              "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	if   [ $PreSeed = 'Y' ] && [ $Release -ge 8 ]
	then
		echo ''
		echo "=============================================="
		echo "Run LXD Init (takes awhile...)                "
		echo "=============================================="
		echo ''

		m=1
		n=1

		while [ $m -eq 1 ]
		do
			sleep 120
			if   [ $LXDCluster = 'N' ]
			then
				cat /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd | lxd init --preseed
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
					cat /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster | sudo /snap/bin/lxd init --preseed
					if [ $? -ne 0 ]
					then
						m=1
					else
						m=0
					fi

				elif [ $GRE = 'Y' ]
				then
					if [ $n -le 5 ]
					then
						cat   /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster | lxd init --preseed
						if [ $? -ne 0 ]
						then
							m=1
						else
							m=0
						fi

						n=$((n+1))
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

	echo ''
	echo "=============================================="
	echo "LXD Snap Info ...                             "
	echo "=============================================="
	echo ''

	sleep 5

	sudo snap info lxd

	echo ''
	echo "=============================================="
	echo "Done: LXD Snap Info ...                       "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

