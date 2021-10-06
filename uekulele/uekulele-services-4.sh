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
NumCon=$3
NameServer=$4
MultiHost=$5
DistDir=$6
Product=$7

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetLXCVersion {
        lxc-create --version
}
LXCVersion=$(GetLXCVersion)

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
	export FEDORA_SUFFIX='2>/dev/null'
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

clear

echo ''
echo "=============================================="
echo "Next script to run: uekulele-services-4.sh    "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Script:  uekulele-services-4.sh NumCon        "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script clones additional containers.     "
echo "=============================================="
echo ''
echo "=============================================="
echo "NumCon is the number of containers            "
echo "NumCon (small integer)                        "
echo "NumCon defaults to value '2'                  "
echo "=============================================="

sleep 5

clear

if [ -z $3 ]
then
	NumCon=2
else
	NumCon=$3
fi

ContainerPrefixLXC=ora$1$2c
CPC=ora$1$2c

ContainerPrefixLXD=ora$1$2d
CPD=ora$1$2d

CP=$ContainerPrefixLXC

if   [ $LXD = 'N' ]
then
#	function GetSeedContainerName {
#		sudo ls -l /var/lib/lxc | rev | cut -f1 -d' ' | rev | grep oel$OracleRelease | cut -f1 -d' '
#	}
#	SeedContainerName=$(GetSeedContainerName)

	function GetSeedContainerName {
		sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '
		}
	SeedContainerName=$(GetSeedContainerName)

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

        echo ''
        echo "=============================================="
        echo "Done: Evaluate CGROUP_SUFFIX variable.        "
        echo "=============================================="
        echo ''

	sleep 10

	clear

        function GetSeedContainerName {
                eval echo "'/var/lib/snapd/snap/bin/lxc list -c n -f csv | grep oel$OracleRelease | sort -d | tail -1' | sg lxd $CGROUP_SUFFIX"
        }
        SeedContainerName=$(GetSeedContainerName)
fi

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

if [ $LXD = 'N' ]
then
        echo ''
        echo "=============================================="
        echo "Update config if LXC v2.0 or lower...          "
        echo "=============================================="
        echo ''

        sleep 5

        clear

        # Case 1 Creating Oracle Seed Container in 2.0- LXC enviro.

        function CheckOracleSeedConfigFormat {
                sudo egrep -c 'lxc.net.0|lxc.net.1|lxc.uts.name|lxc.apparmor.profile' /var/lib/lxc/$SeedContainerName/config
        }
        OracleSeedConfigFormat=$(CheckOracleSeedConfigFormat)

        if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion 2.1.0) ] && [ $OracleSeedConfigFormat -gt 0 ]
        then
                sudo sed -i 's/lxc.net.0/lxc.network/g'                 /var/lib/lxc/$SeedContainerName/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'                 /var/lib/lxc/$SeedContainerName/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'              /var/lib/lxc/$SeedContainerName/config
                sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'   /var/lib/lxc/$SeedContainerName/config
        fi

        # Case 2 importing nameserver from an 2.0- LXC enviro into a 2.1+ LXC enviro (typically this if-then will never be called).

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion 2.1.0) ] && [ $OracleSeedConfigFormat -eq 0 ]
        then
                sudo lxc-update-config -c /var/lib/lxc/$SeedContainerName/config
        fi

        echo ''
        echo "=============================================="
        echo "Done: Update config if LXC v2.0 or lower.      "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

if   [ $LXD = 'N' ]
then
        echo ''
        echo "=============================================="
        echo "Number of LXC Container Nodes = $NumCon       "
        echo "=============================================="
        echo ''

elif [ $LXD = 'Y' ]
then
        echo ''
        echo "=============================================="
        echo "Number of LXD Container Nodes = $NumCon       "
        echo "=============================================="
        echo ''
fi

echo "=============================================="
echo "This script creates container clones          "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Stopping $SeedContainerName seed container...  "
echo "=============================================="
echo ''

if   [ $LXD = 'N' ]
then
        function CheckContainerUp {
                sudo lxc-ls -f | grep $SeedContainerName | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
        }
        ContainerUp=$(CheckContainerUp)
        sudo lxc-stop -n $SeedContainerName > /dev/null 2>&1

