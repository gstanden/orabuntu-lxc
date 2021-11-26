#!/bin/bash
#
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

#    v2.4 		GLS 20151224
#    v2.8 		GLS 20151231
#    v3.0 		GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 		GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 		GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta	GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)
#    v7.0-ELENA-beta    GLS 20210428 Enterprise LXD Edition New AMIDE

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC

#    !! SEE THE README FILE FOR COMPLETE INSTRUCTIONS FIRST BEFORE RUNNING !!
#
#    sudo ALL privilege is required      prior to running!
#    internet connectivity is required   prior to running!
#
#   Note:	Following line shows options you can set for running create-scst-target.sh in this file.
#       	Set the com.yourdomain, the scstadmin groupname, the ASM redundancy, the sizes of your LUNs, and the logical blocksize in this file if you want non-default values.
#       	Review the create-scst-target.sh for more details and/or the README file.
#
#   Example:	create-scst-target.sh com.urdomain1 lxc1 [external|normal|high] 10G 30G 30G [512|4096]
#
#   IMPORTANT!    Remeber that if you use non-default settings for create-scst-target.sh BE SURE TO SPECIFY ALL OF THEM $1 through $7 !!  Otherwise they will be misinterpreted by the script.
#    Note1:     If you do not pass in a "com.yourdomain" parameter it will be set to default value of com.urdomain1
#    Note2:     If you do not pass in a "ScstGroupName"  parameter it will be set to default value of lxc1
#    Note3:     If you do not pass in a "LunRedundancy"  parameter it will be set to default value of external
#    Note4:     If you do not pass in a "GrpA1SizeGb"    parameter it will be set to default value of 1Gb
#    Note5:     If you do not pass in a "GrpB1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note6:     If you do not pass in a "GrpC1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note7:     If you do not pass in a "LogicalBlkSiz"  parameter it will be set to default value of 512 (optionally set to 4096)

StorageOwner=$1
if [ -z $1 ]
then
	StorageOwner=grid
fi

StorageGroup=$2
if [ -z $2 ]
then
	StorageGroup=asmadmin
fi

Mode=$3
if [ -z $3 ]
then
	Mode=0660
fi

StoragePrefix=$6
if [ -z $6 ]
then
	StoragePrefix=asm
fi

ContainerName=$4
if [ -z $4 ]
then
	ContainerName="$StoragePrefix"_luns
fi

Owner=$5
if [ -z $5 ]
then
	Owner=oracle
fi

SUDO_PREFIX=${18}
if [ -z ${18} ]
then
	SUDO_PREFIX=sudo	
fi

LXDStorageDriver=${19}
if [ -z ${19} ]
then
	LXDStorageDriver=none
fi

function GetRPath {
        which rm
} 
RPath=$(GetRPath)

function GetUPath {
        which udevadm
}
UPath=$(GetUPath)

function GetMPath {
        which multipath
}
MPath=$(GetMPath)

function GetIPath {
        which iscsiadm
}
IPath=$(GetIPath)

function GetSPath {
        which service
}
SPath=$(GetSPath)

function GetDPath {
        which mkdir
}
DPath=$(GetDPath)

