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

#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
OR=$OracleRelease
NumCon=$3
NameServer=$4

echo ''
echo "=============================================="
echo "Script:  orabuntu-services-4.sh NumCon        "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "NumCon is the number of RAC nodes             "
echo "NumCon (small integer)                        "
echo "NumCon defaults to value '2'                  "
echo "=============================================="

if [ -z $3 ]
then
NumCon=2
else
NumCon=$3
fi

ContainerPrefix=ora$1$2c

echo ''
echo "=============================================="
echo "Number of LXC Container RAC Nodes = $NumCon   "
echo "=============================================="
echo ''
echo "=============================================="
echo "If wrong number of desired RAC nodes, then    "
echo "<ctrl>+c and restart script to set            "
echo "Sleeping 15 seconds...                        "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script creates oracle-ready lxc clones   "
echo "for oracle-ready RAC container nodes          "
echo "=============================================="

sleep 10

clear

echo ''
echo "=============================================="
echo "Stopping oel$OracleRelease container...       "
echo "(OEL 5 shutdown can take awhile...patience)   "
echo "(OEL 6 and OEL 7 are relatively fast shutdown)"
echo "=============================================="
echo ''

function CheckContainerUp {
sudo lxc-ls -f | grep oel$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)
sudo lxc-stop -n oel$OracleRelease > /dev/null 2>&1

while [ "$ContainerUp" = 'RUNNING' ]
do
sleep 1
ContainerUp=$(CheckContainerUp)
done

sudo lxc-ls -f

echo ''
echo "=============================================="
echo "Container stopped.                            "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Configure 12c ASM Flex Cluster (optional)     "
echo "=============================================="
echo ''

read -e -p "Add ASM Private Networks and RAC Private Networks ? [Y/N]   " -i "Y" AddPrivateNetworks

if [ $AddPrivateNetworks = 'y' ] || [ $AddPrivateNetworks = 'Y' ]
then
	sudo bash -c "cat /var/lib/lxc/oel$OR/config.oracle /var/lib/lxc/oel$OR/config.asm.flex.cluster > /var/lib/lxc/oel$OR/config"
	sudo sed -i "s/ContainerName/oel$OR/g" /var/lib/lxc/oel$OR/config
	OracleNonPublicNetworks='sw2 sw3 sw4 sw5 sw6 sw7 sw8 sw9'
	for j in $OracleNonPublicNetworks
	do
		echo 'nothing' > /dev/null 2>&1	
	done
fi

if [ $AddPrivateNetworks = 'n' ] || [ $AddPrivateNetworks = 'N' ]
then
	sudo cp -p /var/lib/lxc/oel$OracleRelease/config.oracle /var/lib/lxc/oel$OracleRelease/config
	sudo sed -i "s/ContainerName/oel$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
fi

echo ''
echo "=============================================="
echo "Configure 12c ASM Flex Cluster completed.     "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Clone oel$OracleRelease to $NumCon containers "
echo "=============================================="
echo ''

sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/oel$OracleRelease/rootfs/root/lxc-services.sh

function GetHighestContainerIndex {
	sudo ls /var/lib/lxc | more | grep ora | cut -c7-9 | sort -n | tail -1
}
HighestContainerIndex=$(GetHighestContainerIndex)

if [ -z $HighestContainerIndex ]
then
	HighestContainerIndex=0
fi

if [ $HighestContainerIndex -lt 10 ]
then
	let i=10
	let NewHighestContainerIndex=$i+$NumCon-1
fi

if [ $HighestContainerIndex -ge 10 ]
then
	let i=$HighestContainerIndex+1
	let NewHighestContainerIndex=$i+$NumCon-1
fi

sleep 5

