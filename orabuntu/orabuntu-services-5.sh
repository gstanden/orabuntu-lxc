#!/bin/bash

#    Copyright 2015-2017 Gilbert Standen
#    This file is part of orabuntu-lxc.

#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.

#    v2.4 GLS 20151224
#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
OR=$OracleRelease
Config=/var/lib/lxc/oel$OracleRelease/config

echo ''
echo "=============================================="
echo "Script: orabuntu-services-5.sh                  "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script starts lxc clones                 "
echo "=============================================="

sleep 5

clear

## New Start

echo ''
echo "=============================================="
echo "This script starts lxc clones                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Create Priv/ASM OpenvSwitch Onboot Services..."
echo "=============================================="
echo ''

SwitchList='sw2 sw3 sw4 sw5 sw6 sw7 sw8 sw9'
for k in $SwitchList
do
        if [ ! -f /etc/systemd/system/$k.service ]
        then
                sudo sh -c "echo '[Unit]'						 > /etc/systemd/system/$k.service"
                sudo sh -c "echo 'Description=$k Service'				>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'After=network-online.target'				>> /etc/systemd/system/$k.service"
                sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'Type=oneshot'						>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/crt_ovs_$k.sh' 	>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'ExecStop=/usr/bin/ovs-vsctl del-br $k' 		>> /etc/systemd/system/$k.service"
                sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$k.service"
                sudo sh -c "echo 'WantedBy=multi-user.target'				>> /etc/systemd/system/$k.service"
        fi
done

sudo ls -l /etc/systemd/system/sw*.service

echo ''
echo "=============================================="
echo "OpenvSwitch Priv/ASM Onboot Services Created. "
echo "=============================================="

sleep 5

clear

for k in $SwitchList
do
	echo ''
	echo "=============================================="
	echo "Start OpenvSwitch $k ...            "
	echo "=============================================="
	echo ''

        sudo chmod 644 /etc/systemd/system/$k.service
        sudo systemctl enable $k.service
	sudo service $k start
	sudo service $k status

	echo ''
	echo "=============================================="
	echo "OpenvSwitch $k is up.                         "
	echo "=============================================="
	
	sleep 3

	clear
done

echo ''
echo "=============================================="
echo "Openvswitch interfaces installed & configured."
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle...  "
echo "=============================================="


## New End

# echo ''
# echo "=============================================="
# echo "Make sure all openvswitch interfaces are up   "
# echo "=============================================="
# echo ''

# sudo /etc/network/openvswitch/crt_ovs_sw2.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw3.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw4.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw5.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw6.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw7.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw6.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw8.sh >/dev/null 2>&1
# sudo /etc/network/openvswitch/crt_ovs_sw9.sh >/dev/null 2>&1

# ifconfig | grep -v 'ns' | egrep -A1 'sw|sx'

# sleep 5

echo ''
echo "=============================================="
echo "Openvswitch interfaces are up.                "
echo "=============================================="
echo ''

sleep 5 

clear

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle...  "
echo "=============================================="

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | grep "ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' 
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
	function GetUbuntuVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
	}
	UbuntuVersion=$(GetUbuntuVersion)
	# GLS 20160707

	echo ''
	echo "Starting container $j ..."
	echo ''
	if [ $UbuntuVersion = '15.04' ] || [ $UbuntuVersion = '15.10' ]
	then
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
	}
	fi
	if [ $UbuntuVersion = '16.04' ] || [ $UbuntuVersion = '17.04' ]
	then
	function CheckPublicIPIterative {
	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f5 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
	}
	fi
	PublicIPIterative=$(CheckPublicIPIterative)
	echo $j | grep oel > /dev/null
	if [ $? -eq 0 ]
	then
	sudo bash -c "cat $Config|grep ipv4|cut -f2 -d'='|sed 's/^[ \t]*//;s/[ \t]*$//'|cut -f4 -d'.'|sed 's/^/\./'|xargs -I '{}' sed -i "/ipv4/s/\{}/\.1$OR/g" $Config"
#	sudo sed -i "s/\.39/\.$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
#	sudo sed -i "s/\.40/\.$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
	fi
	sudo lxc-start -n $j > /dev/null 2>&1
	sleep 5
	i=1
	while [ "$PublicIPIterative" != 10207 ] && [ "$i" -le 10 ]
	do
		echo "Waiting for $j Public IP to come up..."
		sleep 20
		PublicIPIterative=$(CheckPublicIPIterative)
		if [ $i -eq 5 ]
		then
			sudo lxc-stop -n $j
			sleep 2
			echo ''
			sudo /etc/network/openvswitch/veth_cleanups.sh $j
			echo ''
			sleep 2
			sudo lxc-start -n $j
			if [ $MajorRelease -eq 6 ] || [ $MajorRelease -eq 5 ]
			then
				sudo lxc-attach -n $j -- ntpd -x
			fi
		fi
	sleep 1
	i=$((i+1))
	done
done

echo ''
echo "=============================================="
echo "LXC clone containers for Oracle started.      "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "LXC containers for Oracle started.            "
echo "=============================================="
echo ''

sudo lxc-ls -f

echo ''
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Management links directory creation...        "
echo "Location is:  ~/Manage-Orabuntu-LXC           "
echo "Step creates pointers to relevant files for   "
echo "quickly locating Orabuntu-LXC config files.   "
echo "=============================================="
echo ''