elif [ $LXD = 'Y' ]
then
        function CheckContainerUp {
		eval echo "'/var/lib/snapd/snap/bin/lxc list -c ns -f csv | grep oel$OracleRelease | sort -d | tail -1 | cut -f2 -d','' | sg lxd $CGROUP_SUFFIX"
        }
        ContainerUp=$(CheckContainerUp)
        eval echo "'/var/lib/snapd/snap/bin/lxc stop $SeedContainerName --force' | sg lxd $CGROUP_SUFFIX"  
fi

while [ "$ContainerUp" = 'RUNNING' ]
do
        sleep 1
        ContainerUp=$(CheckContainerUp)
done

if   [ $LXD = 'N' ]
then
        sudo lxc-ls -f

elif [ $LXD = 'Y' ]
then
        eval echo "'/var/lib/snapd/snap/bin/lxc list' | sg lxd $CGROUP_SUFFIX"  
fi

echo ''
echo "=============================================="
echo "Seed container stopped.                       "
echo "=============================================="

sleep 5

clear

if [ $MultiHostVar2 = 'Y' ]
then
        if   [ $LXD = 'N' ]
        then
                sudo sed -i "s/MtuSetting/$MultiHostVar7/g" /var/lib/lxc/$SeedContainerName/config
        fi
fi

echo ''
echo "=============================================="
echo "OpenvSwitch Networking for $Product ...       "
echo "=============================================="
echo ''

sleep 5

clear

if   [ $LXD = 'N' ]
then
        sudo /opt/olxc"$DistDir"/products/$Product/$Product.net $MultiHostVar1
fi

echo ''
echo "=============================================="
echo "Done: OpenvSwitch Networking for $Product.    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Restart OpenvSwitches...                      "
echo "=============================================="
echo ''

SwitchList='sw1 sx1'
for k in $SwitchList
do
	sudo ifconfig $k >/dev/null 2>&1
	IfCon=`echo $?`
	n=1
	while [ $IfCon -ne 0 ] && [ $n -le 5 ]
	do
        	sudo ifconfig $k >/dev/null 2>&1
        	IfCon=`echo $?`
        	n=$((n+1))
        	sleep 5
	done

	sudo ifconfig $k
done

echo ''
sudo iptables -S | egrep 'sw1|sx1'

echo ''
echo "=============================================="
echo "Done: Restart OpenvSwitches.                  "
echo "=============================================="
echo ''

sleep 5

clear

if   [ $LXD = 'N' ]
then
	if [ -f /var/lib/lxc/$SeedContainerName/rootfs/root/lxc-services.sh ]
	then
        	sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/$SeedContainerName/rootfs/root/lxc-services.sh >/dev/null 2>&1
	fi
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Clone $SeedContainerName to $NumCon containers"
echo "=============================================="
echo ''

sleep 5

clear

let CloneIndex=10
let CopyCompleted=0

