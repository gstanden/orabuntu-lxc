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
#    v5.0 GLS 20171016 Orabuntu-LXC v5.0 EE MultiHost

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
MultiHost=$5
NameServer=$6
OR=$OracleRelease

GetLinuxFlavors(){
if   [[ -e /etc/oracle-release ]]
then
        LinuxFlavors=$(cat /etc/oracle-release | cut -f1 -d' ')
elif [[ -e /etc/redhat-release ]]
then
        LinuxFlavors=$(cat /etc/redhat-release | cut -f1 -d' ')
elif [[ -e /usr/bin/lsb_release ]]
then
        LinuxFlavors=$(lsb_release -d | awk -F ':' '{print $2}' | cut -f1 -d' ')
elif [[ -e /etc/issue ]]
then
        LinuxFlavors=$(cat /etc/issue | cut -f1 -d' ')
else
        LinuxFlavors=$(cat /proc/version | cut -f1 -d' ')
fi
}
GetLinuxFlavors

function TrimLinuxFlavors {
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//'
}
LinuxFlavor=$(TrimLinuxFlavors)

if   [ $LinuxFlavor = 'Oracle' ]
then
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Red' ]
then
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$RedHatVersion
        LF=$LinuxFlavor'Hat'
        RL=$Release
fi

function GetOperation {
echo $MultiHost | cut -f1 -d':'
}
Operation=$(GetOperation)

