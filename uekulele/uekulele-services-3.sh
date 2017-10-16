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
#    v5.0 GLS 20161025 Orabuntu-LXC v5.0 EE MultiHost

MajorRelease=$1
PointRelease=$2
OracleRelease=$1$2
OracleVersion=$1.$2
Domain2=$3
MultiHost=$4

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

function GetSeedContainerName {
        sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '
}
SeedContainerName=$(GetSeedContainerName)

clear

echo ''
echo "=============================================="
echo "uekulele-services-3.sh script                 "
echo "                                              "
echo "This script customizes container for oracle by"
echo "installing required packages.                 "
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

echo ''
echo "=============================================="
echo "Ping test Oracle Public Yum server...         "
echo "=============================================="
echo ''

ping -c 3 yum.oracle.com

function CheckNetworkUp {
        ping -c 3 yum.oracle.com | grep packet | cut -f3 -d',' | sed 's/ //g'
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
        echo "Ping yum.oracle.com not reliably pingable.        "
        echo "Script exiting.                               "
        echo "=============================================="
        exit
else
        echo ''
        echo "=============================================="
        echo "Ping yum.oracle.com reliable.                     "
        echo "=============================================="
        echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Configuring $SeedContainerName for Oracle...  "
echo "=============================================="
echo ''

sleep 5

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

if   [ $MajorRelease -eq 7 ]
then
	echo ''
	echo "=============================================="
	echo "Enabling LXC NTP service...                   "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n $SeedContainerName -- ntpd -x
	sudo lxc-attach -n $SeedContainerName -- chmod +x /etc/systemd/system/ntp.service
	sudo lxc-attach -n $SeedContainerName -- systemctl enable ntp.service
	sudo lxc-attach -n $SeedContainerName -- service ntp start
	sudo lxc-attach -n $SeedContainerName -- service ntpd start
#	sudo lxc-attach -n $SeedContainerName -- service ntp status
	sudo lxc-attach -n $SeedContainerName -- chkconfig ntp on
	sudo lxc-attach -n $SeedContainerName -- chkconfig ntpd on

	echo ''
	echo "=============================================="
	echo "Enabled LXC NTP service.                      "
	echo "=============================================="

	sleep 5

	clear

elif [ $MajorRelease -eq 6 ] || [ $MajorRelease -eq 5 ]

	sudo lxc-attach -n $SeedContainerName -- ntpd -x
fi

sleep 5

clear

# GLS 20161118 This section for any tweaks to the unpacked files from archives.

if [ -f /etc/network/if-up.d/orabuntu-lxc-net ]
then
	sudo rm /etc/network/if-up.d/orabuntu-lxc-net
fi

echo ''
echo "=============================================="
echo "Configure extra networks (optional e.g. RAC)  "
echo "=============================================="
echo ''

AddPrivateNetworks=N
# read -e -p "Add Extra Private Networks (e.g for Oracle RAC ASM Flex Cluster) [Y/N]   " -i "Y" AddPrivateNetworks

if [ $AddPrivateNetworks = 'y' ] || [ $AddPrivateNetworks = 'Y' ]
then
        sudo bash -c "cat /var/lib/lxc/$SeedContainerName/config.oracle /var/lib/lxc/$SeedContainerName/config.asm.flex.cluster > /var/lib/lxc/$SeedContainerName/config"
        sudo sed -i "s/ContainerName/$SeedContainerName/g" /var/lib/lxc/$SeedContainerName/config
        OracleNonPublicNetworks='sw2 sw3 sw4 sw5 sw6 sw7 sw8 sw9'
        for j in $OracleNonPublicNetworks
        do
                echo 'nothing' > /dev/null 2>&1
        done
fi

if [ $AddPrivateNetworks = 'n' ] || [ $AddPrivateNetworks = 'N' ]
then
        sudo cp -p /var/lib/lxc/$SeedContainerName/config.oracle /var/lib/lxc/$SeedContainerName/config
        sudo sed -i "s/ContainerName/$SeedContainerName/g" /var/lib/lxc/$SeedContainerName/config
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Configure extra networks completed.   "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Configure NTP on LXC host...                  "
echo "=============================================="
echo ''

sudo service ntpd start
sudo ntpq -p
date

echo ''
echo "=============================================="
echo "Done:  Configure NTP on LXC host.             "
echo "=============================================="

sleep 5

clear

echo "=============================================="
echo "Next script to run: uekulele-services-4.sh    "
echo "=============================================="

sleep 5