while [ $CopyCompleted -lt $NumCon ]
do
	# GLS 20210107 updated to use getent instead of nslookup for indexing check for Fedora 31+
        # GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
        # GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

        RedHatVersion=$(GetRedHatVersion)

	if   [ $LXD = 'N' ]
	then
		if [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 8 ]
		then
			function CheckDNSLookup {
				timeout 5 nslookup $ContainerPrefixLXC$CloneIndex
			}
			DNSLookup=$(CheckDNSLookup)
			DNSLookup=`echo $?`
		else
			function CheckDNSLookup {
				timeout 5 nslookup $ContainerPrefixLXC$CloneIndex
			}
			DNSLookup=$(CheckDNSLookup)
			DNSLookup=`echo $?`
		fi
	
	elif [ $LXD = 'Y' ]
	then
		if [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 8 ]
		then
			function CheckDNSLookup {
				timeout 5 nslookup $ContainerPrefixLXD$CloneIndex
			}
			DNSLookup=$(CheckDNSLookup)
			DNSLookup=`echo $?`
		else
			function CheckDNSLookup {
				timeout 5 nslookup $ContainerPrefixLXD$CloneIndex
			}
			DNSLookup=$(CheckDNSLookup)
			DNSLookup=`echo $?`
		fi
	fi

        while [ $DNSLookup -eq 0 ]
        do
                CloneIndex=$((CloneIndex+1))
                DNSLookup=$(CheckDNSLookup)
                DNSLookup=`echo $?`
        done

        if   [ $LXD = 'N' ]
        then
                echo ''
                echo "=============================================="
                echo "Clone $SeedContainerName to $CPC$CloneIndex   "
                echo "=============================================="
                echo ''

                echo "Clone Container Name = $CPC$CloneIndex"

                sleep 5

        elif  [ $LXD = 'Y' ]
        then
                CI=$CloneIndex
                echo ''
                echo "=============================================="
                echo "Clone $SeedContainerName to $CPD$CI...        "
                echo "=============================================="
                echo ''

                eval echo "'/var/lib/snapd/snap/bin/lxc copy $SeedContainerName $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  

		# GLS 2021-07-19 Workaround for Oracle 8 using privileged container option.
                # GLS 2021-07-19 See https://discuss.linuxcontainers.org/t/centos8-containers-unable-to-automatically-get-ipv4-addresses-after-update/11273/22 for more information.

                if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Oracle' ]
                then
                        eval echo "'/var/lib/snapd/snap/bin/lxc config set oel$OracleRelease$SeedPostfix security.privileged true' | sg lxd $CGROUP_SUFFIX"  
                fi
                
		if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Fedora' ]
                then
                        eval echo "'/var/lib/snapd/snap/bin/lxc config set oel$OracleRelease$SeedPostfix security.privileged true' | sg lxd $CGROUP_SUFFIX"  
                fi

                eval echo "'/var/lib/snapd/snap/bin/lxc list $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  

                echo ''
                echo "=============================================="
                echo "Done: Clone $SeedContainerName to $CPD$CI     "
                echo "=============================================="
                echo ''

                sleep 5

                clear
        fi

	if [ $LXD = 'N' ]
	then
      		sudo lxc-copy -n $SeedContainerName -N $ContainerPrefixLXC$CloneIndex

		if [ $MajorRelease -eq 6 ]
		then
               		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/hostname
		fi

		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"        	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
		sudo sed -i "s/HostName/$ContainerPrefixLXC$CloneIndex/g"        		/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"        	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network
		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"        	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/hosts

                sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"                             /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
                sudo sed -i "s/\.10/\.$CloneIndex/g"                                                            /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
                sudo sed -i 's/sx1/sw1/g'                                                                       /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
        #       sudo sed -i 's/sx1a/sw1a/g'                                                                     /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
                sudo sed -i "s/mtu = 1500/mtu = $MultiHostVar7/g"                                               /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
        #       sudo sed -i "s/lxc\.mount\.entry = \/dev\/lxc_luns/#lxc\.mount\.entry = \/dev\/lxc_luns/g"      /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
        #       sudo sed -i "/domain-name-servers/s/10.207.29.2/10.207.39.2/g"                                  /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/dhcp/dhclient.conf
        #       sudo rm  -f                                                                                     /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/machine-id
        #       sudo systemd-machine-id-setup                                                            --root=/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs

                echo ''
                echo "==============================================  "
                echo "Done: Clone $SeedContainerName to $CPC$CloneIndex"
                echo "==============================================  "
                echo ''

                sleep 5

                clear

		echo ''
		echo "=============================================="
		echo "OpenvSwitch Networking for $Product ...       "
		echo "=============================================="
		echo ''

		sudo /opt/olxc"$DistDir"/products/$Product/$Product.cnf $ContainerPrefixLXC $CloneIndex $Product $MultiHostVar1
	
		echo ''
		echo "=============================================="
		echo "Done: OpenvSwitch Networking for $Product.    "
		echo "=============================================="
		echo ''

		sleep 5

		function GetHostName (){ echo $ContainerPrefixLXC$CloneIndex\1; }
		HostName=$(GetHostName)

		sudo sed -i "s/$HostName/$ContainerPrefixLXC$CloneIndex/" /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network

		if [ $Release -ge 7 ]
		then
			echo ''
			echo "=============================================="
			echo "Create $CPC$CloneIndex Onboot Service...       "
			echo "=============================================="

			sudo sh -c "echo '#!/bin/bash'										>  /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '#'											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '# Manage the Oracle RAC LXC containers'						>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '#'											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo 'start() {'										>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '  exec lxc-start -n $ContainerPrefixLXC$CloneIndex > /dev/null 2>&1'			>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '}'											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo ''											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo 'stop() {'										>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '  exec lxc-stop -n $ContainerPrefixLXC$CloneIndex > /dev/null 2>&1'			>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '}'											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo ''											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo 'case \$1 in'										>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo '  start|stop) \"\$1\" ;;'								>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
			sudo sh -c "echo 'esac'											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"

			sudo chmod +x /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh
	
			sudo sh -c "echo '[Unit]'                                                        			>  /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'Description=$ContainerPrefixLXC$CloneIndex Service'                               	>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'Wants=network-online.target sw1.service $NameServer.service'          		>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'After=network-online.target sw1.service $NameServer.service'          		>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo ''                                                             			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo '[Service]'                                                    			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'Type=oneshot'                                                 			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'User=root'                                                    			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'RemainAfterExit=yes'                                          			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh start' 	>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh stop'   	>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo ''                                                             			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo '[Install]'                                                    			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
			sudo sh -c "echo 'WantedBy=multi-user.target'                                   			>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
	
			sudo chmod 644 /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service
	
			echo ''
			sudo cat /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service
			echo ''
			sudo systemctl enable $ContainerPrefixLXC$CloneIndex
	
			echo ''
			echo "=============================================="
			echo "Created $CPC$CloneIndex Onboot Service.        "
			echo "=============================================="
			echo ''

        		if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
        		then
                		sudo lxc-update-config -c /var/lib/lxc/$CPC$CloneIndex/config
        		fi

			CopyCompleted=$((CopyCompleted+1))
			CloneIndex=$((CloneIndex+1))

			sleep 5

			clear

		elif [ $Release -eq 6 ]
		then
			echo ''
			echo "=============================================="
			echo "Create $CPC$CloneIndex Onboot Service...       "
			echo "=============================================="
			echo ''

			sudo cp -p /etc/network/openvswitch/container-service-linux6.sh /etc/init.d/lxc_$ContainerPrefixLXC$CloneIndex
			sudo sed -i "s/LXCON/$ContainerPrefixLXC$CloneIndex/g" /etc/init.d/lxc_$ContainerPrefixLXC$CloneIndex
			sudo chmod 755 /etc/init.d/lxc_$ContainerPrefixLXC$CloneIndex
			sudo chown $Owner:$Group /etc/init.d/lxc_$ContainerPrefixLXC$CloneIndex
			sudo chkconfig --add lxc_$ContainerPrefixLXC$CloneIndex
			sudo chkconfig lxc_$ContainerPrefixLXC$CloneIndex on --level 345
			sudo chkconfig --list lxc_$ContainerPrefixLXC$CloneIndex
		
			echo ''
			echo "=============================================="
			echo "Done: Create $CPC$CloneIndex Onboot Service.   "
			echo "=============================================="
        	
			if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
        		then
                		sudo lxc-update-config -c /var/lib/lxc/$CPC$CloneIndex/config
        		fi

			CopyCompleted=$((CopyCompleted+1))
			CloneIndex=$((CloneIndex+1))

			sleep 5

			clear
		fi

	elif [ $LXD = 'Y' ]
	then
                echo ''
                echo "=============================================="
                echo "Configure $ContainerPrefixLXD$CI...           "
                echo "=============================================="
                echo ''
                echo "=============================================="
                echo "Assign Profile $ContainerPrefixLXD$CI...      "
                echo "=============================================="
                echo ''

                eval echo "'/var/lib/snapd/snap/bin/lxc profile assign $ContainerPrefixLXD$CloneIndex olxc_sw1a' | sg lxd $CGROUP_SUFFIX"  

                echo ''
                echo "=============================================="
                echo "Done: Assign Profile $ContainerPrefixLXD$CI.  "
                echo "=============================================="

		if [ $MajorRelease -ge 8 ]
		then
                	echo ''
                	echo "=============================================="
                	echo "Set Machine-ID  $ContainerPrefixLXD$CI...     "
                	echo "=============================================="
                	echo ''

        		echo "/var/lib/snapd/snap/bin/lxc file delete $ContainerPrefixLXD$CloneIndex/etc/machine-id"
                	eval echo "'/var/lib/snapd/snap/bin/lxc file delete $ContainerPrefixLXD$CloneIndex/etc/machine-id' | sg lxd $CGROUP_SUFFIX" 

                	sleep 5

                	eval echo "'/var/lib/snapd/snap/bin/lxc start $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  

                	sleep 5

                	n=1
                	while [ $n -ne 0 ]
                	do
                        	eval echo "'/var/lib/snapd/snap/bin/lxc exec  $ContainerPrefixLXD$CloneIndex -- systemd-machine-id-setup > /dev/null 2>&1' | sg lxd $CGROUP_SUFFIX"  
                        	n=`echo $?`
                        	sleep 5
                	done

                	eval echo "'/var/lib/snapd/snap/bin/lxc stop  $ContainerPrefixLXD$CloneIndex --force' | sg lxd $CGROUP_SUFFIX" 
                	eval echo "'/var/lib/snapd/snap/bin/lxc start $ContainerPrefixLXD$CloneIndex' 	      | sg lxd $CGROUP_SUFFIX"  

                	echo ''
                	echo "=============================================="
                	echo "Done: Set Machine-ID $ContainerPrefixLXD$CI.  "
                	echo "=============================================="
                	echo ''
                	echo "=============================================="
                	echo "Set hostnamectl $ContainerPrefixLXD$CI...     "
                	echo "=============================================="
                	echo ''

                	n=1
                	while [ $n -ne 0 ]
                	do
                        	eval echo "'/var/lib/snapd/snap/bin/lxc exec $ContainerPrefixLXD$CloneIndex -- hostnamectl set-hostname $ContainerPrefixLXD$CloneIndex > /dev/null 2>&1' | sg lxd $CGROUP_SUFFIX"  
                        	n=`echo $?`
                        	sleep 5
                	done

                	eval echo "'/var/lib/snapd/snap/bin/lxc exec $ContainerPrefixLXD$CloneIndex -- hostnamectl' | sg lxd $CGROUP_SUFFIX"  

                	echo ''
                	echo "=============================================="
                	echo "Done: Set hostnamectl $ContainerPrefixLXD$CI. "
                	echo "=============================================="
                	echo ''

                	sleep 5
                	
			clear

                	echo ''
                	echo "=============================================="
                	echo "Restart $ContainerPrefixLXD$CI...             "
                	echo "=============================================="
                	echo ''

                	eval echo "'/var/lib/snapd/snap/bin/lxc stop  $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  
                	eval echo "'/var/lib/snapd/snap/bin/lxc start $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  
                	eval echo "'/var/lib/snapd/snap/bin/lxc list  $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  

                	echo ''
                	echo "=============================================="
                	echo "Done: Restart $ContainerPrefixLXD$CI.         "
                	echo "=============================================="
                	echo ''

                	sleep 5

                	clear
		else
                	eval echo "'/var/lib/snapd/snap/bin/lxc start $ContainerPrefixLXD$CloneIndex' | sg lxd $CGROUP_SUFFIX"  
		fi

                echo ''
                echo "=============================================="
                echo "Done: Configure $ContainerPrefixLXD$CI        "
                echo "=============================================="
                echo ''

	#	sleep 10

	#	clear

	#	echo ''
	#	echo "=============================================="
	#	echo "nslookup $ContainerPrefixLXD$CI...            "
	#	echo "=============================================="
	#	echo ''

	#	nslookup $ContainerPrefixLXD$CloneIndex

	#	echo "=============================================="
	#	echo "Done: nslookup $ContainerPrefixLXD$CI.        "
	#	echo "=============================================="
	#	echo ''
        
		CopyCompleted=$((CopyCompleted+1))
        	CloneIndex=$((CloneIndex+1))
        fi

        sleep 5

        clear