function GetMultiHostVar4 {
        echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

function GetMultiHostVar7 {
        echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)

function CheckSeedRunning {
        sudo lxc-ls -f | grep oel$OracleRelease$SeedPostfix | grep RUNNING | wc -l
}
SeedRunning=$(CheckSeedRunning)

SeedIndex=10
function CheckHighestSeedIndexHit {
	nslookup 10.207.29.$SeedIndex | grep "can't find" | wc -l
}
HighestSeedIndexHit=$(CheckHighestSeedIndexHit)

while [ $HighestSeedIndexHit = 0 ]
do
	SeedIndex=$((SeedIndex+1))
	HighestSeedIndexHit=$(CheckHighestSeedIndexHit)
done
SeedPostfix=c$SeedIndex

clear

echo ''
echo "=============================================="
echo "uekulele-services-2.sh script                 "
echo "                                              "
echo "This script creates Oracle seed LXC container "
echo "and overlays container with custom files      "
echo "for Oracle.                                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Establish sudo privileges...                  "
echo "=============================================="
echo ''

echo $MultiHostVar4 | sudo -S date

echo ''
echo "=============================================="
echo "Privileges established.                       "
echo "=============================================="

sleep 5

clear

if [ $SeedRunning -eq 0 ]
then
	echo ''
	echo "=============================================="
	echo "Create the LXC oracle container...            "
	echo "=============================================="
	echo ''

	sudo lxc-create -n oel$OracleRelease$SeedPostfix -t oracle -- --release=$OracleVersion

	echo ''
	echo "=============================================="
	echo "Create the LXC oracle container complete      "
	echo "(Passwords are the same as the usernames)     "
	echo "Sleeping 5 seconds...                         "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Extracting oracle-specific files to container."
	echo "=============================================="
	echo ''

	cd ~/Downloads/orabuntu-lxc-master/uekulele/archives
	sudo tar -xvf ~/Downloads/orabuntu-lxc-master/uekulele/archives/lxc-oracle-files.tar -C /var/lib/lxc/oel$OracleRelease$SeedPostfix --touch

	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/hugepages_setting.sh
	sudo chmod 755 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/hugepages_setting.sh
	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/packages.sh
	sudo chmod 755 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/packages.sh
	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/create_directories.sh
	sudo chmod 755 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/create_directories.sh
	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/lxc-services.sh
	sudo chmod 755 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/lxc-services.sh
	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/create_users.sh
	sudo chmod 755 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/root/create_users.sh
	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	sudo chmod 644 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	sudo sed -i "s/HOSTNAME=ContainerName/HOSTNAME=oel$OracleRelease$SeedPostfix/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/network
	sudo rm /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/ntp.conf

	if [ -n $Domain1 ]
	then
        	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	fi

	if [ -n $Domain2 ]
	then
        	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	fi

	echo ''
	echo "=============================================="
	echo "Extraction container-specific files complete  "
	echo "=============================================="

	sleep 5

	clear

# 	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k

	echo ''
	echo "=============================================="
	echo "Begin LXC container MAC address reset...      "
	echo "=============================================="
	echo ''

	sudo cp /var/lib/lxc/oel$OracleRelease$SeedPostfix/config /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.original.bak

	function GetOriginalHwaddr {
	sudo cat /var/lib/lxc/oel$OracleRelease$SeedPostfix/config | grep hwaddr | tail -1 | sed 's/\./\\\./g'
	}
	OriginalHwaddr=$(GetOriginalHwaddr)
	echo $OriginalHwaddr | sed 's/\\//g'

	sudo cp -p /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.oracle.bak.oel$MajorRelease /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.oracle

	sudo sed -i "s/lxc\.network\.hwaddr.*/$OriginalHwaddr/" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.oracle
	sudo cp -p /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.oracle /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

	echo ''
	echo "These should match..."
	echo ''
	sudo grep hwaddr /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.original.bak | tail -1
	sudo grep hwaddr /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.oracle

	sudo chmod 644 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

	echo ''
	echo "=============================================="
	echo "LXC container MAC address reset complete.     "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Legacy script cleanups...                     "
	echo "=============================================="
	echo ''

	sudo tar -vP --extract --file=ubuntu-host.tar /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1
	sudo tar -vP --extract --file=ubuntu-host.tar /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1
	sudo cp -p /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1 /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
	sudo cp -p /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1 /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

	sudo sed -i 's/-sw1/-sx1/g' 	/var/lib/lxc/oel$OracleRelease$SeedPostfix/config
	sudo sed -i 's/sw1/sx1/g'   	/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
	sudo sed -i 's/sw1/sx1/g'   	/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1
	sudo sed -i 's/tag=10/tag=11/g' /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1

	sudo ls -l /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix*
	sudo ls -l /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix*

	echo ''
	echo "=============================================="
	echo "Legacy script cleanups complete               "
	echo "=============================================="

	sleep 5

	clear

	if [ $MajorRelease -eq 7 ]
	then
		echo ''
		echo "=============================================="
		echo "Create LXC NTP service file...                "
		echo "=============================================="
		echo ''

		Wants=ntpd.service
		Before=ntpd.service

		sudo sh -c "echo '[Unit]'             	         		 		>  /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'Description=ntp Service'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'Wants=ntpd.service'						>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'Before=ntpd.service'						>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo ''								>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo '[Service]'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'Type=oneshot'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'User=root'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'RemainAfterExit=yes'						>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'ExecStart=/usr/sbin/ntpd -x'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'ExecStop=/bin/bash /usr/sbin/service /usr/sbin/ntpd stop'	>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo ''								>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo '[Install]'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
		sudo sh -c "echo 'WantedBy=multi-user.target'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"

		sudo cat /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service

		echo ''
		echo "=============================================="
		echo "Created LXC NTP service file.                 "
		echo "=============================================="

		sleep 5

		clear
	
		echo ''
		echo "=============================================="
		echo "Set NTP '-x' option in ntpd file...           "
		echo "=============================================="
		echo ''

		sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /etc/sysconfig/ntpd
		sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/ntpd
	fi

	sleep 5

	clear

	cd /etc/network/if-up.d/openvswitch
	sudo sed -i "s/ContainerName/oel$OracleRelease$SeedPostfix/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

	# GLS 20151217 Veth Pair Cleanups Scripts Create

	sudo chown root:root /etc/network/openvswitch/veth_cleanups.sh
	sudo chmod 755 /etc/network/openvswitch/veth_cleanups.sh

	if [ $Release -eq 6 ]
	then
		echo ''
		echo "=============================================="
		echo "Reboot #3 required for $LF Linux $RL...       "
		echo "=============================================="
                echo ''
                echo "=============================================="
                echo "Re-run anylinux-services.sh after reboot...   "
                echo "=============================================="

#		Already in the config.oracle.ol6.bak file in the archive.
#		sudo sh -c "echo '# Autostart at boot' >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
#		sudo sh -c "echo 'lxc.start.auto = 1'  >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
#		sudo sh -c "echo 'lxc.group = onboot'  >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
#		sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D'    /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

		sudo reboot

		sleep 5
	fi

fi

sleep 5

clear

echo ''
echo "==============================================" 
echo "Next script to run: uekulele-services-3.sh    "
echo "=============================================="

sleep 5

