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
#    v7.0-ELENA-beta    GLS 20210428 Orabuntu-LXC AmazonS3 Multi-Host LXD Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#    See CONFIG file for user-settable configuration variables.

clear

echo ''
echo "=============================================="
echo "Script: anylinux-services.GRE.HOST.sh         "
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

sleep 5

clear

if [ -z $2 ]
then
        echo ''
        echo "=============================================="
        echo "                                              "
        echo "If you are doing a fresh Orabuntu-LXD install "
        echo "for LXD containers select 'lxd' (default)     "
        echo "                                              "
        echo "If you are doing a fresh Orabuntu-LXC install "
        echo "for LXC containers select 'lxc' (alternative) "
        echo "                                              "
        echo "=============================================="
        echo "                                              "
        read -e -p "Install Type lxd or lxc [lxd/lxc]  " -i "lxd" ConType
        echo "                                              "
        echo "=============================================="
        echo ''
else
        ConType=$2
fi

if   [ $ConType = 'lxd' ]
then
        cp -p CONFIG.LXD CONFIG

elif [ $ConType = 'lxc' ]
then
        cp -p CONFIG.LXC CONFIG
fi

sleep 5

clear

function GetDistDir {
        pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

function CheckAptProcessRunning {
	ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
}
AptProcessRunning=$(CheckAptProcessRunning)

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
                sudo ip link | grep -v veth0 | grep eth0 | cut -f5 -d' '
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

        sudo sh -c "echo 'Acquire::ForceIPv4 \"true\"\;' > /etc/apt/apt.conf.d/99olxc-ipv4"

        sudo ls -l /etc/apt/apt.conf.d/99olxc-ipv4
        echo ''
	echo 'Contents of file:'
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

# These values are set hard-coded in this script.
# MTU 9000 has not been developed into Orabuntu-LXC yet but is on roadmap.

GRE=Y
MTU=1420
LOGEXT=`date +"%Y-%m-%d.%R:%S"`

#################### Tunnel settings ###########################

# TunType values [geneve|gre|vxlan]

TunType=$(source "$DistDir"/anylinux/CONFIG; echo $TunType)

###################### SCST settings ###########################

IscsiTarget=$(source "$DistDir"/anylinux/CONFIG; echo $IscsiTarget)
IscsiVendor=$(source "$DistDir"/anylinux/CONFIG; echo $IscsiVendor)
IscsiTargetLunPrefix=$(source "$DistDir"/anylinux/CONFIG; echo $IscsiTargetLunPrefix)
Lun1Name=$(source "$DistDir"/anylinux/CONFIG; echo $Lun1Name)
Lun2Name=$(source "$DistDir"/anylinux/CONFIG; echo $Lun2Name)
Lun3Name=$(source "$DistDir"/anylinux/CONFIG; echo $Lun3Name)
Lun1Size=$(source "$DistDir"/anylinux/CONFIG; echo $Lun1Size)
Lun2Size=$(source "$DistDir"/anylinux/CONFIG; echo $Lun2Size)
Lun3Size=$(source "$DistDir"/anylinux/CONFIG; echo $Lun3Size)
LogBlkSz=$(source "$DistDir"/anylinux/CONFIG; echo $LogBlkSz)

BtrfsRaid=$(source "$DistDir"/anylinux/CONFIG; echo $BtrfsRaid)
ZfsMirror=$(source "$DistDir"/anylinux/CONFIG; echo $ZfsMirror)

############ User-configured non-SCST storage ###################

ZfsLun1=$(source "$DistDir"/anylinux/CONFIG; echo $ZfsLun1)
ZfsLun2=$(source "$DistDir"/anylinux/CONFIG; echo $ZfsLun2)

BtrfsLun1=$(source "$DistDir"/anylinux/CONFIG; echo $BtrfsLun1)
BtrfsLun2=$(source "$DistDir"/anylinux/CONFIG; echo $BtrfsLun2)

LxcLun1=$(source "$DistDir"/anylinux/CONFIG; echo $LxcLun1)

############## Kubernetes Snap Install Flag  ###################

K8S=$(source "$DistDir"/anylinux/CONFIG; echo $K8S)

################### Docker Install Flag  ########################

Docker=$(source "$DistDir"/anylinux/CONFIG; echo $Docker)

################ LXD Cluster Settings ######################

LXD=$(source "$DistDir"/anylinux/CONFIG; echo $LXD)
LXDCluster=$(source "$DistDir"/anylinux/CONFIG; echo $LXDCluster)
LXDStorageDriver=$(source "$DistDir"/anylinux/CONFIG; echo $LXDStorageDriver)
LXDStoragePoolName=$(source "$DistDir"/anylinux/CONFIG; echo $LXDStoragePoolName)
LXDPreSeed=$(source "$DistDir"/anylinux/CONFIG; echo $LXDPreSeed)

# GLS 20210818 Support for snapd starts with Fedora 24
# GLS 20210818 Orabuntu-LXC supports LXD and LXD Clusters starting with Fedora 24
# GLS 20210818 Reference: https://www.omgubuntu.co.uk/2017/04/use-snap-fedora

################## ContainerRuntime Setting ########################

ContainerRuntime=$(source "$DistDir"/anylinux/CONFIG; echo $ContainerRuntime)
k8sCNI=$(source "$DistDir"/anylinux/CONFIG; echo $k8sCNI)
k8sLoadBalancer=$(source "$DistDir"/anylinux/CONFIG; echo $k8sLoadBalancer)
k8sIngressController=$(source "$DistDir"/anylinux/CONFIG; echo $k8sIngressController)

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
                if [ $LXDCluster = 'Y' ]
                then
                        if [ $LXDStorageDriver = 'zfs' ]
                        then
                                sudo modprobe zfs > /dev/null 2>&1
                                which zpool > /dev/null 2>&1
                                if [ $? -eq 0 ]
                                then
                                        ZpoolCmdExist=1
                                else
                                        ZpoolCmdExist=0
                                fi

                                if [ $ZpoolCmdExist -eq 0 ]
                                then
                                        echo ''
                                        echo "=============================================="
                                        echo "Install ZFS ...                               "
                                        echo "=============================================="
                                        echo ''

                                        if [ $LinuxFlavor != 'Ubuntu' ]
                                        then
                                                CurrentDir=`pwd`
                                                sudo mkdir -p /opt/olxc/"$DistDir"/zfsutils/"$LinuxFlavor"
                                                sudo chown "$Owner":"$Group" /opt/olxc/"$DistDir"/zfsutils/"$LinuxFlavor"
                                                sudo cp -p "$DistDir"/zfsutils/"$LinuxFlavor"/"$LXDStorageDriver"_"$LinuxFlavor"_"$RedHatVersion".sh /opt/olxc/"$DistDir"/zfsutils/"$LinuxFlavor"/.
                                                cd /opt/olxc/"$DistDir"/zfsutils/"$LinuxFlavor"
                                                ./"$LXDStorageDriver"_"$LinuxFlavor"_"$RedHatVersion".sh
                                                cd $CurrentDir
                                        else
                                                while [ $AptProcessRunning -gt 0 ]
                                                do
                                                        echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
                                                        echo ''
                                                        ps -ef | grep -v '_apt' | grep apt | grep -v grep
                                                        sleep 10
                                                        AptProcessRunning=$(CheckAptProcessRunning)
                                                done

                                                sudo apt-get -y install zfsutils-linux
                                        fi

                                        echo ''
                                        echo "=============================================="
                                        echo "Done: Install ZFS.                            "
                                        echo "=============================================="
                                        echo ''

                                        sleep 5

                                        clear

                                        echo ''
                                        echo "=============================================="
                                        echo "Verify zpool cmd available ...                "
                                        echo "=============================================="
                                        echo ''

                                        sudo zpool list
                                        if [ $? -ne 0 ]
                                        then
                                                echo 'ZFS zpool command is not available.'
                                                echo ''
                                                echo 'RedHat-family:  go to ./zfsutils/$LinuxFlavor and run manually before re-running this script.'
                                                echo 'Debian-family:  run apt-get -y install zfsutils-linux'
                                                echo 'script exiting ... '
                                        else
                                                echo 'ZFS is already installed'
                                        fi

                                        echo ''
                                        echo "=============================================="
                                        echo "Done: Verify zpool cmd available.             "
                                        echo "=============================================="
                                        echo ''

                                        sleep 5

                                        clear
                                fi

                                if [ $IscsiTarget = 'Y' ]
                                then
                                        BtrfsLun1=Unused
                                        BtrfsLun2=Unused
                                        ZfsLun1=Unused
                                        ZfsLun2=Unused
                                        LxcLun1=Unused

                                elif [ $IscsiTarget = 'N' ]
                                then
                                        BtrfsLun1=Unused
                                        BtrfsLun2=Unused
                                        Lun1Name=unused
                                        Lun2Name=unused
                                        Lun3Name=unused
                                        Lun1Size=0
                                        Lun2Size=0
                                        Lun3Size=0
                                fi

                        elif [ $LXDStorageDriver = 'btrfs' ]
                        then
                                if [ $IscsiTarget = 'Y' ]
                                then
                                        BtrfsLun1=Unused
                                        BtrfsLun2=Unused
                                        ZfsLun1=Unused
                                        ZfsLun2=Unused
                                        LxcLun1=Unused

                                elif [ $IscsiTarget = 'N' ]
                                then
                                        ZfsLun1=Unused
                                        ZfsLun2=Unused
                                        Lun1Name=unused
                                        Lun2Name=unused
                                        Lun3Name=unused
                                        Lun1Size=0
                                        Lun2Size=0
                                        Lun3Size=0
                                fi
                        fi
                fi
        fi
fi

echo ''
echo "=============================================="
echo "Show LXD & LXD Cluster Values...     "
echo "=============================================="
echo ''

echo 'SCST                      = '$IscsiTarget
echo 'IscsiTargetLunPrefix      = '$IscsiTargetLunPrefix
echo 'LXDCluster                = '$LXDCluster
echo 'LXDPreSeed                = '$LXDPreSeed
echo 'LXD                       = '$LXD
echo 'LXDStorageDriver  	  = '$LXDStorageDriver
echo 'LXDStoragePoolName        = '$LXDStoragePoolName
echo 'Lun1Name          	  = '$Lun1Name
echo 'Lun2Name          	  = '$Lun2Name
echo 'Lun3Name          	  = '$Lun3Name
echo 'Lun1Size          	  = '$Lun1Size
echo 'Lun2Size          	  = '$Lun2Size
echo 'Lun3Size          	  = '$Lun3Size
echo 'ZfsLun1                   = '$ZfsLun1
echo 'ZfsLun2                   = '$ZfsLun2
echo 'BtrfsLun1         	  = '$BtrfsLun1
echo 'BtrfsLun2         	  = '$BtrfsLun2
echo 'LxcLun1                   = '$LxcLun1

echo ''
echo "=============================================="
echo "Done: Show LXD & LXD Cluster Values.          "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Check LUN naming matches Storage Driver...    "
echo "=============================================="
echo ''

function GetLXDStorageDriverPrefix {
        echo $LXDStorageDriver | cut -c1-3
}
LXDStorageDriverPrefix=$(GetLXDStorageDriverPrefix)

function CheckIscsiTargetLunName1 {
        echo $Lun1Name | grep -c $LXDStorageDriverPrefix
}
IscsiTargetLunName1=$(CheckIscsiTargetLunName1)

function CheckIscsiTargetLunName2 {
        echo $Lun2Name | grep -c $LXDStorageDriverPrefix
}
IscsiTargetLunName2=$(CheckIscsiTargetLunName2)

if [ $IscsiTargetLunName1 -eq 0 ] || [ $IscsiTargetLunName2 -eq 0 ]
then
        echo "SCST LUNs $Lun1Name $Lun2Name mismatch $LXDStorageDriver driver."
        echo ''
        echo "$LXDStorageDriver"
        echo "$Lun1Name"
        echo "$Lun2Name"
        echo ''
        echo "Please edit CONFIG file and restart script."
        echo ''
        echo "=============================================="
        echo "Done: Check LUN naming matches Storage Driver."
        echo "=============================================="
        echo ''
        exit
else
        sleep 5

        clear

        echo ''
        echo "=============================================="
        echo "Done: Check LUN naming matches Storage Driver."
        echo "=============================================="
        echo ''
fi

sleep 5

clear

################## LXD Cluster Settings END #########################

if [ -z $3 ]
then
	SPOKEIP=$(source "$DistDir"/anylinux/CONFIG; echo $SPOKEIP)
else
	SPOKEIP=$3
fi

if [ -z $4 ]
then
	HUBIP=$(source "$DistDir"/anylinux/CONFIG; echo $HUBIP)
else
	HUBIP=$4
fi

if [ -z $5 ]
then
	HubUserAct=$(source "$DistDir"/anylinux/CONFIG; echo $HubUserAct)
else
	HubUserAct=$5
fi

if [ -z $6 ]
then
	HubSudoPwd=$(source "$DistDir"/anylinux/CONFIG; echo $HubSudoPwd)
else
	HubSudoPwd=$6
fi

if [ -z $7 ]
then
	Product=$(source "$DistDir"/anylinux/CONFIG; echo $Product)
else
	Product=$7
fi

if [ $SPOKEIP = 'lan.ip.gre.host' ] || [ $HUBIP = 'lan.ip.hub.host' ] || [ $HubUserAct = 'username' ] || [ $HubSudoPwd = 'password' ]
then
	echo ''
	echo "=============================================="
	echo "Update settings in config file required.      "
	echo "=============================================="
	echo ''
	echo 'You must edit the "config" file first and set the following variables:'
	echo ''
	echo '		SPOKEIP'
       	echo '		HUBIP'
        echo '		HubUserAct'
	echo '		HubSudoPwd'
	echo ''
	echo 'The config file is located in this current directory.'
	echo ''
	echo 'After setting these in this file re-run this anylinux-services.GRE.HOST.sh  script'
	echo 'Also ... be SURE to verify these values carefully before running Orabuntu-LXC install !'
	echo ''
	echo "=============================================="
	echo ''
	exit
fi

function GetDistDir {
        pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

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
        sudo sh -c "echo 'Defaults      logfile=\"/opt/olxc/installs/logs/$USER.log\"'                          >> /etc/sudoers.d/orabuntu-lxc"
        sudo sh -c "echo 'Defaults      log_input,log_output'                                                           >> /etc/sudoers.d/orabuntu-lxc"
        sudo sh -c "echo 'Defaults      iolog_dir=/var/log/sudo-io/%{user}'                                             >> /etc/sudoers.d/orabuntu-lxc"
        sudo chmod 0440 /etc/sudoers.d/orabuntu-lxc
fi

if [ $LinuxFlavor != 'Ubuntu' ] && [ $LinuxFlavor != 'Fedora' ]
then
        echo ''
        echo "=============================================="
        echo "Configure epel for $LinuxFlavor Linux...      "
        echo "=============================================="
        echo ''

	sleep 5

	clear

        DocBook2XInstalled=0
        m=1
        while [ $DocBook2XInstalled -eq 0 ] && [ $m -le 5 ]
        do
                if [ $LinuxFlavor != 'Fedora' ]
                then
        		echo ''
        		echo "=============================================="
        		echo "Install Required Packages...                  "
        		echo "=============================================="
        		echo ''

                        sudo yum -y install wget
        		
			echo ''
        		echo "=============================================="
        		echo "Done: Install Required Packages.              "
        		echo "=============================================="
        		echo ''

			sleep 5

			clear

                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel

                        if   [ $Release -eq 7 ]
                        then
				echo ''
				echo "=============================================="
				echo "Get EPEL latest ...                           "
				echo "=============================================="
				echo ''

				function CheckEpelInstalled {
				        rpm -qa | grep -c epel-release
				}
				EpelInstalled=$(CheckEpelInstalled)

				if [ $EpelInstalled -eq 0 ]
				then
				        n=1
				        Epel1=1
				        while [ $Epel1 -ne 0 ] && [ $n -le 5 ]
				        do
				                sudo rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
				                Epel1=`echo $?`
				                n=$((n+1))
				                sleep 5
				        done
				else
				        sudo rpm -qa | grep epel-release
				fi

				echo ''
				echo "=============================================="
				echo "Done: Get EPEL latest.                        "
				echo "=============================================="
				echo ''

				sleep 5

				clear

                        elif [ $Release -eq 6 ]
                        then
			#	GLS 20201217 EPEL seems unavailable for Linux 6
			#	wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
			#	sudo rpm -ivh epel-release-latest-6.noarch.rpm
			#	wget https://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/docbook2x-0.8.8-1.el6.rf.x86_64.rpm -4
			#	wget https://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/i386/rpmforge/RPMS/sshpass-1.05-1.el6.rf.x86_64.rpm -4
				
				echo ''
        			echo "=============================================="
        			echo "Install docbook2x and sshpass ...             "
        			echo "=============================================="
        			echo ''

				sudo yum -y install openjade texinfo perl-XML-SAX
				sudo rpm -ivh "$DistDir"/rpmstage/docbook2x-0.8.8-1.el6.rf.x86_64.rpm
				sudo rpm -ivh "$DistDir"/rpmstage/sshpass-1.05-1.el6.rf.x86_64.rpm
				
				echo ''
        			echo "=============================================="
        			echo "Done: Install docbook2x and sshpass.          "
        			echo "=============================================="
        			echo ''

				sleep 5

				clear

			elif [ $Release -eq 8 ]
			then
        			echo ''
        			echo "=============================================="
        			echo "Install Required Packages...                  "
        			echo "=============================================="
        			echo ''

				if   [ $LinuxFlavor = 'Red' ]
				then
					sudo subscription-manager repos --enable codeready-builder-for-rhel-8-x86_64-rpms
					sudo dnf -y install docbook2X
					sudo rpm -qa | grep docbook2X

				elif [ $LinuxFlavor = 'Oracle' ]
				then
					sudo yum -y install oracle-epel-release-el8
					sudo yum -y install yum-utils
					sudo yum-config-manager --enable ol8_codeready_builder
					sudo yum-config-manager --enable ol8_addons

				elif [ $LinuxFlavor = 'CentOS' ]
				then
					sudo dnf -y --enablerepo=powertools install docbook2X
				fi

				sudo yum -y install docbook2X
        			
				echo ''
        			echo "=============================================="
        			echo "Done: Install Required Packages.              "
        			echo "=============================================="
        			echo ''

				sleep 5

				clear
                        fi

			echo ''
        		echo "=============================================="
        		echo "Check REPO provides for lxc...                "
        		echo "=============================================="
        		echo ''

                        sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u

			echo ''
        		echo "=============================================="
        		echo "Done: Check REPO provides for lxc.            "
        		echo "=============================================="
        		echo ''

			sleep 5

			clear

                        sudo yum -y install docbook2X > /dev/null 2>&1
                fi

                function CheckDocBook2XInstalled {
                        rpm -qa | grep -ic docbook2X
                }
                DocBook2XInstalled=$(CheckDocBook2XInstalled)

                if   [ $DocBook2XInstalled -gt 0 ]
                then
                        echo ''
                        echo "=============================================="
                        echo "Done: Configure epel for $LinuxFlavor Linux.  "
                        echo "=============================================="
                        echo ''

                        sleep 5

                        clear

                elif [ $DocBook2XInstalled -eq 0 ]
                then
                        echo ''
                        echo "=============================================="
                        echo 'epel failure ... retrying epel configuration. '
                        echo "=============================================="
                        echo ''

                        sleep 5

                        clear
                fi
                m=$((m+1))
        done

        echo ''
        echo "=============================================="
        echo 'Install sshpass package...                    '
        echo "=============================================="
        echo ''

        sudo yum -y install sshpass

        echo ''
        echo "=============================================="
        echo 'Done: Install sshpass package.                '
        echo "=============================================="
        sleep 5
        clear
elif [ $LinuxFlavor = 'Ubuntu' ]
then
        echo ''
        echo "=============================================="
        echo 'Install sshpass package...                    '
        echo "=============================================="
        echo ''

	function CheckAptProcessRunning {
		ps -ef | grep apt | grep -v '_apt' | grep -v grep | wc -l
	}
	AptProcessRunning=$(CheckAptProcessRunning)

	while [ $AptProcessRunning -gt 0 ]
	do
		echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
                echo ''
		ps -ef | grep apt | grep -v '_apt' | grep -v grep
		sleep 10
		AptProcessRunning=$(CheckAptProcessRunning)
	done

        sudo apt-get -y install sshpass

        echo ''
        echo "=============================================="
        echo 'Done: Install sshpass package.                '
        echo "=============================================="
        sleep 5
        clear
elif [ $LinuxFlavor = 'Fedora' ]
then
        echo ''
        echo "=============================================="
        echo 'Install sshpass package...                    '
        echo "=============================================="
        echo ''

        sudo dnf -y install sshpass

        echo ''
        echo "=============================================="
        echo 'Done: Install sshpass package.                '
        echo "=============================================="
        sleep 5
        clear
fi

echo ''
echo "=============================================="
echo "Test sshpass to HUB Host $HUBIP               "
echo "=============================================="
echo ''

sudo yum -y     install net-tools > /dev/null 2>&1
sudo apt-get -y install net-tools > /dev/null 2>&1

ssh-keygen -R $HUBIP > /dev/null 2>&1
sshpass -p $HubSudoPwd ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $HubUserAct@$HUBIP "sudo -S -p' '  <<< "$HubSudoPwd"  echo '';uname -a; echo '';sudo -S <<< "$HubSudoPwd" lxc-ls -f"
if [ $? -eq 0 ]
then
	echo ''
	echo "=============================================="
	echo "Done: Test sshpass to HUB Host $HUBIP         "
	echo "=============================================="
	echo ''

	sleep 5

	echo ''

	cd "$DistDir"/anylinux

        if   [ $AWS -eq 1 ]
        then
                if   [ $AwsMtu -ge 9000 ]
                then
                        # Until support for MTU 9000 is ready, set MTU to 1500.
                        sudo ifconfig eth0 mtu 1500
                        AwsMtu=1500
#			MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:8920:$HubUserAct:$HubSudoPwd:$GRE:$Product"
                	MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:1420:$HubUserAct:$HubSudoPwd:$GRE:$Product"

		elif [ $AwsMtu -eq 1500 ]
		then
                	MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:1420:$HubUserAct:$HubSudoPwd:$GRE:$Product"
                fi

	elif [ $UbuntuMajorVersion -ge 16 ]
	then
		MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product:$LXD:$K8S:$LXDPreSeed:$LXDCluster:$LXDStorageDriver:$LXDStoragePoolName:$BtrfsLun1:$Docker:$TunType:$IscsiTarget:$Lun1Name:$Lun2Name:$Lun3Name:$Lun1Size:$Lun2Size:$Lun3Size:$LogBlkSz:$BtrfsRaid:$ZfsMirror:$BtrfsLun2:$ZfsLun1:$ZfsLun2:$LxcLun1:$IscsiTargetLunPrefix:$IscsiVendor:$ContainerRuntime:$k8sCNI:$k8sLoadBalancer:$k8sIngressController"
	else
		MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product:$LXD:$K8S:$LXDPreSeed:$LXDCluster:$LXDStorageDriver:$LXDStoragePoolName:$BtrfsLun1:$Docker:$TunType:$IscsiTarget:$Lun1Name:$Lun2Name:$Lun3Name:$Lun1Size:$Lun2Size:$Lun3Size:$LogBlkSz:$BtrfsRaid:$ZfsMirror:$BtrfsLun2:$ZfsLun1:$ZfsLun2:$LxcLun1:$IscsiTargetLunPrefix:$IscsiVendor:$ContainerRuntime:$k8sCNI:$k8sLoadBalancer:$k8sIngressController"
        fi

	sleep 5

	./anylinux-services.sh $MultiHost
else
        echo "The sshpass to the Orabuntu-LXC HUB host at $HUBIP failed. Recheck settings in this file and re-run."
	echo ''
	echo "=============================================="
	echo "Fail: Test sshpass to HUB Host $HUBIP         "
	echo "=============================================="
	echo ''
	sleep 5
        exit
fi

exit