done

echo ''
echo "=============================================="
echo "Container cloning completed.                  "
echo "=============================================="

sleep 5

clear

if [ $LXD = 'N' ]
then
#	echo ''
#	echo "=============================================="
#	echo "Creating OpenvSwitch files ...                "
#	echo "=============================================="
#	echo ''

#	sleep 5

#	sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefix $NumCon $NewHighestContainerIndex $HighestContainerIndex
#	sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefix $NumCon $CloneIndex

#	echo ''
#	echo "=============================================="
#	echo "Creating OpenvSwitch files complete.          "
#	echo "=============================================="

#	sleep 5

#	clear

	if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
	then
        	echo ''
        	echo "=============================================="
        	echo "Update config for LXC 2.1.0+                  "
        	echo "=============================================="
        	echo ''

        	sudo lxc-update-config -c /var/lib/lxc/$SeedContainerName/config

		sleep 5

		clear

        	echo ''
        	echo "=============================================="
        	echo "Done: Update config for LXC 2.1.0+            "
        	echo "=============================================="
        	echo ''
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Start Seed Container $SeedContainerName...    "
	echo "=============================================="
	echo ''

	sudo lxc-start -n $SeedContainerName > /dev/null 2>&1
	sleep 5
	sudo lxc-ls -f

	echo ''
	echo "=============================================="
	echo "Done: Start Seed Container $SeedContainerName."
	echo "=============================================="

	sleep 5

	clear

        echo ''
        echo "=============================================="
        echo "Configure LXC Containers...                   "
        echo "=============================================="
        echo ''

