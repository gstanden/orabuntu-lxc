#!/bin/bash

clear

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
	lxd init --auto

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

# echo ''
# echo "=============================================="
# echo "                                              "
# echo "=============================================="
# echo ''
# echo "=============================================="
# echo "                                              "
# echo "=============================================="
# echo ''



# echo ''
# echo "=============================================="
# echo "                                              "
# echo "=============================================="
# echo ''
# echo "=============================================="
# echo "                                              "
# echo "=============================================="
# echo ''