sleep 10

if [ ! -e ~/Manage-Orabuntu ]
then
mkdir ~/Manage-Orabuntu
fi

cd ~/Manage-Orabuntu
sudo chmod 755 /etc/orabuntu-lxc-scripts/crt_links.sh 
sudo /etc/orabuntu-lxc-scripts/crt_links.sh

echo ''
ls -l ~/Manage-Orabuntu
echo ''
cd ~/Manage-Orabuntu

echo ''
echo "=============================================="
echo "Management links directory created.           "
echo "=============================================="

sleep 10

clear

echo ''
echo "=============================================="
echo "Next step would be to setup some block storage"
echo "(optional) e.g. for a DB e.g. Oracle RAC      "
echo "The scst-files.tar is in the 'archives' subdir"
echo "of this distribution:                         "
echo "                                              "
echo "tar -xvf .orabuntu/archives/scst-files.tar    "
echo "                                              "
echo "cd ./orabuntu/archives/scst-files             "
echo "cat README                                    "
echo "follow the instructions in the README         "
echo "Builds the SCST Linux SAN.                    "
echo "=============================================="

sleep 10

clear

function CheckRebootNeeded {
facter virtual
}
RebootNeeded=$(CheckRebootNeeded)

if [ $RebootNeeded != 'physical' ] && [ ! -f /etc/orabuntu-lxc-release ] 
then
	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release file...          "
	echo "=============================================="
	echo ''

	sudo touch /etc/orabuntu-lxc-release
	sudo sh -c "echo 'Orabuntu-LXC v4.4' > /etc/orabuntu-lxc-release"
	sudo ls -l /etc/orabuntu-lxc-release
	echo ''
	sudo cat /etc/orabuntu-lxc-release

	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release file complete.   "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo " Facter detects that this server is virtual.  "
	echo " A reboot now is recommended so that DNS      " 
	echo " for Orabuntu-LXC networks  will switch to    "
	echo " /etc/NetworkManager/dnsmasq.d/local          " 
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Display /etc/NetworkManager/dnsmasq.d/local   "
	echo "=============================================="
	echo ''

	sudo cat /etc/NetworkManager/dnsmasq.d/local

	echo ''
	echo "=============================================="
	echo "Displayed /etc/NetworkManager/dnsmasq.d/local "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Currently resolution of Orabuntu-LXC DNS      "
	echo "is being handled by the nameservers listed in "
	echo "the /etc/resolv.conf file.                    "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Display current /etc/resolv.conf file...      "
	echo "=============================================="
	echo ''

	sudo cat /etc/resolv.conf

	echo ''
	echo "=============================================="
	echo "Displayed /etc/resolv.conf file.              "
	echo "=============================================="
	
	sleep 5

	clear

#	echo "=============================================="
#	echo "If you reboot now the following lines will be "
#	echo "automatically commented out for you before    "
#	echo "reboot in the /etc/resolv.conf file:          "
#	echo "                                              "
#	echo "# nameserver 10.207.39.2                      "
#	echo "# nameserver 10.207.29.2                      "
#	echo "                                              "
#	echo "and when the server comes back up the file    "
#	echo "/etc/NetworkManager/dnsmasq.d/local will take "
#	echo "over DNS resolution for those networks.       "
#	echo "                                              "
#	echo "If you do not choose to reboot now you can    "
#	echo "manually comment out those nameservers later  "
#	echo "and then reboot to switch DNS to              "
#	echo "/etc/NetworkManager/dnsmasq.d/local           "
#	echo "                                              "
#	echo "Note that correct resolution of the Oracle GNS"
#	echo "SCAN IP's on the Orabuntu-LXC host (this host)"
#	echo "requires that the DNS be resolving via the    "
#	echo "/etc/NetworkManager/dnsmasq.d/local file      "
#	echo "=============================================="
#	echo "                                              "
#	echo "=============================================="
#	echo "                                              "
#	read -e -p "Reboot Now? [Y/N]                       " -i "Y" ReBoot 
#	echo "                                              "
#	echo "=============================================="
#	echo ''

#	if [ $ReBoot = 'y' ] || [ $ReBoot = 'Y' ] 
#	then
#		sudo sed -i "/nameserver 10\.207\.39\.2/s/nameserver 10\.207\.39\.2/# nameserver 10\.207\.39\.2/" /etc/resolv.conf
#		sudo sed -i "/nameserver 10\.207\.29\.2/s/nameserver 10\.207\.29\.2/# nameserver 10\.207\.39\.2/" /etc/resolv.conf
#		sudo reboot
#	fi

fi

if [ $RebootNeeded = 'physical' ] && [ ! -f /etc/orabuntu-lxc-release ] 
then
	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release file...          "
	echo "=============================================="
	echo ''

	sudo touch /etc/orabuntu-lxc-release
	sudo sh -c "echo 'Orabuntu-LXC v4.4' > /etc/orabuntu-lxc-release"
	sudo ls -l /etc/orabuntu-lxc-release
	echo ''
	sudo cat /etc/orabuntu-lxc-release

	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release file complete.   "
	echo "=============================================="

	sleep 5

	clear
fi

