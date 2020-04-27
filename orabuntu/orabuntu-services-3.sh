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
#
#!/bin/bash

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
MultiHost=$5
DistDir=$6
Product=$7

echo ''
echo "=============================================="
echo "Script:  orabuntu-services-3.sh               "
echo "                                              "
echo "This script installs required packages into   "
echo "the Oracle Linux container.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="

if [ -e /sys/hypervisor/uuid ]
then
	function CheckAWS {
        	cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
	}
	AWS=$(CheckAWS)
fi

function GetMultiHostVar2 {
        echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar4 {
        echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

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
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//' | sed 's/\!//'
}
LinuxFlavor=$(TrimLinuxFlavors)

if   [ $LinuxFlavor = 'Oracle' ]
then
        CutIndex=7
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
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                CutIndex=7
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                CutIndex=4
        fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
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

if [ -f /etc/lsb-release ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
fi
RL=$UbuntuVersion

if [ -f /etc/lsb-release ]
then
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

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

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetLXCVersion {
	lxc-create --version
}
LXCVersion=$(GetLXCVersion)

function CheckSystemdResolvedInstalled {
	        sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
	}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

sleep 5

clear

echo ''
echo "=============================================="
echo "Ping yum.oracle.com test...                       "
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
echo "Ping yum.oracle.com not reliable.                 "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Ping yum.oracle.com is reliable.                  "
echo "=============================================="
echo ''
fi

sleep 5

clear

function CheckSearchDomain2 {
        grep -c $Domain2 /etc/resolv.conf
}
SearchDomain2=$(CheckSearchDomain2)

if [ $SearchDomain2 -eq 0 ] && [ $AWS -eq 0 ]
then
        sudo sed -i '/search/d' /etc/resolv.conf
        sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1' >> /etc/resolv.conf"
fi

echo ''
echo "=============================================="
echo "Initialize LXC Seed Container on OpenvSwitch.."
echo "=============================================="

cd /etc/network/if-up.d/openvswitch

# GLS 20151222 I don't think this step does anything anymore.  Commenting for now, removal pending.
# sudo sed -i "s/lxcora01/oel$OracleRelease$SeedPostfix/" /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

function GetSeedPostfix {
        sudo lxc-ls -f | grep oel"$OracleRelease"c | cut -f1 -d' ' | cut -f2 -d'c' | sed 's/^/c/'
}
SeedPostfix=$(GetSeedPostfix)

function CheckContainerUp {
	sudo lxc-ls -f | grep oel$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

function CheckPublicIP {
	sudo lxc-info -n oel$OracleRelease$SeedPostfix -iH | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

function GetSeedContainerName {
	sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '	
}
SeedContainerName=$(GetSeedContainerName)

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
                echo "=============================================="
                echo "Display LXC Seed Container Name...            "
                echo "=============================================="
                echo ''
                echo $j
                echo ''
                echo "=============================================="
                echo "Done: Display LXC Seed Container Name.        "
                echo "=============================================="
                echo ''

                sleep 5

                # GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
                # GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

		UbuntuVersion=$(GetUbuntuVersion)

                if [ $UbuntuMajorVersion -ge 16 ]
                then
                        function CheckPublicIPIterative {
                                sudo lxc-info -n oel$OracleRelease$SeedPostfix -iH | cut -f1-3 -d'.' | sed 's/\.//g' | head -1
                        }
                fi
		PublicIPIterative=$(CheckPublicIPIterative)
		echo "Starting container $j ..."
		echo ''
                if [ $MultiHostVar2 = 'Y' ]
                then
                        sudo sed -i "s/MtuSetting/$MultiHostVar7/g" /var/lib/lxc/$j/config
                fi
		sudo lxc-start -n $j > /dev/null 2>&1
		i=1
		while [ "$PublicIPIterative" != 1020729 ] && [ "$i" -le 10 ]
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
                                if [ $MultiHostVar2 = 'Y' ]
                                then
                                        ls -l /var/lib/lxc/$j/config
                                        sudo sed -i "s/MtuSetting/$MultiHostVar7/g" /var/lib/lxc/$j/config
                                fi
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

if [ $SystemdResolvedInstalled -eq 1 ] && [ $UbuntuVersion != '16.04' ]
then
	sudo service systemd-resolved restart
fi

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
	echo "lxc-attach $SeedContainerName has issue.      "
	echo "lxc-attach $SeedContainerName must succeed.   "
	echo "Fix issues retry script.                      "
	echo "Script exiting.                               "
	echo "=============================================="
	exit
else
	sudo lxc-attach -n $SeedContainerName -- yum -y install openssh-server

	echo ''
	echo "=============================================="
	echo "lxc-attach $SeedContainerName successful.     "
	echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: $Product                  "
echo "=============================================="

sleep 5