function GetOPath {
        which sudo
}
OPath=$(GetOPath)

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
                $SUDO_PREFIX cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
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
                $SUDO_PREFIX cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        RHV=$RedHatVersion
        function GetOracleDistroRelease {
                $SUDO_PREFIX cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
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
                        $SUDO_PREFIX cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
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
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                $SUDO_PREFIX cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        RHV=$RedHatVersion
        if   [ $RedHatVersion -ge 28 ]
        then
                Release=8
	elif [ $RedHatVersion -ge 19 ] || [ $RedHatVersion -le 27 ]
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

if [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Fedora' ]
then
	LinuxFlavor=Red
fi

function GetInitiatorName {
	$SUDO_PREFIX cat /etc/iscsi/initiatorname.iscsi | grep -v '#' | grep iqn | cut -f2 -d'=' 
}
InitiatorName=$(GetInitiatorName)

function GetHostName {
	echo $HOSTNAME 
}
HostName=$(GetHostName)

DATEYR=`date +"%Y"`
DATEMO=`date +"%m"`

# Determine User-Selected Reversed Domain IQN prefix or set it to default (com.orabuntu-lxc)

DOMAIN=$7
if [ -z $7 ]
then
	DOMAIN=com.orabuntu-lxc
fi

# Determine User-Selected SCST Group Name  or set to default (lxc1)

ScstGroup=$8
if [ -z $8 ]
then
	ScstGroup=lxc1
fi

# Determine User-Selected redundancy or set to default (external)

LunRedundancy=$9

function SetCaseLunRedundancy {
	echo $LunRedundancy | sed -e 's/\([A-Z][A-Za-z0-9]*\)/\L\1/g'
}
LunRedundancy=$(SetCaseLunRedundancy)

if [ -z "$9" ]
then
	LunRedundancy=external
fi

if   [ "$LunRedundancy" = 'external' ]
then
	echo 'LunRedundancy = '$LunRedundancy > /dev/null 2>&1
elif [ "$LunRedundancy" = 'normal' ]
then
	echo $LunRedundancy
elif [ "$LunRedundancy" = 'high' ]
then
	echo 'LunRedundancy = '$LunRedundancy > /dev/null 2>&1
else
	echo "LunRedundancy must be in the set {external, normal, high}"
	echo "Current setting of LunRedundancy is $LunRedundancy"
	echo "Rerun program with correct spelling of external, normal, or high"
fi

GrpA=${10}
if [ -z ${10} ]
then
	GrpA=sysd
fi

GrpB=${11}
if [ -z ${11} ]
then
	GrpB=data
fi

GrpC=${12}
if [ -z ${12} ]
then
	GrpC=reco
fi

# GLS 20180210 https://samindaw.wordpress.com/tag/dynamically-create-variables-in-bash-script/
# GLS 20180210 Create and access shell variable having a name created by another string

eval "$GrpA"1SizeGb=${13}
GrpA1SizeGb="$GrpA"1SizeGb
if [ -z ${13} ]
then
	eval "$GrpA"1SizeGb=1G
	GrpA1SizeGb="$GrpA"1SizeGb
fi

eval "$GrpB"1SizeGb=${14}
GrpB1SizeGb="$GrpB"1SizeGb
if [ -z ${14} ]
then
	eval "$GrpB"1SizeGb=1G
	GrpB1SizeGb="$GrpB"1SizeGb
fi

eval "$GrpC"1SizeGb=${15}
GrpC1SizeGb="$GrpC"1SizeGb
if [ -z ${15} ]
then
	eval "$GrpC"1SizeGb=1G
	GrpC1SizeGb="$GrpC"1SizeGb
fi

LogicalBlkSiz=${16}
if [ -z ${16} ]
then
	LogicalBlkSiz=512
fi

if [ $LogicalBlkSiz -ne 4096 ] && [ $LogicalBlkSiz -ne 512 ]
then
	echo 'Error invalid block size'
	exit
fi

product=${17}
if [ -z ${17} ]
then
	product=oracle
fi

sleep 5

clear

echo ''
echo "======================================================"
echo "Display SCST Install settings...                      "
echo "======================================================"
echo ''

echo 'StorageOwner	= '$StorageOwner
echo 'StorageGroup	= '$StorageGroup
echo 'Mode		= '$Mode
echo 'ContainerName	= '$ContainerName
echo 'Owner		= '$Owner
echo 'StoragePrefix	= '$StoragePrefix
echo 'DATEYR        	= '$DATEYR
echo 'DATEMO        	= '$DATEMO
echo 'Domain        	= '$DOMAIN
echo 'ScstGroup     	= 'tpg1
echo 'LunRedundancy 	= '$LunRedundancy
echo 'GrpA		= '$GrpA
echo 'GrpB		= '$GrpB
echo 'GrpC		= '$GrpC
echo 'GrpA1SizeGb   	= '${!GrpA1SizeGb}
echo 'GrpB1SizeGb   	= '${!GrpB1SizeGb}
echo 'GrpC1SizeGb   	= '${!GrpC1SizeGb}
echo 'Initiatorname 	= '$InitiatorName
echo 'HostName      	= '$HostName
echo 'LogicalBlkSiz 	= '512
echo 'Product       	= '$product

echo ''
echo "======================================================"
echo "SCST Install settings displayed.                      "
echo "======================================================"

sleep 10

clear

echo ''
echo "======================================================"
echo "Display target, group, and initiators...              "
echo "======================================================"
echo ''

sleep 10

# Create Target and Groups

$SUDO_PREFIX targetcli /iscsi/create iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product
$SUDO_PREFIX targetcli /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product/tpg1/acls create $InitiatorName
$SUDO_PREFIX targetcli saveconfig 
$SUDO_PREFIX targetcli /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product ls

echo ''
echo "======================================================"
echo "Target, group, and initiator displayed.               "
echo "======================================================"

sleep 5

clear

# Create file-backed devices for LUNS for Oracle ASM diskgroup SYSD1

if [ "$LunRedundancy" = 'external' ]
then
	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for "$GrpA"1 "
	echo "======================================================"
	echo ''

	$SUDO_PREFIX targetcli /backstores/fileio create "$StoragePrefix"_"$GrpA"_SWITCH_IP_00 "$StoragePrefix"_"$GrpA"_SWITCH_IP_00.img ${!GrpA1SizeGb}
	
	sleep 5

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for "$GrpB"1 "
	echo "======================================================"
	echo ''

	$SUDO_PREFIX targetcli /backstores/fileio create "$StoragePrefix"_"$GrpB"_SWITCH_IP_00 "$StoragePrefix"_"$GrpB"_SWITCH_IP_00.img ${!GrpB1SizeGb}

	sleep 5

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for "$GrpC"1 "
	echo "======================================================"
	echo ''

	$SUDO_PREFIX targetcli /backstores/fileio create "$StoragePrefix"_"$GrpC"_SWITCH_IP_00 "$StoragePrefix"_"$GrpC"_SWITCH_IP_00.img ${!GrpC1SizeGb}

	sleep 5
	
	echo ''
	echo "======================================================"
	echo "Devices for "$GrpA"1, "$GrpB"1, and "$GrpC"1 displayed"
	echo "======================================================"

	sleep 5

	clear
	
	echo ''
	echo "======================================================"
	echo "Open LIO devices and create LUNs...                   "
	echo "======================================================"
	echo ''

	sleep 5

	$SUDO_PREFIX targetcli /backstores/fileio create lun0 "$StoragePrefix"_"$GrpA"_SWITCH_IP_00 
	$SUDO_PREFIX targetcli /backstores/fileio create lun1 "$StoragePrefix"_"$GrpB"_SWITCH_IP_00 
	$SUDO_PREFIX targetcli /backstores/fileio create lun2 "$StoragePrefix"_"$GrpC"_SWITCH_IP_00 

	# Add LUNs to iscsi target

	$SUDO_PREFIX targetcli /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product/tpg1/luns /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product create /backstores/fileio/lun0
	$SUDO_PREFIX targetcli /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product/tpg1/luns /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product create /backstores/fileio/lun1
	$SUDO_PREFIX targetcli /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product/tpg1/luns /iscsi/iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.$StoragePrefix.$product create /backstores/fileio/lun2

	echo ''
	echo "======================================================"
	echo "LIO devices and LUNs configured.                     "
	echo "======================================================"

	sleep 5

	clear
fi

echo ''
echo "======================================================="
echo "Write LIO configuration to config file...              "
echo "======================================================="

sleep 5

$SUDO_PREFIX targetcli saveconfig
$SUDO_PREFIX cat /etc/target/saveconfig.json | head -30

echo "======================================================="
echo "Done: Write LIO configuration to config file.          "
echo "======================================================="

sleep 5

clear

echo ''
echo "======================================================="
echo " Enable SCST target for access...                      "
echo "======================================================="
echo ''

sudo iscsiadm -m discovery -t sendtargets --portal 127.0.0.1
sudo iscsiadm -m node --login

echo ''
echo "======================================================="
echo " Done: Enable SCST target for access completed.        "
echo "======================================================="

sleep 5

clear
