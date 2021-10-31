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

#    v2.4               GLS 20151224
#    v2.8               GLS 20151231
#    v3.0               GLS 20160710 Updates for Ubuntu 16.04
#    v4.0               GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0               GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta    GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)
#    v7.0-AMIDE-beta    GLS 20210428 Orabuntu-LXC AmazonS3 Multi-Host LXD Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#    See CONFIG file for user-settable configuration variables.

clear

echo ''
echo "=============================================="
echo "Script: anylinux-services.HUB.HOST.sh         "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Establish sudo...                             "
echo "=============================================="
echo ''

trap "exit" INT TERM; trap "kill 0" EXIT; sudo -v || exit $?; sleep 1; while true; do sleep 60; sudo -nv; done 2>/dev/null &
sudo date

echo ''
echo "=============================================="
echo "Done: Establish sudo.                         "
echo "=============================================="
echo ''

sleep 5

clear

function GetDistDir {
        pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

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
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
	UbuntuMajorVersion=0
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
	SubDirName=uekulele
	UbuntuMajorVersion=0
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
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
	RHV=$RedHatVersion
	SubDirName=uekulele
	UbuntuMajorVersion=0
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Pop_OS' ]
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
	SubDirName=orabuntu
	Release=0
fi

if [ -e /sys/hypervisor/uuid ]
then
        function CheckAWS {
                cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
        }
        AWS=$(CheckAWS)
else
        AWS=0
fi

if [ $AWS -eq 1 ]
then
	function GetAwsMtu {
		sudo ip link | grep eth0 | cut -f5 -d' '
	}
	AwsMtu=$(GetAwsMtu)
fi

if [ $UbuntuMajorVersion -eq 16 ]
then
        echo ''
        echo "=============================================="
        echo "Set apt-get to use ipv4 if Ubuntu 16.04...    "
        echo "=============================================="
        echo ''

        sudo sh -c "echo 'Acquire::ForceIPv4 \"true\"\;' >> /etc/apt/apt.conf.d/99olxc-ipv4"

        sudo ls -l /etc/apt/apt.conf.d/99olxc-ipv4
        echo ''
        sudo cat /etc/apt/apt.conf.d/99olxc-ipv4

        echo ''
        echo "=============================================="
        echo "Done: Set apt-get to use ipv4 if Ubuntu 16.04 "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

################ MultiHost Settings for HUB host ########################

# These values are set hard-coded in this script because this is the HUB host install script.

GRE=N 
MTU=1500
LOGEXT=`date +"%Y-%m-%d.%R:%S"`

# TunType values [geneve|gre|vxlan]

TunType=$(source "$DistDir"/anylinux/CONFIG; echo $TunType)

################e Kubernetes Install Flag  ######################

K8S=N

################### Docker Install Flag  ########################

Docker=$(source "$DistDir"/anylinux/CONFIG; echo $Docker)

################ LXD Cluster Settings ######################

LXD=$(source "$DistDir"/anylinux/CONFIG; echo $LXD)
LXDCluster=$(source "$DistDir"/anylinux/CONFIG; echo $LXDCluster)
LXDStorageDriver=$(source "$DistDir"/anylinux/CONFIG; echo $LXDStorageDriver)

# GLS 20210818 Support for snapd starts with Fedora 24
# GLS 20210818 Orabuntu-LXC supports LXD and LXD Clusters starting with Fedora 24
# GLS 20210818 Reference: https://www.omgubuntu.co.uk/2017/04/use-snap-fedora

if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -le 28 ]
then
	LXD='N'
	LXDCluster='N'
fi

if [ $LXDCluster = 'N' ]
then
	PreSeed=N
fi

