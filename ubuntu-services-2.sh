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

#!/bin/bash

clear

echo ''
echo "=============================================="
echo "ubuntu-services-2.sh script                   "
echo "                                              "
echo "This script customizes container for oracle.  "
echo "This script creates rsa key for host if one   "
echo "does not already exist                        "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="
echo ''

OracleMajor=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain=$3

sleep 5

clear

echo ''
echo "=============================================="
echo "Extracting oracle-specific files to container."
echo "=============================================="
echo ''

sudo tar -xvf ~/Downloads/orabuntu-lxc-master/lxc-oracle-files.tar -C /var/lib/lxc/oel$OracleRelease

sudo chown root:root /var/lib/lxc/oel$OracleRelease/rootfs/root/hugepages_setting.sh
sudo chmod 755 /var/lib/lxc/oel$OracleRelease/rootfs/root/hugepages_setting.sh
sudo chown root:root /var/lib/lxc/oel$OracleRelease/rootfs/root/packages.sh
sudo chmod 755 /var/lib/lxc/oel$OracleRelease/rootfs/root/packages.sh
sudo chown root:root /var/lib/lxc/oel$OracleRelease/rootfs/root/create_directories.sh
sudo chmod 755 /var/lib/lxc/oel$OracleRelease/rootfs/root/create_directories.sh
sudo chown root:root /var/lib/lxc/oel$OracleRelease/rootfs/root/lxc-services.sh
sudo chmod 755 /var/lib/lxc/oel$OracleRelease/rootfs/root/lxc-services.sh
sudo chown root:root /var/lib/lxc/oel$OracleRelease/rootfs/root/create_users.sh
sudo chmod 755 /var/lib/lxc/oel$OracleRelease/rootfs/root/create_users.sh
sudo chown root:root /var/lib/lxc/oel$OracleRelease/rootfs/etc/dhcp/dhclient.conf
sudo chmod 644 /var/lib/lxc/oel$OracleRelease/rootfs/etc/dhcp/dhclient.conf
sudo sed -i "s/HOSTNAME=ContainerName/HOSTNAME=oel$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/rootfs/etc/sysconfig/network
sudo sed -i "s/yourdomain\.com/$Domain/" /var/lib/lxc/oel$OracleRelease/rootfs/etc/dhcp/dhclient.conf

echo ''
echo "=============================================="
echo "Extraction container-specific files complete  "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Begin LXC container MAC address reset...      "
echo "=============================================="
echo ''

sudo cp /var/lib/lxc/oel$OracleRelease/config /var/lib/lxc/oel$OracleRelease/config.original.bak

function GetOriginalHwaddr {
sudo cat /var/lib/lxc/oel$OracleRelease/config | grep hwaddr | tail -1 | sed 's/\./\\\./g'
}
OriginalHwaddr=$(GetOriginalHwaddr)
echo $OriginalHwaddr | sed 's/\\//g'

sudo cp -p /var/lib/lxc/oel$OracleRelease/config.oracle.bak.oel$OracleMajor /var/lib/lxc/oel$OracleRelease/config.oracle

sudo sed -i "s/lxc\.network\.hwaddr.*/$OriginalHwaddr/" /var/lib/lxc/oel$OracleRelease/config.oracle
sudo cp -p /var/lib/lxc/oel$OracleRelease/config.oracle /var/lib/lxc/oel$OracleRelease/config

echo ''
echo "These should match..."
echo ''
sudo grep hwaddr /var/lib/lxc/oel$OracleRelease/config.original.bak | tail -1
sudo grep hwaddr /var/lib/lxc/oel$OracleRelease/config.oracle

sudo chmod 644 /var/lib/lxc/oel$OracleRelease/config

echo ''
echo "=============================================="
echo "LXC container MAC address reset complete.     "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Create RSA key if it does not already exist   "
echo "=============================================="
echo ''

if [ ! -e ~/.ssh/id_rsa.pub ]
then
# ssh-keygen -t rsa
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

if [ -e ~/.ssh/known_hosts ]
then
rm ~/.ssh/known_hosts
fi

if [ -e ~/.ssh/authorized_keys ]
then
rm ~/.ssh/authorized_keys
fi

touch ~/.ssh/authorized_keys

if [ -e ~/.ssh/id_rsa.pub ]
then
function GetAuthorizedKey {
cat ~/.ssh/id_rsa.pub
}
AuthorizedKey=$(GetAuthorizedKey)

echo ''
echo 'Authorized Key:'
echo ''
echo $AuthorizedKey 
echo ''
fi

function CheckAuthorizedKeys {
grep -c "$AuthorizedKey" ~/.ssh/authorized_keys
}
AuthorizedKeys=$(CheckAuthorizedKeys)

echo "Results of grep = $AuthorizedKeys"

if [ "$AuthorizedKeys" -eq 0 ]
then
cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

echo ''
echo 'cat of authorized_keys'
echo ''
cat ~/.ssh/authorized_keys

echo ''
echo "=============================================="
echo "Create RSA key completed                      "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Legacy script cleanups...                     "
echo "=============================================="
echo ''

sudo cp -p /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1 /etc/network/if-up.d/openvswitch/oel$OracleRelease-pub-ifup-sx1
sudo cp -p /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1 /etc/network/if-down.d/openvswitch/oel$OracleRelease-pub-ifdown-sx1

sudo sed -i 's/-sw1/-sx1/g' /var/lib/lxc/oel$OracleRelease/config

