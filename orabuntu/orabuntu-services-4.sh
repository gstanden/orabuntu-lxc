#/bin/bash

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

if [ -e /sys/hypervisor/uuid ]
then
        function CheckAWS {
                cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
        }
        AWS=$(CheckAWS)
else
        AWS=0
fi

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

function GetMultiHostVar21 {
        echo $MultiHost | cut -f21 -d':'
}
MultiHostVar21=$(GetMultiHostVar21)
IscsiTarget=$MultiHostVar21

function GetMultiHostVar22 {
        echo $MultiHost | cut -f22 -d':'
}
MultiHostVar22=$(GetMultiHostVar22)
Lun1Name=$MultiHostVar22

function GetMultiHostVar23 {
        echo $MultiHost | cut -f23 -d':'
}
MultiHostVar23=$(GetMultiHostVar23)
Lun2Name=$MultiHostVar23

function GetMultiHostVar24 {
        echo $MultiHost | cut -f24 -d':'
}
MultiHostVar24=$(GetMultiHostVar24)
Lun3Name=$MultiHostVar24

function GetMultiHostVar25 {
        echo $MultiHost | cut -f25 -d':'
}
MultiHostVar25=$(GetMultiHostVar25)
Lun1Size=$MultiHostVar25

function GetMultiHostVar26 {
        echo $MultiHost | cut -f26 -d':'
}
MultiHostVar26=$(GetMultiHostVar26)
Lun2Size=$MultiHostVar26

function GetMultiHostVar27 {
        echo $MultiHost | cut -f27 -d':'
}
MultiHostVar27=$(GetMultiHostVar27)
Lun3Size=$MultiHostVar27

function GetMultiHostVar28 {
        echo $MultiHost | cut -f28 -d':'
}
MultiHostVar28=$(GetMultiHostVar28)
LogBlkSz=$MultiHostVar28

function GetMultiHostVar29 {
        echo $MultiHost | cut -f29 -d':'
}
MultiHostVar29=$(GetMultiHostVar29)
BtrfsRaid=$MultiHostVar29

function GetMultiHostVar30 {
        echo $MultiHost | cut -f30 -d':'
}
MultiHostVar30=$(GetMultiHostVar30)
ZfsMirror=$MultiHostVar30

function GetMultiHostVar31 {
        echo $MultiHost | cut -f31 -d':'
}
MultiHostVar31=$(GetMultiHostVar31)
BtrfsLun2=$MultiHostVar31

function GetMultiHostVar32 {
        echo $MultiHost | cut -f32 -d':'
}
MultiHostVar32=$(GetMultiHostVar32)
ZfsLun1=$MultiHostVar32

function GetMultiHostVar33 {
        echo $MultiHost | cut -f33 -d':'
}
MultiHostVar33=$(GetMultiHostVar33)
ZfsLun2=$MultiHostVar33

function GetMultiHostVar34 {
        echo $MultiHost | cut -f34 -d':'
}
MultiHostVar34=$(GetMultiHostVar34)
LxcLun1=$MultiHostVar34

function GetMultiHostVar35 {
        echo $MultiHost | cut -f35 -d':'
}
MultiHostVar35=$(GetMultiHostVar35)
IscsiTargetLunPrefix=$MultiHostVar35

function GetMultiHostVar36 {
        echo $MultiHost | cut -f36 -d':'
}
MultiHostVar36=$(GetMultiHostVar36)
IscsiVendor=$MultiHostVar36

function GetMultiHostVar37 {
        echo $MultiHost | cut -f37 -d':'
}
MultiHostVar37=$(GetMultiHostVar37)
ContainerRuntime=$MultiHostVar37

function GetMultiHostVar38 {
        echo $MultiHost | cut -f38 -d':'
}
MultiHostVar38=$(GetMultiHostVar38)
ContainerRuntime=$MultiHostVar38

function GetMultiHostVar39 {
        echo $MultiHost | cut -f39 -d':'
}
MultiHostVar39=$(GetMultiHostVar39)
ContainerRuntime=$MultiHostVar39

function GetMultiHostVar40 {
        echo $MultiHost | cut -f40 -d':'
}
MultiHostVar40=$(GetMultiHostVar40)
ContainerRuntime=$MultiHostVar40

function GetMultiHostVar41 {
        echo $MultiHost | cut -f41 -d':'
}
MultiHostVar41=$(GetMultiHostVar41)
BaseNet=$MultiHostVar41

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

echo ''
echo "=============================================="
echo "Next script to run: orabuntu-services-4.sh    "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Script:  orabuntu-services-4.sh NumCon        "
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
echo ''

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
	if   [ $UbuntuMajorVersion -eq 16 ]
	then
		function GetSeedContainerName {
			sudo ls -l /var/lib/lxc | rev | cut -f1 -d' ' | rev | grep oel$OracleRelease | cut -f1 -d' '
		}
		SeedContainerName=$(GetSeedContainerName)
	elif [ $UbuntuMajorVersion -gt 16 ]
	then
		function GetSeedContainerName {
			sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '
		}
		SeedContainerName=$(GetSeedContainerName)
	fi