if   [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'Fedora' ] || [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Red' ]
then
	if [ $UbuntuMajorVersion -ge 20 ] || [ $Release -ge 7 ]
	then
		if [ $LXDCluster = 'Y' ] && [ $LXDStorageDriver = 'zfs' ]
		then
			echo ''
			echo "=============================================="
			echo "Show Optional LXD & LXD Cluster Values...     "
			echo "=============================================="
			echo ''

			LXD=Y
			PreSeed=Y
       		 	BtrfsLun=Unused
			StoragePoolName=$(source "$DistDir"/anylinux/CONFIG; echo $LXDStoragePoolName)
			LXDStorageDriver=zfs

			echo 'LXDCluster       = '$LXDCluster
			echo 'PreSeed          = '$PreSeed
			echo 'LXD              = '$LXD
			echo 'LXDStorageDriver = '$LXDStorageDriver
			echo 'StoragePool      = '$StoragePoolName
			echo 'BtrfsLun         = '$BtrfsLun

			echo ''
			echo "=============================================="
			echo "Done: Show Optional LXD & LXD Cluster Values. "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Check ZFS Storage Pool Exists...              "
			echo "=============================================="
			echo ''

			function CheckZpoolExist {
				sudo zpool list $StoragePoolName | grep ONLINE | wc -l
			}
			ZpoolExist=$(CheckZpoolExist)

			if [ $ZpoolExist -eq 1 ]
			then
				echo "ZFS $StoragePoolName exists."
			else
				echo "ZFS $StoragePoolName does not exist."
				echo "ZFS $StoragePoolName must be created before running Orabuntu-LXC in LXD Cluster Mode."
				echo "Orabuntu-LXC Exiting."
				exit
			fi
	
			echo ''
			echo "=============================================="
			echo "Done: Check ZFS Storage Pool Exists.          "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		else
			PreSeed=Unused
       		 	BtrfsLun=Unused
			StoragePoolName=Unused
			LXDStorageDriver=Unused
		fi
	fi
fi

# if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 8 ]
# then
# 	if [ $LXDCluster = 'Y' ] && [ $LXDStorageDriver = 'btrfs' ]
# 	then
# 		LXD=Y
#        	PreSeed=Y
#       	BtrfsLun=$(source "$DistDir"/anylinux/CONFIG; echo $BtrfsLun)
# 		StoragePoolName=Unused
# 		LXDStorageDriver=Unused

#        	echo ''
#       	echo "=============================================="
#      	echo "                WARNING !!                    "
#     	echo "=============================================="
#    	echo ''
#   	echo "=============================================="
#  	echo "LXD Cluster will RE-FORMAT $BtrfsLun as a     "
# 	echo "BTRFS file system for LXD.                    "
# 	echo "                                              "
# 	echo "If you do NOT want to use $BtrfsLun for this  "
# 	echo "purpose, hit CTRL+c now to exit.              "
# 	echo "=============================================="
# 	echo ''

# 	sleep 20
# 	else
# 		PreSeed=Unused
#        	BtrfsLun=Unused
# 		StoragePoolName=Unused
# 		LXDStorageDriver=Unused
# 	fi
# fi

################## LXD Cluster Settings END #########################

if [ -z $1 ]
then	
	echo ''
	echo "=============================================="
	echo "                                              "
	echo "If you doing a fresh Orabuntu-LXC install     "
	echo "on this host then take default 'new'          "
	echo "                                              "
	echo "If you are doing a complete Orabuntu-LXC      "
	echo "reinstall then answer 'reinstall'             "
	echo "                                              "
	echo "=============================================="
	echo "                                              "
	read -e -p "Install Type New or Reinstall [new/rei] " -i "new" OpType
	echo "                                              "
	echo "=============================================="
else
	OpType=$1
fi

if   [ $OpType = 'rei' ]
then
	Operation=reinstall
elif [ $OpType = 'new' ]
then
	Operation=new
fi

if [ -z $2 ]
then
        Product=workspaces
	Product=oracle-db
	Product=oracle-gi-18c
	Product=no-producta
	Product=$(source "$DistDir"/anylinux/CONFIG; echo $Product)

else
        Product=$2
fi

function GetDistDir {
        pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

if [ ! -d /opt/olxc ]
then
        sudo mkdir -p  /opt/olxc
        sudo chmod 777 /opt/olxc
fi

if [ ! -d /opt/olxc/installs/logs ]
then
	sudo mkdir -p /opt/olxc/installs/logs
fi

if [ -f /opt/olxc/installs/logs/$USER.log ]
then
	sudo mv /opt/olxc/installs/logs/$USER.log /opt/olxc/installs/logs/$USER.log.$LOGEXT
fi

if [ ! -d /var/log/sudo-io ]
then
	sudo mkdir -m 750 /var/log/sudo-io
fi

if [ ! -f /etc/sudoers.d/orabuntu-lxc ]
then
	sudo sh -c "echo 'Defaults      logfile=\"/opt/olxc/installs/logs/$USER.log\"'					>> /etc/sudoers.d/orabuntu-lxc"
	sudo sh -c "echo 'Defaults      log_input,log_output'								>> /etc/sudoers.d/orabuntu-lxc"
	sudo sh -c "echo 'Defaults      iolog_dir=/var/log/sudo-io/%{user}'						>> /etc/sudoers.d/orabuntu-lxc"
	sudo chmod 0440 /etc/sudoers.d/orabuntu-lxc
fi

function CheckAptProcessRunning {
ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
}
AptProcessRunning=$(CheckAptProcessRunning)

while [ $AptProcessRunning -gt 0 ]
do
	echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
	echo ''
	ps -ef | grep -v '_apt' | grep apt | grep -v grep
	sleep 10
	AptProcessRunning=$(CheckAptProcessRunning)
done

if   [ $AWS -eq 1 ]
then
	if   [ $AwsMtu -ge 9000 ]
	then
		# Until support for MTU 9000 is ready, set MTU to 1500.
		sudo ifconfig eth0 mtu 1500
		AwsMtu=1500
		MultiHost="$Operation:N:1:X:X:X:$AwsMtu:X:X:$GRE:$Product"

	elif [ $AwsMtu -eq 1500 ]
	then
		MultiHost="$Operation:N:1:X:X:X:$AwsMtu:X:X:$GRE:$Product"
	fi

else
	MultiHost="$Operation:N:1:X:X:X:$MTU:X:X:$GRE:$Product:$LXD:$K8S:$PreSeed:$LXDCluster:$LXDStorageDriver:$StoragePoolName:$BtrfsLun:$Docker:$TunType"
fi

./anylinux-services.sh $MultiHost 

exit
