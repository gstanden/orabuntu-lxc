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
echo "Install LXD...                                "
echo "=============================================="
echo ''

if   [ $UbuntuVersion = '16.04' ]
then
	echo 'Install LXD Snap ...'

elif [ $UbuntuVersion = '16.10' ]
then
	echo 'Install LXD Snap ...'

elif [ $UbuntuMajorVersion -eq 17 ]
then
	echo 'Install LXD Snap ...'

elif [ $UbuntuMajorVersion -ge 18 ]
then
	echo ''
	echo "=============================================="
	echo "Install LXD Snap ...                          "
	echo "=============================================="
	echo ''

	sleep 5

	sudo snap install lxd
	sudo snap refresh lxd --edge

	if   [ $PreSeed = 'Y' ]
	then
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
						lxd init
						
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
	else
		lxd init --auto
	fi

	echo ''
	echo "=============================================="
	echo "Done: Install LXD Snap ...                       "
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