while [ $i -le "$NewHighestContainerIndex" ]
do
	echo ''
	echo "=============================================="
	echo "Clone oel$OracleRelease to $ContainerPrefix$i "
	echo "=============================================="
	echo ''

	echo "Clone Container Name = $ContainerPrefix$i"

	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

	function GetRedHatVersion {
	cat /etc/redhat-release  | cut -f7 -d' ' | cut -f1 -d'.'
	}
	RedHatVersion=$(GetRedHatVersion)

	if [ $RedHatVersion = '7' ]
	then
       		sudo lxc-copy -n oel$OracleRelease -N $ContainerPrefix$i
	fi

	sudo sed -i "s/oel$OracleRelease/$ContainerPrefix$i/g" /var/lib/lxc/$ContainerPrefix$i/config
	sudo sed -i "s/\.10/\.$i/g" /var/lib/lxc/$ContainerPrefix$i/config
	sudo sed -i 's/sx1/sw1/g' /var/lib/lxc/$ContainerPrefix$i/config

	function GetHostName (){ echo $ContainerPrefix$i\1; }
	HostName=$(GetHostName)

	sudo sed -i "s/$HostName/$ContainerPrefix$i/" /var/lib/lxc/$ContainerPrefix$i/rootfs/etc/sysconfig/network

	echo ''
	echo "=============================================="
	echo "Create $ContainerPrefix$i Onboot Service...   "
	echo "=============================================="

	sudo sh -c "echo '#!/bin/bash'								>  /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '#'									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '# Manage the Oracle RAC LXC containers'				>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '#'									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo 'start() {'								>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '  exec lxc-start -n $ContainerPrefix$i > /dev/null 2>&1'		>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '}'									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo ''									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo 'stop() {'								>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '  exec lxc-stop -n $ContainerPrefix$i > /dev/null 2>&1'		>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '}'									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo ''									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo 'case \$1 in'								>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo '  start|stop) \"\$1\" ;;'						>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"
	sudo sh -c "echo 'esac'									>> /etc/network/openvswitch/strt_$ContainerPrefix$i.sh"

	sudo chmod +x /etc/network/openvswitch/strt_$ContainerPrefix$i.sh
	
	sudo sh -c "echo '[Unit]'                                                        	>  /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'Description=$ContainerPrefix$i Service'                               >> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'Wants=network-online.target sw1.service $NameServer.service'          >> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'After=network-online.target sw1.service $NameServer.service'          >> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo ''                                                             	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo '[Service]'                                                    	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'Type=oneshot'                                                 	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'User=root'                                                    	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'RemainAfterExit=yes'                                          	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_$ContainerPrefix$i.sh start' 	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/strt_$ContainerPrefix$i.sh stop'   	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo ''                                                             	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo '[Install]'                                                    	>> /etc/systemd/system/$ContainerPrefix$i.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'                                   	>> /etc/systemd/system/$ContainerPrefix$i.service"

	sudo chmod 644 /etc/systemd/system/$ContainerPrefix$i.service
	
	echo ''
	sudo cat /etc/systemd/system/$ContainerPrefix$i.service
	echo ''
	sudo systemctl enable $ContainerPrefix$i
	
	echo ''
	echo "=============================================="
	echo "Created $ContainerPrefix$i Onboot Service.   "
	echo "=============================================="
	echo ''

	sleep 5

	clear
i=$((i+1))
done

echo ''
echo "=============================================="
echo "Container cloning completed.                  "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Creating OpenvSwitch files ...                "
echo "=============================================="

sleep 5

sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefix $NumCon $NewHighestContainerIndex

echo ''
echo "=============================================="
echo "Creating OpenvSwitch files complete.          "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "      Reset config file for oel$OracleRelease."
echo "Removes ASM and RAC private network interfaces"
echo "      from seed container oel$OracleRelease   "
echo "(cloned containers are not affected by reset) "
echo "=============================================="
echo ''

read -e -p "Reset Seed Container oel$OracleRelease to single DHCP interface ? [Y/N]   " -i "Y" ResetSingleDHCPInterface

if [ $ResetSingleDHCPInterface = 'y' ] || [ $ResetSingleDHCPInterface = 'Y' ]
then
sudo cp -p /var/lib/lxc/oel$OracleRelease/config.oracle /var/lib/lxc/oel$OracleRelease/config
sudo sed -i "s/ContainerName/oel$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config
fi

echo ''
echo "=============================================="
echo "Config file reset successful.                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: orabuntu-services-5.sh    "
echo "=============================================="

sleep 5