elif [ $LXD = 'Y' ]
then
	function GetSeedContainerName {
		lxc list | grep oel$OracleRelease | sort -d | cut -f2 -d' ' | sed 's/^[ \t]*//;s/[ \t]*$//' | tail -1
	}
	SeedContainerName=$(GetSeedContainerName)
fi

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

if [ $LXD = 'N' ]
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
		lxc list | grep $SeedContainerName | sed 's/  */ /g' | egrep 'RUNNING|STOPPED' | cut -f4 -d' ' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ContainerUp=$(CheckContainerUp)
	lxc stop $SeedContainerName > /dev/null 2>&1
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
	lxc list
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

if   [ $LXD = 'N' ]
then
	if [ -f /var/lib/lxc/$SeedContainerName/rootfs/root/lxc-services.sh ]
	then
		sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/$SeedContainerName/rootfs/root/lxc-services.sh
	fi
fi

sleep 5

clear

if [ $LXD = 'Y' ]
then
	echo ''
	echo "=============================================="
	echo "Create olxc_sw1a LXD Profile ...              "
	echo "=============================================="
	echo ''

	lxc profile create olxc_sw1a
	cat /etc/network/openvswitch/olxc_sw1a | lxc profile edit olxc_sw1a
	lxc profile device add olxc_sw1a root disk path=/ pool=local

	echo ''
	echo "=============================================="
	echo "Done: Create olxc_sw1a LXD Profile.           "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

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
	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
	# GLS 20200504 Using sshpass to create a short-duration socket for nslookups.  Reference: https://jrs-s.net/2017/07/01/slow-ssh-logins/

	function CheckSystemdResolvedInstalled {
		sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
	}
	SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

	if   [ $LXD = 'N' ]
	then
       		function CheckDNSLookup {
               		timeout 5 nslookup $ContainerPrefixLXC$CloneIndex
       		}
       		DNSLookup=$(CheckDNSLookup)
		DNSLookup=`echo $?`

	elif [ $LXD = 'Y' ]
	then	
       		function CheckDNSLookup {
               		timeout 5 nslookup $BaseNet.$CloneIndex
       		}
       		DNSLookup=$(CheckDNSLookup)
		DNSLookup=`echo $?`
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

		lxc copy $SeedContainerName $ContainerPrefixLXD$CloneIndex
		lxc list $ContainerPrefixLXD$CloneIndex

		echo ''
		echo "=============================================="
		echo "Done: Clone $SeedContainerName to $CPD$CI     "
		echo "=============================================="
		echo ''

		sleep 5

		clear
	fi

	if   [ $LXD = 'N' ]
	then
      		sudo lxc-copy -n $SeedContainerName -N $ContainerPrefixLXC$CloneIndex

		if [ $MajorRelease -eq 6 ]
		then	
			sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/hostname
		fi

		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"		/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
		sudo sed -i "s/HostName/$ContainerPrefixLXC$CloneIndex/g"                  	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"		/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network
		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g"		/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/hosts

		sudo sed -i "s/$SeedContainerName/$ContainerPrefixLXC$CloneIndex/g" 				/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
		sudo sed -i "s/\.10/\.$CloneIndex/g" 								/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
 		sudo sed -i 's/sx1/sw1/g' 									/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
	#	sudo sed -i 's/sx1a/sw1a/g' 									/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
		sudo sed -i "s/mtu = 1500/mtu = $MultiHostVar7/g" 						/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
	#	sudo sed -i "s/lxc\.mount\.entry = \/dev\/lxc_luns/#lxc\.mount\.entry = \/dev\/lxc_luns/g" 	/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/config
	#	sudo sed -i "/domain-name-servers/s/10.207.29.2/10.207.39.2/g" 					/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/dhcp/dhclient.conf
	#	sudo rm  -f											/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/machine-id
	#	sudo systemd-machine-id-setup								 --root=/var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs

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

		clear

		function GetHostName (){ echo $ContainerPrefixLXC$CloneIndex\1; }
		HostName=$(GetHostName)

		sudo sed -i "s/$HostName/$ContainerPrefixLXC$CloneIndex/" /var/lib/lxc/$ContainerPrefixLXC$CloneIndex/rootfs/etc/sysconfig/network

		echo ''
		echo "=============================================="
		echo "Create $CPC$CloneIndex Onboot Service...       "
		echo "=============================================="

		sudo sh -c "echo '#!/bin/bash'										>  /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
		sudo sh -c "echo '#'											>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
		sudo sh -c "echo '# Manage the Oracle LXC containers'							>> /etc/network/openvswitch/strt_$ContainerPrefixLXC$CloneIndex.sh"
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
	
		if [ $AWS -eq 1 ]
		then
			sudo sh -c "echo 'Type=idle'									>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
		else
			sudo sh -c "echo 'Type=idle'									>> /etc/systemd/system/$ContainerPrefixLXC$CloneIndex.service"
		fi

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
			sudo lxc-update-config -c /var/lib/lxc/$CP$CloneIndex/config
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

		lxc profile assign $ContainerPrefixLXD$CloneIndex olxc_sw1a
		
		echo ''
		echo "=============================================="
		echo "Done: Assign Profile $ContainerPrefixLXD$CI.  "
		echo "=============================================="
		echo ''
		echo "=============================================="
		echo "Set Machine-ID  $ContainerPrefixLXD$CI...     "
		echo "=============================================="
		echo ''

	echo   "lxc file delete $ContainerPrefixLXD$CloneIndex/etc/machine-id"
		lxc file delete $ContainerPrefixLXD$CloneIndex/etc/machine-id 

		sleep 5

		lxc start $ContainerPrefixLXD$CloneIndex

		sleep 5

		n=1
		while [ $n -ne 0 ]
		do
                	lxc exec  $ContainerPrefixLXD$CloneIndex -- systemd-machine-id-setup > /dev/null 2>&1
			n=`echo $?`
			sleep 5
		done

		lxc stop  $ContainerPrefixLXD$CloneIndex
		lxc start $ContainerPrefixLXD$CloneIndex
		
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
			lxc exec $ContainerPrefixLXD$CloneIndex -- hostnamectl set-hostname $ContainerPrefixLXD$CloneIndex > /dev/null 2>&1
			n=`echo $?`
			sleep 5
		done
	
		lxc exec  $ContainerPrefixLXD$CloneIndex -- hostnamectl
		
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

		lxc stop  $ContainerPrefixLXD$CloneIndex
		lxc start $ContainerPrefixLXD$CloneIndex
		lxc list  $ContainerPrefixLXD$CloneIndex
		
		echo ''
		echo "=============================================="
		echo "Done: Restart $ContainerPrefixLXD$CI.         "
		echo "=============================================="
		echo ''

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Done: Configure $ContainerPrefixLXD$CI        "
		echo "=============================================="
		echo ''

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "nslookup $ContainerPrefixLXD$CI...            "
		echo "=============================================="
		echo ''

		nslookup $ContainerPrefixLXD$CloneIndex
		
		echo "=============================================="
		echo "Done: nslookup $ContainerPrefixLXD$CI.        "
		echo "=============================================="
		echo ''
	fi

	sleep 5

	clear

	CopyCompleted=$((CopyCompleted+1))
	CloneIndex=$((CloneIndex+1))

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
	echo ''
	echo "=============================================="
	echo "Creating OpenvSwitch files ...                "
	echo "=============================================="
	echo ''

	sleep 5