elif [ $LXD = 'Y' ]
then
        echo ''
        echo "=============================================="
        echo "Configure LXD Containers...                   "
        echo "=============================================="
        echo ''
fi

sleep 5

clear

if [ $LXD = 'N' ]
then
	function GetClonedContainers {
		sudo ls /var/lib/lxc | grep "ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ClonedContainers=$(GetClonedContainers)

	for j in $ClonedContainers
	do
        	if [ -e /var/lib/lxc/$j/rootfs/var/run/dhclient.pid ]
        	then
                	sudo rm -f /var/lib/lxc/$j/rootfs/var/run/dhclient.pid
        	fi

        #	sudo lxc-start  -n $j > /dev/null 2>&1
        	sudo lxc-start  -n $j 

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Set Host and Machine-ID in Clone in $j...     "
		echo "=============================================="
		echo ''

		sudo lxc-attach -n $j -- rm -f /etc/machine-id
		sudo lxc-attach -n $j -- systemd-machine-id-setup
		sudo lxc-stop   -n $j
		sleep 5
		sudo lxc-start  -n $j

		echo ''
		echo "=============================================="
		echo "Done: Set Host and Machine-ID in Clone in $j. "
		echo "=============================================="
		echo ''

		sleep 15

        	if [ $MajorRelease -ge 7 ] && [ $Release -ge 7 ]
        	then
                	echo ''
                	echo "=============================================="
                	echo "Run hostnamectl in clone...                   "
                	echo "=============================================="
                	echo ''

                	sudo lxc-attach -n $j -- hostnamectl set-hostname $j
                	sudo lxc-stop   -n $j
                	sudo lxc-start  -n $j

                	echo ''
                	echo "=============================================="
                	echo "Done: Run hostnamectl in clone                "
                	echo "=============================================="
                	echo ''

                	sleep 5
        	fi

#		sudo lxc-ls -f
        	echo ''
	done

	echo ''
	echo "=============================================="
	echo "Done: Configure LXD Containers.               "
	echo "=============================================="
	echo ''

elif [ $LXD = 'Y' ]
then
	echo ''
	echo "=============================================="
	echo "Done: Configure LXD Containers.               "
	echo "=============================================="
	echo ''
fi

sleep 5

clear

if [ $LXD = 'Y' ]
then
	eval echo "'/var/lib/snapd/snap/bin/lxc start $SeedContainerName' | sg lxd $CGROUP_SUFFIX" 
fi

if [ $LXD = 'N' ]
then
	sudo lxc-start -n $SeedContainerName
fi

echo ''
echo "=============================================="
echo "Next script to run: uekulele-services-5.sh    "
echo "=============================================="

sleep 5
