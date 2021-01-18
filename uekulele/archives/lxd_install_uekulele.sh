#!/bin/bash

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

echo "PreSeed    = "$1
echo "LXDCluster = "$2
echo "GRE        = "$3
echo "Release    = "$4

echo ''
echo "=============================================="
echo "Done: Display Install Settings.               "
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

	m=1; n=1
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
				cat /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster | lxd init --preseed
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
					cat   /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster | sudo /snap/bin/lxd init --preseed
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
