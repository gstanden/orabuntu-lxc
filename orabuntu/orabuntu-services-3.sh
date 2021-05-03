#!/bin/bash

#    Copyright 2015-2021 Gilbert Standen
#    This file is part of Orabuntu-LXC.

#    Orabuntu-LXC is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-LXC is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

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

if [ -e /sys/hypervisor/uuid ]
then
	function CheckAWS {
        	cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
	}
	AWS=$(CheckAWS)
fi

function GetMultiHostVar1 {
echo $MultiHost | cut -f1 -d':'
}
MultiHostVar1=$(GetMultiHostVar1)

function GetMultiHostVar2 {
echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar3 {
echo $MultiHost | cut -f3 -d':'
}
MultiHostVar3=$(GetMultiHostVar3)

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

function GetMultiHostVar8 {
        echo $MultiHost | cut -f8 -d':'
}
MultiHostVar8=$(GetMultiHostVar8)

function GetMultiHostVar9 {
        echo $MultiHost | cut -f9 -d':'
}
MultiHostVar9=$(GetMultiHostVar9)

function GetMultiHostVar10 {
        echo $MultiHost | cut -f10 -d':'
}
MultiHostVar10=$(GetMultiHostVar10)
GREValue=$MultiHostVar10
GRE=$GREValue

function GetMultiHostVar11 {
        echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)

function GetMultiHostVar12 {
        echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)
LXDValue=$MultiHostVar12
LXD=$MultiHostVar12

function GetMultiHostVar13 {
        echo $MultiHost | cut -f13 -d':'
}
MultiHostVar13=$(GetMultiHostVar13)

function GetMultiHostVar14 {
        echo $MultiHost | cut -f14 -d':'
}
MultiHostVar14=$(GetMultiHostVar14)
PreSeed=$MultiHostVar14

function GetMultiHostVar15 {
        echo $MultiHost | cut -f15 -d':'
}
MultiHostVar15=$(GetMultiHostVar15)
LXDCluster=$MultiHostVar15

function GetMultiHostVar16 {
        echo $MultiHost | cut -f16 -d':'
}
MultiHostVar16=$(GetMultiHostVar16)
StorageDriver=$MultiHostVar16

function GetMultiHostVar17 {
        echo $MultiHost | cut -f17 -d':'
}
MultiHostVar17=$(GetMultiHostVar17)
StoragePoolName=$MultiHostVar17

function GetMultiHostVar18 {
        echo $MultiHost | cut -f18 -d':'
}
MultiHostVar18=$(GetMultiHostVar18)
BtrfsLun=$MultiHostVar18

function GetMultiHostVar19 {
        echo $MultiHost | cut -f19 -d':'
}
MultiHostVar19=$(GetMultiHostVar19)
Docker=$MultiHostVar19

function GetMultiHostVar20 {
        echo $MultiHost | cut -f20 -d':'
}
MultiHostVar20=$(GetMultiHostVar20)
TunType=$MultiHostVar20

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

if   [ $LXD = 'N' ]
then
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

elif [ $LXD = 'Y' ]
then
        if [ $GRE = 'Y' ] && [ $LXDCluster = 'Y' ]
        then
                sudo sed -i "s/mtu_request=1500/mtu_request=$MultiHostVar7/g" /etc/network/openvswitch/crt_ovs_sw1.sh
                sudo sed -i "s/mtu_request=1500/mtu_request=$MultiHostVar7/g" /etc/network/openvswitch/crt_ovs_sx1.sh
        fi
	
	function GetSeedContainerName {
		lxc list | grep oel$OracleRelease | sort -d | cut -f2 -d' ' | sed 's/^[ \t]*//;s/[ \t]*$//' | tail -1
	}
	SeedContainerName=$(GetSeedContainerName)
fi

echo ''
echo "==============================================" 
echo "Show IP on $SeedContainerName...              "
echo "==============================================" 
echo ''

if   [ $LXD = 'N' ]
then
	sudo lxc-ls -f

elif [ $LXD = 'Y' ]
then
	lxc list
fi

echo ''
echo "==============================================" 
echo "Done: Show IP on $SeedContainerName.          "
echo "==============================================" 
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Test connectivity to $SeedContainerName...    "
echo "=============================================="
echo ''
echo "=============================================="
echo "Output of 'uname -a' in $SeedContainerName... "
echo "=============================================="
echo ''

if   [ $LXD = 'N' ]
then
	sudo lxc-attach -n $SeedContainerName -- uname -a

elif [ $LXD = 'Y' ]
then
	lxc exec $SeedContainerName -- uname -a
fi

echo ''
echo "=============================================="
echo "Done: Test connectivity to $SeedContainerName."
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Configure $SeedContainerName...               "
echo "=============================================="
echo ''

if   [ $LXD = 'N' ]
then
	sudo lxc-attach -n $SeedContainerName -- usermod --password `perl -e "print crypt('root','root');"` root
	sudo lxc-attach -n $SeedContainerName -- yum -y install openssh-server net-tools
	sudo lxc-attach -n $SeedContainerName -- service sshd restart

elif [ $LXD = 'Y' ]
then
	lxc exec $SeedContainerName -- usermod --password `perl -e "print crypt('root','root');"` root
	lxc exec $SeedContainerName -- yum -y install openssh-server net-tools
	lxc exec $SeedContainerName -- service sshd restart
fi

echo ''
echo "=============================================="
echo "Done: Configure $SeedContainerName.           "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: $Product                  "
echo "=============================================="

sleep 5
