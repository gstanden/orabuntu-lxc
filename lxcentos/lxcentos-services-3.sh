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
Domain2=$3
MultiHost=$4

function GetMultiHostVar7 {
        echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)

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
elif [ $LinuxFlavor = 'CentOS' ]
then
        function GetCentOSDistroRelease {
                sudo cat /etc/centos-release | cut -f4 -d' ' | cut -f1 -d'.'
        }
        CentOSDistroRelease=$(GetCentOSDistroRelease)
        Release=$CentOSDistroRelease
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Red' ]
then
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
fi

echo ''
echo "=============================================="
echo "Script:  lxcentos-services-3.sh                 "
echo "                                              "
echo "This script installs packages into the Oracle "
echo "Linux container required for running Oracle.  "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Ping google.com test...                       "
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
echo "Ping google.com not reliable.                 "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Ping google.com is reliable.                  "
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

# GLS 20151222 I don't think this step does anything anymore.  Commenting for now, removal pending.
# sudo sed -i "s/lxcora01/oel$OracleRelease$SeedPostfix/" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

function CheckContainerUp {
sudo lxc-ls -f | grep oel$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

function CheckPublicIP {
sudo lxc-ls -f | sed 's/  */ /g' | grep oel$OracleRelease | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

echo ''
echo "=============================================="
echo "Starting LXC Seed Container for Oracle        "
echo "=============================================="
echo ''

if [ $ContainerUp != 'RUNNING' ] || [ $PublicIP != 1020729 ]
then
	function CheckContainersExist {
		sudo ls /var/lib/lxc | grep oel$OracleRelease | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ContainersExist=$(CheckContainersExist)

	function GetSeedContainerName {
		sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '	
	}
	SeedContainerName=$(GetSeedContainerName)

	sleep 5

        for j in $ContainersExist
        do
                # GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
                # GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
                
                if [ $Release = '7' ] || [ $Release = '6' ]
                then
                function CheckPublicIPIterative {
		sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f2 -d'-' | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f1 -d' ' | cut -f1-2 -d'.' | sed 's/\.//g'
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
			echo ''
			sudo lxc-stop -n $j > /dev/null 2>&1
			sudo /etc/network/openvswitch/veth_cleanups.sh $SeedContainerName
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
echo "Public IP is up on $SeedContainerName         "
echo ''
sudo lxc-ls -f
echo ''
echo "=============================================="
echo "Container Up.                                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Container $SeedContainerName ping test...     "
echo "=============================================="
echo ''

ping -c 3 $SeedContainerName

function CheckNetworkUp {
ping -c 3 $SeedContainerName | grep packet | cut -f3 -d',' | sed 's/ //g'
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
echo "Container $SeedContainerName not pingable.    "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Container $SeedContainerName is pingable.     "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Testing connectivity to $SeedContainerName... "
echo "=============================================="
echo ''
echo "=============================================="
echo "Output of 'uname -a' in $SeedContainerName... "
echo "=============================================="
echo ''

sudo lxc-attach -n $SeedContainerName -- uname -a
if [ $? -ne 0 ]
then
echo ''
echo "=============================================="
echo "No-password $SeedContainerName ssh has issue. "
echo "No-password $SeedContainerName must succeed.  "
echo "Fix issues retry script.                      "
echo "Script exiting.                               "
echo "=============================================="
exit
fi
echo ''
echo "=============================================="
echo "No-password $SeedContainerName ssh successful."
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Configuring $SeedContainerName for Oracle...  "
echo "=============================================="
echo ''

sudo lxc-attach -n $SeedContainerName -- ip link set eth0 mtu $MultiHostVar7
sudo lxc-attach -n $SeedContainerName -- /root/packages.sh
sudo lxc-attach -n $SeedContainerName -- /root/create_users.sh
sudo lxc-attach -n $SeedContainerName -- /root/lxc-services.sh
sudo lxc-attach -n $SeedContainerName -- usermod --password `perl -e "print crypt('grid','grid');"` grid
sudo lxc-attach -n $SeedContainerName -- usermod --password `perl -e "print crypt('oracle','oracle');"` oracle
sudo lxc-attach -n $SeedContainerName -- usermod -g oinstall oracle
sudo lxc-attach -n $SeedContainerName -- chown oracle:oinstall /home/oracle/.bash_profile
sudo lxc-attach -n $SeedContainerName -- chown oracle:oinstall /home/oracle/.bashrc
sudo lxc-attach -n $SeedContainerName -- chown oracle:oinstall /home/oracle/.kshrc
sudo lxc-attach -n $SeedContainerName -- chown oracle:oinstall /home/oracle/.bash_logout
sudo lxc-attach -n $SeedContainerName -- chown oracle:oinstall /home/oracle/.
sudo lxc-attach -n $SeedContainerName -- chown grid:oinstall /home/grid/.bash_profile
sudo lxc-attach -n $SeedContainerName -- chown grid:oinstall /home/grid/.bashrc
sudo lxc-attach -n $SeedContainerName -- chown grid:oinstall /home/grid/.kshrc
sudo lxc-attach -n $SeedContainerName -- chown grid:oinstall /home/grid/.bash_logout
sudo lxc-attach -n $SeedContainerName -- chown grid:oinstall /home/grid/.
sudo lxc-attach -n $SeedContainerName -- yum -y install net-tools bind-utils ntp

echo ''  
echo "=============================================="
echo "$SeedContainerName configured for Oracle.     "
echo "=============================================="
echo ''

sleep 5

clear

if [ $MajorRelease -eq 7 ]
then
	echo ''
	echo "=============================================="
	echo "Enabling LXC NTP service...                   "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n $SeedContainerName -- chmod +x /etc/systemd/system/ntp.service
	sudo lxc-attach -n $SeedContainerName -- systemctl enable ntp.service
	echo ''
	sudo lxc-attach -n $SeedContainerName -- service ntp start
	echo ''
	sudo lxc-attach -n $SeedContainerName -- service ntpd start
	echo ''
	sudo lxc-attach -n $SeedContainerName -- service ntp status
	echo ''
	sudo lxc-attach -n $SeedContainerName -- chkconfig ntp on
	sudo lxc-attach -n $SeedContainerName -- chkconfig ntpd on

	echo ''
	echo "=============================================="
	echo "Enabled LXC NTP service.                      "
	echo "=============================================="

	sleep 5

	clear
elif [ $MajorRelease -eq 6 ] || [ $MajorRelease -eq 5 ]
then
	sudo lxc-attach -n $SeedContainerName -- ntpd -x
fi

echo ''
echo "=============================================="
echo "Next script to run: lxcentos-services-4.sh    "
echo "=============================================="

sleep 5
