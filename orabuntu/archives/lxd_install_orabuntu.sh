#!/bin/bash

clear

   PreSeed=$1
LXDCluster=$2
 MultiHost=$3
       GRE=$4

function GetUbuntuVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
}
UbuntuVersion=$(GetUbuntuVersion)

function GetUbuntuMajorVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
}
UbuntuMajorVersion=$(GetUbuntuMajorVersion)

echo ''
echo "=============================================="
echo "Configure LXD...                              "
echo "=============================================="
echo ''

sleep 5

clear

if   [ $UbuntuMajorVersion -ge 16 ]
then
	echo ''
	echo "=============================================="
	echo "Install LXD Snap ...                          "
	echo "=============================================="
	echo ''

	sudo snap install lxd
	sudo snap refresh lxd
#	sudo snap refresh lxd --edge

	echo ''
	echo "=============================================="
	echo "Done: Install LXD Snap.                       "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	if   [ $PreSeed = 'Y' ] && [ $UbuntuMajorVersion -ge 20 ]
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
					cat /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster | lxd init --preseed
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
						cat   /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster | lxd init --preseed
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