sudo ls -l /etc/network/if-up.d/openvswitch/oel$OracleRelease*
sudo ls -l /etc/network/if-down.d/openvswitch/oel$OracleRelease*

echo ''
echo "=============================================="
echo "Legacy script cleanups complete               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Ping test  google.com...                   "
echo "=============================================="
echo ''

ping -c 3 google.com

function CheckNetworkUp {
ping -c 3 google.com | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
n=1
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -le 5 ]
do
NetworkUp=$(CheckNetworkUp)
n=$((n+1))
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "Ping google.com not reliably pingable.        "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Ping google.com reliable.                     "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Initialize LXC Seed Container on OpenvSwitch.."
echo "=============================================="

cd /etc/network/if-up.d/openvswitch
sudo sed -i "s/ContainerName/oel$OracleRelease/g" /var/lib/lxc/oel$OracleRelease/config

function CheckContainerUp {
sudo lxc-ls -f | grep oel$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

function CheckPublicIP {
sudo lxc-ls -f | sed 's/  */ /g' | grep oel$OracleRelease | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

# GLS 20151217 Veth Pair Cleanups Scripts Create

sudo chown root:root /etc/network/openvswitch/veth_cleanups.sh
sudo chmod 755 /etc/network/openvswitch/veth_cleanups.sh

# GLS 20151217 Veth Pair Cleanups Scripts Create End

echo ''
echo "=============================================="
echo "Starting LXC Seed Container for Oracle        "
echo "=============================================="
echo ''

sudo sed -i 's/sw1/sx1/' /etc/network/if-up.d/openvswitch/oel$OracleRelease*
sudo sed -i 's/sw1/sx1/' /etc/network/if-down.d/openvswitch/oel$OracleRelease*
sudo sed -i 's/tag=10/tag=11/' /etc/network/if-up.d/openvswitch/oel$OracleRelease*
sudo sed -i 's/tag=10/tag=11/' /etc/network/if-down.d/openvswitch/oel$OracleRelease*

if [ $ContainerUp != 'RUNNING' ] || [ $PublicIP != 1020729 ]
then
	function CheckContainersExist {
	sudo ls /var/lib/lxc | grep oel$OracleRelease | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ContainersExist=$(CheckContainersExist)
	sleep 5
	for j in $ContainersExist
	do
        	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
        	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
        	function GetUbuntuVersion {
        	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        	}
        	UbuntuVersion=$(GetUbuntuVersion)
        	# GLS 20160707
        	if [ $UbuntuVersion = 15.04 ] || [ $UbuntuVersion = 15.10 ]
        	then
        	function CheckPublicIPIterative {
        	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
        	}
        	fi
        	if [ $UbuntuVersion = 16.04 ]
        	then
        	function CheckPublicIPIterative {
        	sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f5 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
        	}
        	fi
		PublicIPIterative=$(CheckPublicIPIterative)
		echo "Starting container $j ..."
		echo ''
		sudo lxc-start -n $j > /dev/null 2>&1
		i=1
		while [ "$PublicIPIterative" != 10207 ] && [ "$i" -le 10 ]
		do
			echo "Waiting for $j Public IP to come up..."
			echo ''
			sleep 5
			PublicIPIterative=$(CheckPublicIPIterative)
			if [ $i -eq 5 ]
			then
			sudo lxc-stop -n $j > /dev/null 2>&1
			sudo /etc/network/openvswitch/veth_cleanups.sh oel$OracleRelease
			echo ''
			sudo lxc-start -n $j > /dev/null 2>&1
			fi
		sleep 1
		i=$((i+1))
		done
	done
	echo "=============================================="
	echo "LXC Seed Container for Oracle started.        "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Waiting for final container initialization.   " 
	echo "=============================================="
fi

echo ''
echo "==============================================" 
echo "Public IP is up on oel$OracleRelease                    "
echo ''
sudo lxc-ls -f
echo ''
echo "=============================================="
echo "Container Up.                                 "
echo "=============================================="

sleep 10

clear

echo ''
echo "=============================================="
echo "Container oel$OracleRelease ping test...                "
echo "=============================================="
echo ''

function CheckNetworkUp {
ping -c 3 oel$OracleRelease | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
n=1
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -le 5 ]
do
NetworkUp=$(CheckNetworkUp)
n=$((n+1))
done

ping -c 3 oel$OracleRelease

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "Container oel$OracleRelease not pinging.      "
echo "=============================================="
else
echo ''
echo "=============================================="
echo "Container oel$OracleRelease is pingable.      "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Testing connectivity to oel$OracleRelease...  "
echo "=============================================="
echo "Output of 'uname -a' in oel$OracleRelease...  "
echo "=============================================="
echo ''

sudo lxc-attach -n oel$OracleRelease -- uname -a
if [ $? -ne 0 ]
then
echo ''
echo "=============================================="
echo "No-password ssh to oel$OracleRelease has issue(s).      "
echo "No-password ssh to oel$OracleRelease must succeed.      "
echo "Fix issues retry script.                      "
echo "Script exiting.                               "
echo "=============================================="
exit
fi
echo ''
echo "=============================================="
echo "No-password ssh test to oel$OracleRelease successful.   "
echo "=============================================="

sleep 5

clear

echo ''
echo "==============================================" 
echo "Next script to run: ubuntu-services-3.sh      "
echo "=============================================="

sleep 5
