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

ContainerPrefix=ora$1$2c
CP=$ContainerPrefix

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

echo ''
echo "=============================================="
echo "Number of LXC Container Nodes = $NumCon       "
echo "=============================================="
echo ''
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

function CheckContainerUp {
sudo lxc-ls -f | grep $SeedContainerName | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)
sudo lxc-stop -n $SeedContainerName > /dev/null 2>&1

while [ "$ContainerUp" = 'RUNNING' ]
do
	sleep 1
	ContainerUp=$(CheckContainerUp)
done

sudo lxc-ls -f

echo ''
echo "=============================================="
echo "Seed container stopped.                       "
echo "=============================================="

sleep 5

clear

if [ $MultiHostVar2 = 'Y' ]
then
        sudo sed -i "s/MtuSetting/$MultiHostVar7/g" /var/lib/lxc/$SeedContainerName/config
fi

echo ''
echo "=============================================="
echo "OpenvSwitch Networking for $Product ...       "
echo "=============================================="
echo ''

sleep 5

clear

sudo /opt/olxc"$DistDir"/products/$Product/$Product.net $MultiHostVar1

echo ''
echo "=============================================="
echo "Done: OpenvSwitch Networking for $Product.    "
echo "=============================================="
echo ''

sleep 5

clear

if [ -f /var/lib/lxc/$SeedContainerName/rootfs/root/lxc-services.sh ]
then
	sudo sed -i 's/yum install/yum -y install/g' /var/lib/lxc/$SeedContainerName/rootfs/root/lxc-services.sh
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Clone $SeedContainerName to $NumCon containers"
echo "=============================================="
echo ''

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

	if [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'Y' ]
	then
        	function CheckDNSLookup {
                	timeout 5 nslookup $ContainerPrefix$CloneIndex
        	}
        	DNSLookup=$(CheckDNSLookup)
		DNSLookup=`echo $?`
	else
        	function CheckDNSLookup {
                	timeout 5 nslookup $ContainerPrefix$CloneIndex
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
		
	echo ''
	echo "=============================================="
	echo "Clone $SeedContainerName to $CP$CloneIndex    "
	echo "=============================================="
	echo ''

	echo "Clone Container Name = $ContainerPrefix$CloneIndex"

	sleep 5

      	sudo lxc-copy -n $SeedContainerName -N $ContainerPrefix$CloneIndex
		
	if [ $MajorRelease -eq 6 ]
	then	
		sudo sed -i "s/$SeedContainerName/$ContainerPrefix$CloneIndex/g"	/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/hostname
	fi

	sudo sed -i "s/$SeedContainerName/$ContainerPrefix$CloneIndex/g"		/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
	sudo sed -i "s/HostName/$ContainerPrefix$CloneIndex/g"                  	/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/sysconfig/network-scripts/ifcfg-eth0
	sudo sed -i "s/$SeedContainerName/$ContainerPrefix$CloneIndex/g"		/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/sysconfig/network
	sudo sed -i "s/$SeedContainerName/$ContainerPrefix$CloneIndex/g"		/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/hosts

	sudo sed -i "s/$SeedContainerName/$ContainerPrefix$CloneIndex/g" 				/var/lib/lxc/$ContainerPrefix$CloneIndex/config
	sudo sed -i "s/\.10/\.$CloneIndex/g" 								/var/lib/lxc/$ContainerPrefix$CloneIndex/config
 	sudo sed -i 's/sx1/sw1/g' 									/var/lib/lxc/$ContainerPrefix$CloneIndex/config
#	sudo sed -i 's/sx1a/sw1a/g' 									/var/lib/lxc/$ContainerPrefix$CloneIndex/config
	sudo sed -i "s/mtu = 1500/mtu = $MultiHostVar7/g" 						/var/lib/lxc/$ContainerPrefix$CloneIndex/config
#	sudo sed -i "s/lxc\.mount\.entry = \/dev\/lxc_luns/#lxc\.mount\.entry = \/dev\/lxc_luns/g" 	/var/lib/lxc/$ContainerPrefix$CloneIndex/config
#	sudo sed -i "/domain-name-servers/s/10.207.29.2/10.207.39.2/g" 					/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/dhcp/dhclient.conf
	sudo rm  -f											/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/machine-id
	sudo systemd-machine-id-setup								 --root=/var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs

        echo ''
        echo "=============================================="
        echo "OpenvSwitch Networking for $Product ...       "
        echo "=============================================="
        echo ''

        sudo /opt/olxc"$DistDir"/products/$Product/$Product.cnf $ContainerPrefix $CloneIndex $Product $MultiHostVar1

        echo ''
        echo "=============================================="
        echo "Done: OpenvSwitch Networking for $Product.    "
        echo "=============================================="
        echo ''

        sleep 5

	function GetHostName (){ echo $ContainerPrefix$CloneIndex\1; }
	HostName=$(GetHostName)

	sudo sed -i "s/$HostName/$ContainerPrefix$CloneIndex/" /var/lib/lxc/$ContainerPrefix$CloneIndex/rootfs/etc/sysconfig/network

	echo ''
	echo "=============================================="
	echo "Create $CP$CloneIndex Onboot Service...       "
	echo "=============================================="

	sudo sh -c "echo '#!/bin/bash'										>  /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '#'											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '# Manage the Oracle LXC containers'							>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '#'											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo 'start() {'										>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '  exec lxc-start -n $ContainerPrefix$CloneIndex > /dev/null 2>&1'			>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '}'											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo ''											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo 'stop() {'										>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '  exec lxc-stop -n $ContainerPrefix$CloneIndex > /dev/null 2>&1'			>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '}'											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo ''											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo 'case \$1 in'										>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo '  start|stop) \"\$1\" ;;'								>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"
	sudo sh -c "echo 'esac'											>> /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh"

	sudo chmod +x /etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh
	
	sudo sh -c "echo '[Unit]'                                                        			>  /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'Description=$ContainerPrefix$CloneIndex Service'                               	>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'Wants=network-online.target sw1.service $NameServer.service'          		>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'After=network-online.target sw1.service $NameServer.service'          		>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo ''                                                             			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo '[Service]'                                                    			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	
	if [ $AWS -eq 1 ]
	then
		sudo sh -c "echo 'Type=idle'									>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	else
		sudo sh -c "echo 'Type=idle'									>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	fi

	sudo sh -c "echo 'User=root'                                                    			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'RemainAfterExit=yes'                                          			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh start' 	>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/strt_$ContainerPrefix$CloneIndex.sh stop'   	>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo ''                                                             			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo '[Install]'                                                    			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'                                   			>> /etc/systemd/system/$ContainerPrefix$CloneIndex.service"

	sudo chmod 644 /etc/systemd/system/$ContainerPrefix$CloneIndex.service
	
	echo ''
	sudo cat /etc/systemd/system/$ContainerPrefix$CloneIndex.service
	echo ''
	sudo systemctl enable $ContainerPrefix$CloneIndex
	
	echo ''
	echo "=============================================="
	echo "Created $CP$CloneIndex Onboot Service.        "
	echo "=============================================="
	echo ''

	if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
	then
		sudo lxc-update-config -c /var/lib/lxc/$CP$CloneIndex/config
	fi

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

echo ''
echo "=============================================="
echo "Creating OpenvSwitch files ...                "
echo "=============================================="

sleep 5

# sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefix $NumCon $NewHighestContainerIndex $HighestContainerIndex
  sudo /etc/network/openvswitch/create-ovs-sw-files-v2.sh $ContainerPrefix $NumCon $CloneIndex

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

if [ $LXDCluster = 'Y' ]
then
	echo ''
	echo "=============================================="
	echo "Install LXD ...                               "
	echo "=============================================="
	echo ''

	sleep 5

	sudo chmod 775  /opt/olxc/"$DistDir"/orabuntu/archives/lxd_install_orabuntu.sh
			/opt/olxc/"$DistDir"/orabuntu/archives/lxd_install_orabuntu.sh $PreSeed $LXDCluster $MultiHostVar2 $MultiHostVar10

	echo ''
	echo "=============================================="
	echo "Done: Install LXD.                            "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

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

echo ''
echo "=============================================="
echo "Start Clone Containers...                     "
echo "=============================================="
echo ''

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

        sudo lxc-start  -n $j
        sleep 5

        if [ $MajorRelease -ge 7 ] && [ $UbuntuMajorVersion -ge 16 ]
        then
                sudo lxc-attach -n $j -- hostnamectl set-hostname $j
                sudo lxc-stop   -n $j
                sudo lxc-start  -n $j
                sleep 5
        fi

        sudo lxc-ls -f
        echo ''
done

echo "=============================================="
echo "Done: Start Clone Containers...               "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: orabuntu-services-5.sh    "
echo "=============================================="

sleep 5
