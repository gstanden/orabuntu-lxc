#!/bin/bash

#    Copyright 2015-2019 Gilbert Standen
#    This file is part of Orabuntu-LXC.

#    Orabuntu-LXC is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-LXC is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Orabuntu-LXC.  If not, see <http://www.gnu.org/licenses/>.

#    v2.4 		GLS 20151224
#    v2.8 		GLS 20151231
#    v3.0 		GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 		GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 		GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta	GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
MultiHost=$6
DistDir=$7
OR=$OracleRelease

echo ''
echo "=============================================="
echo "uekulele-services-2.sh script                   "
echo "                                              "
echo "This script customizes container for oracle.  "
echo "This script creates rsa key for host if one   "
echo "does not already exist                        "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="

sleep 5

clear

function GetShortHost {
        uname -n | cut -f1 -d'.'
}
ShortHost=$(GetShortHost)

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetLXCVersion {
        lxc-create --version
}
LXCVersion=$(GetLXCVersion)

function GetMultiHostVar2 {
        echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar4 {
        echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

function GetMultiHostVar5 {
        echo $MultiHost | cut -f5 -d':'
}
MultiHostVar5=$(GetMultiHostVar5)

function GetMultiHostVar6 {
        echo $MultiHost | cut -f6 -d':'
}
MultiHostVar6=$(GetMultiHostVar6)

function GetMultiHostVar7 {
        echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)
MTU=$MultiHostVar7

function GetMultiHostVar10 {
        echo $MultiHost | cut -f10 -d':'
}
MultiHostVar10=$(GetMultiHostVar10)
GRE=$MultiHostVar10

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
        if   [ $OracleDistroRelease -eq 7 ] || [ $OracleDistroRelease -eq 6 ]
        then
                CutIndex=7
        elif [ $OracleDistroRelease -eq 8 ]
        then
                CutIndex=6
        fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                function GetRedHatVersion {
                        sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
                }
                RedHatVersion=$(GetRedHatVersion)
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
                RedHatVersion=$(GetRedHatVersion)
        fi
	RHV=$RedHatVersion
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        if [ $RedHatVersion -ge 19 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
elif [ $LinuxFlavor = 'Ubuntu' ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
        LF=$LinuxFlavor
        RL=$UbuntuVersion
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

SeedIndex=10
SeedPostfix=c$SeedIndex
function CheckHighestSeedIndexHit {
	nslookup -timeout=1 oel$OracleRelease$SeedPostfix | grep -v '#' | grep Address | grep '10\.207\.29' | wc -l
}
HighestSeedIndexHit=$(CheckHighestSeedIndexHit)

while [ $HighestSeedIndexHit = 1 ]
do
	SeedIndex=$((SeedIndex+1))
	SeedPostfix=c$SeedIndex
	HighestSeedIndexHit=$(CheckHighestSeedIndexHit)
done
SeedPostfix=c$SeedIndex

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

if [ $LinuxFlavor = 'Fedora' ]
then
	echo ''
	echo "=============================================="
	echo "Install lxc-templates ($LinuxFlavor)...       "
	echo "=============================================="
	echo ''

	sudo yum -y install lxc-templates

	echo ''
	echo "=============================================="
	echo "Done: Install lxc-templates ($LinuxFlavor).   "
	echo "=============================================="

	sleep 5

	clear
fi

if [ $LinuxFlavor = 'CentOS' ]
then
	echo ''
	echo "=============================================="
	echo "Install lsb on CentOS 6 ...                   "
	echo "=============================================="
	echo ''

	sudo yum -y install lsb

	echo ''
	echo "=============================================="
	echo "Done: Install lsb on CentOS 6.                "
	echo "=============================================="

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "   Create the LXC Oracle Linux container      "
echo "                                              "
echo "    Note: Depends on download speed...        "
echo "    Patience at downloading packages !        "
echo "=============================================="
echo ''

sleep 5

sudo lxc-create -n oel$OracleRelease$SeedPostfix -t oracle -- --release=$OracleVersion

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
then
        sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

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
echo "Extract network files to container...        "
echo "=============================================="
echo ''

sudo mkdir -p /var/lib/lxc/oel$OracleRelease$SeedPostfix
cd /opt/olxc/"$DistDir"/uekulele/archives
sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/lxc-oracle-files.tar -C /var/lib/lxc/oel$OracleRelease$SeedPostfix --touch

sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
sudo chmod 644 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
sudo sed -i "s/HOSTNAME=ContainerName/HOSTNAME=oel$OracleRelease$SeedPostfix/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/network
# sudo rm /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/ntp.conf

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
echo "Done: Extract network files to container.     "
echo "=============================================="

sleep 5

clear

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

sudo cp -p /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/config.oracle.bak.oel$MajorRelease /var/lib/lxc/oel$OracleRelease$SeedPostfix/config.oracle

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

sudo cp -p /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1 /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
sudo cp -p /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1 /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

sudo sed -i 's/-sw1/-sx1/g' /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

sudo ls -l /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo ls -l /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix*

echo ''
echo "=============================================="
echo "Legacy script cleanups complete               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Ping test  google.com...                      "
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

# if [ $MajorRelease -ge 7 ]
# then
# 	echo ''
# 	echo "=============================================="
# 	echo "Create LXC NTP service file...                "
# 	echo "=============================================="
# 	echo ''

# 	Wants=ntpd.service
# 	Before=ntpd.service

# 	sudo sh -c "echo '[Unit]'             	         		 		>  /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'Description=ntp Service'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'Wants=ntpd.service'						>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'Before=ntpd.service'						>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo ''								>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo '[Service]'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'Type=oneshot'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'User=root'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'RemainAfterExit=yes'						>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'ExecStart=/usr/sbin/ntpd -x'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'ExecStop=/bin/bash /usr/sbin/service /usr/sbin/ntpd stop'	>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo ''								>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo '[Install]'							>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"
# 	sudo sh -c "echo 'WantedBy=multi-user.target'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service"

# 	sudo cat /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/systemd/system/ntp.service

# 	echo ''
# 	echo "=============================================="
# 	echo "Created LXC NTP service file.                 "
# 	echo "=============================================="

#	sleep 5

#	clear
	
#	echo ''
#	echo "=============================================="
#	echo "Set NTP '-x' option in ntpd file...           "
#	echo "=============================================="
#	echo ''

#	sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /etc/sysconfig/ntpd
#	sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/ntpd
# fi

sleep 5

clear

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
then
        sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

echo ''
echo "=============================================="
echo "Initialize Oracle Linux seed container...     "
echo "=============================================="

cd /etc/network/if-up.d/openvswitch
sudo sed -i "s/ContainerName/oel$OracleRelease$SeedPostfix/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

if [ $GRE = 'Y' ]
then
	sudo sed -i "/mtu/s/1500/$MTU/" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

function CheckContainerUp {
sudo lxc-ls -f | grep oel$OracleRelease$SeedPostfix | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

function CheckPublicIP {
	sudo lxc-info -n oel$OracleRelease$SeedPostfix -iH | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

# GLS 20151217 Veth Pair Cleanups Scripts Create

sudo chown root:root /etc/network/openvswitch/veth_cleanups.sh
sudo chmod 755 /etc/network/openvswitch/veth_cleanups.sh

# GLS 20151217 Veth Pair Cleanups Scripts Create End

echo ''
echo "=============================================="
echo "Start Oracle Linux seed LXC container...      "
echo "=============================================="
echo ''

sudo sed -i 's/sw1/sx1/' /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i 's/sw1/sx1/' /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i 's/tag=10/tag=11/' /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i 's/tag=10/tag=11/' /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i "s/mtu = 1500/mtu = $MultiHostVar7/" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
sudo sed -i "s/MtuSetting/$MultiHostVar7/" 	 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

if [ $ContainerUp != 'RUNNING' ] || [ $PublicIP != 1020729 ]
then
	function CheckContainersExist {
	sudo ls /var/lib/lxc | grep oel$OracleRelease$SeedPostfix | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ContainersExist=$(CheckContainersExist)
	sleep 5
	for j in $ContainersExist
	do
        	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
        	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
		
		RedHatVersion=$(GetRedHatVersion)

        	if [ $Release -ge 7 ] || [ $Release -eq 6 ]
        	then
        	function CheckPublicIPIterative {
			sudo lxc-info -n oel$OracleRelease$SeedPostfix -iH | cut -f1-3 -d'.' | sed 's/\.//g'
        	}
        	fi
		PublicIPIterative=$(CheckPublicIPIterative)
		echo "Starting container $j ..."
		echo ''
		sudo lxc-start -n $j > /dev/null 2>&1
		i=1
		while [ "$PublicIPIterative" != 1020729 ] && [ "$i" -le 10 ]
		do
			echo "Waiting for $j Public IP to come up..."
			echo ''
			sleep 10
			PublicIPIterative=$(CheckPublicIPIterative)
			if [ $i -eq 5 ]
			then
				if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 6 ]
				then
					sudo lxc-stop -n $j -k > /dev/null 2>&1
				else
					sudo lxc-stop -n $j    > /dev/null 2>&1
				fi
				sudo /etc/network/openvswitch/veth_cleanups.sh oel$OracleRelease$SeedPostfix
				echo ''
				sudo lxc-start -n $j > /dev/null 2>&1
			fi
		sleep 1
		i=$((i+1))
		done
	done
	
	echo "=============================================="
	echo "Done: Start Oracle Linux seed LXC container..."
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Waiting for final container initialization.   " 
	echo "=============================================="
fi

echo ''
echo "==============================================" 
echo "Public IP is up on oel$OracleRelease$SeedPostfix"
echo ''
sudo lxc-ls -f
echo ''
echo "=============================================="
echo "Container Up.                                 "
echo "=============================================="

sleep 10

clear

function GetMultiHostVar4 {
        echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

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
echo "Container oel$OracleRelease$SeedPostfix ping test..."
echo "=============================================="
echo ''

function CheckNetworkUp {
ping -c 3 oel$OracleRelease$SeedPostfix | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
n=1
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -le 5 ]
do
NetworkUp=$(CheckNetworkUp)
n=$((n+1))
done

ping -c 3 oel$OracleRelease$SeedPostfix

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "Container oel$OracleRelease$SeedPostfix not pinging."
echo "=============================================="
else
echo ''
echo "=============================================="
echo "Container oel$OracleRelease$SeedPostfix is pingable."
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Testing connectivity to oel$OR$SeedPostfix... "
echo "=============================================="
echo ''
echo "=============================================="
echo "Output of 'uname -a' in oel$OR$SeedPostfix..."
echo "=============================================="
echo ''

sudo lxc-attach -n oel$OracleRelease$SeedPostfix -- uname -a
if [ $? -ne 0 ]
then
echo ''
echo "=============================================="
echo "lxc-attach is failing...see if selinux is set."
echo "Script exiting.                               "
echo "=============================================="
exit
fi
echo ''
echo "=============================================="
echo "Test lxc-attach oel$OracleRelease$SeedPostfix successful. "
echo "=============================================="

sleep 5

clear

echo ''
echo "==============================================" 
echo "Next script to run: uekulele-services-3.sh    "
echo "=============================================="

sleep 5
