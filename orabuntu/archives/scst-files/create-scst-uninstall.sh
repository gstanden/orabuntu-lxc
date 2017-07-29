#!/bin/bash

clear

echo ''
echo "=============================================="
echo "Uninstall SCST Linux SAN                      "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "sudo scstadmin -clear_config -force           "
echo "=============================================="
echo ''

sudo scstadmin -clear_config -force             

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "sudo dpkg -r scst                             "
echo "=============================================="
echo ''

sudo dpkg -r scst                               

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "sudo apt-get purge scst                       "
echo "=============================================="
echo ''

sudo apt-get purge scst                         

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "sudo rm -rf /asm[01234]                       "
echo "=============================================="
echo ''

sudo rm -rf /asm0                                
sudo rm -rf /asm1                                
sudo rm -rf /asm2                                
sudo rm -rf /asm3                                
sudo rm -rf /asm4                                

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

function GetUbuntuMajorRelease {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
}
UbuntuMajorRelease=$(GetUbuntuMajorRelease)

if [ $UbuntuMajorRelease -gt 14 ]
then
	echo ''
	echo "=============================================="
	echo "sudo systemctl disable uekuscst               "
	echo "=============================================="
	echo ''

	sudo systemctl disable uekuscst
	sudo rm -f /etc/systemd/system/uekuscst.service

	echo ''
	echo "=============================================="
	echo "Uninstall SCST: Step completed.               "
	echo "=============================================="

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "sudo rm -f /etc/network/openvswitch/*_scst.sh "
echo "=============================================="
echo ''

sudo rm -f /etc/network/openvswitch/stp_scst.sh 
sudo rm -f /etc/network/openvswitch/strt_scst.sh

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "sudo rm -f /etc/network/if-down.d/scst.net    "
echo "=============================================="
echo ''

sudo rm -f /etc/network/if-down.d/scst.net      

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "sudo rm -f /etc/udev/rules.d/99-oracle.rules  "
echo "=============================================="
echo ''

sudo rm -f /etc/udev/rules.d/99-oracle.rules    

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Delete the ~/Downloads/scst-trunk ?           "
echo "                                              "
echo "If you are planning to reinstall SCST then    "
echo "answer 'N' here to avoid re-downloading code. "
echo "                                              "
echo "If you are permanently deleting the SCST SAN  "
echo "then answer 'Y' here to reclaim disk space of "
echo "the SCST source code.                         "
echo "                                              "
echo "You might also answer 'Y' if you are updating "
echo "to a new version of SCST and want to download "
echo "a new scst-trunk latest release.              "
echo "                                              "
echo "=============================================="
echo "                                              "
read -e -p "rm ~/Downloads/scst-trunk source [Y/N]  " -i "N" DeleteTrunkSCST
echo "                                              "
echo "=============================================="
echo ''

if [ $DeleteTrunkSCST = 'y' ] || [ $DeleteTrunkSCST = 'Y' ]
then
	sudo rm -rf ~/Downloads/scst-trunk
fi

echo ''
echo "=============================================="
echo "Uninstall SCST: Step completed.               "
echo "=============================================="

# If previously using multipath.conf then restore your backup copy.
# If not then just uncomment and delete the multipath.conf 

sleep 5

clear

echo ''
echo "=============================================="
echo "Delete the ~/etc/multipath.conf ?             "
echo "                                              "
echo "You might answer 'N' here if your             "
echo "/etc/multipath.conf file has other entries    "
echo "besides the entries for this SCST SAN.        "
echo "                                              "
echo "You probably would answer 'Y' here if your    "
echo "/etc/multipath.conf did not exist previously  "
echo "until you used these scripts to install SCST  "
echo "Linux SAN.                                    "
echo "                                              "
echo "=============================================="
echo "                                              "
read -e -p "rm /etc/multipath.conf [Y/N]            " -i "N" DeleteMultipathConf
echo "                                              "
echo "=============================================="
echo ''

if [ $DeleteMultipathConf = 'y' ] || [ $DeleteMultipathConf = 'Y' ]
then
sudo rm -f /etc/multipath.conf
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Remove Upstart/Init Job (Ubuntu 14.04 & lower)"
echo "=============================================="
echo ''

function GetUbuntuMajorRelease {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
}
UbuntuMajorRelease=$(GetUbuntuMajorRelease)

if [ $UbuntuMajorRelease -le 14 ]
then
	sudo update-rc.d -f scst remove
	echo ''
	sudo rm -f /etc/network/openvswitch/login-scst.sh
	sudo rm -f /etc/init/login-scst.conf
fi

echo ''
echo "=============================================="
echo "Remove Upstart/Init Job Completed.            "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Uninstall SCST: Complete.                     "
echo "=============================================="
echo ''