#	sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefixLXC $NumCon $NewHighestContainerIndex $HighestContainerIndex
	sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefixLXC $NumCon $CloneIndex

	echo ''
	echo "=============================================="
	echo "Creating OpenvSwitch files complete.          "
	echo "=============================================="

	sleep 5

	clear

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
fi

if   [ $LXD = 'N' ]
then
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
	echo "Start Seed Container $SeedContainerName...    "
	echo "=============================================="

	sleep 5

	clear
fi

if   [ $LXD = 'N' ]
then
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

	sleep 5

	for j in $ClonedContainers
	do
        	if [ -e /var/lib/lxc/$j/rootfs/var/run/dhclient.pid ]
        	then
                	sudo rm -f /var/lib/lxc/$j/rootfs/var/run/dhclient.pid
        	fi

		sudo lxc-start  -n $j > /dev/null 2>&1
		
		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Set Host and Machine-ID in Clone $j ...       "
		echo "=============================================="
		echo ''

		sudo lxc-attach -n $j -- rm -f /etc/machine-id
		sudo lxc-attach -n $j -- systemd-machine-id-setup
		sudo lxc-stop   -n $j
		sleep 5
		sudo lxc-start  -n $j

		echo ''
		echo "=============================================="
		echo "Done: Set Host and Machine-ID in Clone $j.    "
		echo "=============================================="

		sleep 15

		if [ $MajorRelease -ge 7 ] && [ $UbuntuMajorVersion -ge 16 ]
		then
			echo ''
			echo "=============================================="
			echo "Run hostnamectl in clone $j ...               "
			echo "=============================================="
			echo ''

			sudo lxc-attach -n $j -- hostnamectl set-hostname $j
			sudo lxc-attach -n $j -- hostnamectl
			sudo lxc-stop   -n $j

			echo ''
			echo "=============================================="
			echo "Done: Run hostnamectl in clone $j.            "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		fi
	
	#	sudo lxc-info -n $j
       		echo ''
	done

	echo ''
	echo "=============================================="
	echo "Done: Configure LXC Containers.               "
	echo "=============================================="
	echo ''

elif  [ $LXD = 'Y' ]
then
	echo ''
	echo "=============================================="
	echo "Done: Configure LXD Containers.               "
	echo "=============================================="
	echo ''
fi

if [ $MultiHostVar2 = 'N' ]
then
	sudo lxc-start -n $NameServer > /dev/null 2>&1
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Start Seed Container ...                      "
echo "=============================================="
echo ''

lxc start $SeedContainerName

sleep 5

clear

echo ''
echo "=============================================="
echo "Done: Start Seed Container.                   "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: orabuntu-services-5.sh    "
echo "=============================================="

sleep 5
