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

#    You should have received a copy of the GNU General Public License
#    along with Orabuntu-LXC.  If not, see <http://www.gnu.org/licenses/>.

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain2=$3
MultiHost=$4
DistDir=$5
Product=$6

echo ''
echo "=============================================="
echo "Script:  uekulele-services-3.sh                 "
echo "                                              "
echo "This script installs packages into the Oracle "
echo "Linux container required for running Oracle.  "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="

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
GRE=$MultiHostVar10
GREValue=$MultiHostVar10

function GetMultiHostVar11 {
        echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)

function GetMultiHostVar12 {
        echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)
LXDValue=$MultiHostVar12
LXD=$LXDValue

function GetMultiHostVar13 {
        echo $MultiHost | cut -f13 -d':'
}
MultiHostVar13=$(GetMultiHostVar13)
K8S=$MultiHostVar13

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
LXDStorageDriver=$MultiHostVar16

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

function CheckCgroupType {
        ls /sys/fs/cgroup | egrep 'memory|cpuset' | grep -cv '\.'
}
CgroupType=$(CheckCgroupType)

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
	RHV=$RedHatVersion
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
                function GetRedHatVersion {
                        sudo cat /etc/redhat-release | rev | cut -f2 -d' ' | cut -f2 -d'.'
                }
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
        fi
	RedHatVersion=$(GetRedHatVersion)
	RHV=$RedHatVersion
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
	RHV=$RedHatVersion
        if   [ $RedHatVersion -ge 28 ]
        then
                Release=8
        elif [ $RedHatVersion -ge 19 ] && [ $RedHatVersion -le 27 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
        RL=$Release
	export FEDORA_SUFFIX='> /dev/null 2>&1'
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
                                	if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 6 ]
                                	then
                                        	sudo lxc-stop -n $j -k > /dev/null 2>&1
                                	else
                                        	sudo lxc-stop -n $j    > /dev/null 2>&1
                                	fi
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
	echo ''
	echo "=============================================="
	echo "Evaluate CGROUP_SUFFIX variable...            "
	echo "=============================================="
	echo ''

	function GetCgroupv2Warning1 {
	        echo "/var/lib/snapd/snap/bin/lxc cluster list" | sg lxd 2> >(grep -c 'WARNING: cgroup v2 is not fully supported yet, proceeding with partial confinement') >/dev/null
	}
	Cgroupv2Warning1=$(GetCgroupv2Warning1)

	if [ $Cgroupv2Warning1 -eq 1 ]
	then
	        echo "=============================================="
	        echo "On $LinuxFlavor $RedHatVersion the WARNING:   "
	        echo "                                              "
	        echo "WARNING: cgroup v2 is not fully supported yet "
	        echo "proceeding with partial confinement.          "
	        echo "                                              "
	        echo "can be safely IGNORED.                        "
	        echo "This is a snapd issue not an LXD issue.       "
	        echo "                                              "
	        echo "This specific warning has been suppressed     "
	        echo "during this install of Orabuntu-LXC.          "
	        echo "                                              "
	        echo " More info here:                              "
	        echo "                                              "
	        echo "https://discuss.linuxcontainers.org/t/lxd-cgroup-v2-support/10455"
	        echo "https://bugs.launchpad.net/ubuntu/+source/snapd/+bug/1850667"
	        echo "                                              "
	        echo "=============================================="

	        CGROUP_SUFFIX='2>/dev/null'
	else
		CGROUP_SUFFIX=''
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Done: Evaluate CGROUP_SUFFIX variable.        "
	echo "=============================================="
	echo ''

	sleep 10

	clear

	if [ $GRE = 'Y' ] && [ $LXDCluster = 'Y' ]
	then
		sudo sed -i "s/mtu_request=1500/mtu_request=$MultiHostVar7/g" /etc/network/openvswitch/crt_ovs_sw1.sh
		sudo sed -i "s/mtu_request=1500/mtu_request=$MultiHostVar7/g" /etc/network/openvswitch/crt_ovs_sx1.sh
	fi

        function GetSeedContainerName {
		eval echo "'/var/lib/snapd/snap/bin/lxc list -c n -f csv | grep oel$OracleRelease | sort -d | tail -1' | sg lxd $CGROUP_SUFFIX"
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
        eval echo "'/var/lib/snapd/snap/bin/lxc list' | sg lxd $CGROUP_SUFFIX"  
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
        eval echo "'/var/lib/snapd/snap/bin/lxc exec $SeedContainerName -- uname -a' | sg lxd $CGROUP_SUFFIX"  
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
#	eval echo "'/var/lib/snapd/snap/bin/lxc exec $SeedContainerName -- usermod --password `perl -e "print crypt('root','root');"` root' | sg lxd $CGROUP_SUFFIX"  
#	eval echo "'/var/lib/snapd/snap/bin/lxc exec $SeedContainerName -- yum -y install openssh-server net-tools' | sg lxd $CGROUP_SUFFIX"  
#	eval echo "'/var/lib/snapd/snap/bin/lxc exec $SeedContainerName -- service sshd restart' | sg lxd $CGROUP_SUFFIX"  
	eval echo "'/var/lib/snapd/snap/bin/lxc exec $SeedContainerName -- rpm -qa | grep openssh-server' | sg lxd $CGROUP_SUFFIX"  
	eval echo "'/var/lib/snapd/snap/bin/lxc exec $SeedContainerName -- rpm -qa | grep net-tools'      | sg lxd $CGROUP_SUFFIX"  
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
