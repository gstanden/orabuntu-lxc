#!/bin/bash

#    Copyright 2015-2017 Gilbert Standen
#    This file is part of orabuntu-lxc:  https://github.com/gstanden/orabuntu-lxc
#
#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.
#
#    v2.8 GLS 20151231
#    v3.0 GLS 20160710
#    v3.1 GLS 20160925
#    v4.0 GLS 20170906
#    v5.0 GLS 20171103
#
#    This software is for kernels 2.6.30 and higher but it can be used with lower kernels if you build a custom SCST kernel.
#    Read Chris Weiss post on building custom SCST kernel on Ubuntu for kernels older than 2.6.30.
#    https://gist.github.com/chrwei/42f8bbb687290b04b598.#!/bin/bash
#
#   !! SEE THE README FILE FOR COMPLETE INSTRUCTIONS FIRST BEFORE RUNNING !!
#
#   sudo ALL privilege is required      prior to running!
#   internet connectivity is required   prior to running!
#
# Note:		Following line shows options you can set for running create-scst-oracle.sh in this file.
#       	Set the com.yourdomain, the scstadmin groupname, the ASM redundancy, the sizes of your LUNs, and the logical blocksize in this file if you want non-default values.
#       	Review the create-scst-oracle.sh for more details and/or the README file.
#
# Example:	create-scst-oracle.sh com.urdomain1 lxc1 [external|normal|high] 10G 30G 30G [512|4096]
#
# IMPORTANT!    Remeber that if you use non-default settings for create-scst-oracle.sh BE SURE TO SPECIFY ALL OF THEM $1 through $7 !!  Otherwise they will be misinterpreted by the script.
#    Note1:     If you do not pass in a "com.yourdomain" parameter it will be set to default value of com.urdomain1
#    Note2:     If you do not pass in a "ScstGroupName"  parameter it will be set to default value of lxc1
#    Note3:     If you do not pass in a "AsmRedundancy"  parameter it will be set to default value of external
#    Note4:     If you do not pass in a "Sysd1SizeGb"    parameter it will be set to default value of 1Gb
#    Note5:     If you do not pass in a "Data1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note6:     If you do not pass in a "Reco1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note7:     If you do not pass in a "LogicalBlkSiz"  parameter it will be set to default value of null (SCST by default uses 512-byte logical sector.  Optionally set this to 4096).)

# Determine if sudo prefix is needed on commands

GetLinuxFlavor(){
	if [[ -e /etc/redhat-release ]]
	then
		LinuxFlavor=$(cat /etc/redhat-release | cut -f1 -d' ')
	elif [[ -e /usr/bin/lsb_release ]]
	then
		LinuxFlavor=$(lsb_release -d | awk -F ':' '{print $2}' | cut -f1 -d' ')
	elif [[ -e /etc/issue ]]
	then
		LinuxFlavor=$(cat /etc/issue | cut -f1 -d' ')
	else
		LinuxFlavor=$(cat /proc/version | cut -f1 -d' ')
	fi
}

GetLinuxFlavor

function TrimLinuxFlavor {
	echo $LinuxFlavor | sed 's/^[ \t]//;s/[ \t]$//'
}
LinuxFlavor=$(TrimLinuxFlavor)

if [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
	SUDO_PREFIX=sudo
	echo ''
	echo "======================================================="
	echo "Establish sudo privileges ...                          "
	echo "======================================================="
	echo ''

	sudo date

	echo ''
	echo "======================================================="
	echo "Establish sudo privileges successful.                  "
	echo "======================================================="
	
	sleep 5

	clear

elif [ $LinuxFlavor = 'CentOS' ]
then
	SUDO_PREFIX=''

	echo ''
	echo "======================================================="
	echo "Install iscs-initiator-utils package...                "
	echo "======================================================="
	echo ''

	yum -y install iscsi-initiator-utils

	echo ''
	echo "======================================================="
	echo "Package installed.                                     "
	echo "======================================================="

elif [ $LinuxFlavor = 'Red'    ]
then
	SUDO_PREFIX=''

	echo ''
	echo "======================================================="
	echo "Install iscs-initiator-utils package...                "
	echo "======================================================="
	echo ''

	yum -y install iscsi-initiator-utils

	echo ''
	echo "======================================================="
	echo "Package installed.                                     "
	echo "======================================================="
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

DOMAIN=$1
if [ -z $DOMAIN ]
then
DOMAIN=com.orabuntu-lxc
fi

# Determine User-Selected SCST Group Name  or set to default (lxc1)

ScstGroup=$2
if [ -z $ScstGroup ]
then
ScstGroup=lxc1
fi

# Determine User-Selected redundancy or set to default (external)

AsmRedundancy=$3

function SetCaseAsmRedundancy {
echo $AsmRedundancy | sed -e 's/\([A-Z][A-Za-z0-9]*\)/\L\1/g'
}
AsmRedundancy=$(SetCaseAsmRedundancy)

if [ -z "$3" ]
then
AsmRedundancy=external
fi

if   [ "$AsmRedundancy" = 'external' ]
then
echo 'AsmRedundancy = '$AsmRedundancy > /dev/null 2>&1
elif [ "$AsmRedundancy" = 'normal' ]
then
echo $AsmRedundancy
elif [ "$AsmRedundancy" = 'high' ]
then
echo 'AsmRedundancy = '$AsmRedundancy > /dev/null 2>&1
else
echo "AsmRedundancy must be in the set {external, normal, high}"
echo "Current setting of AsmRedundancy is $AsmRedundancy"
echo "Rerun program with correct spelling of external, normal, or high"
fi

Sysd1SizeGb=$4
if [ -z $Sysd1SizeGb ]
then
Sysd1SizeGb=1G
fi

Data1SizeGb=$5
if [ -z $Data1SizeGb ]
then
Data1SizeGb=1G
fi

Reco1SizeGb=$6
if [ -z $Reco1SizeGb ]
then
Reco1SizeGb=1G
fi

LogicalBlkSiz=$7
if [ -z $7 ]
then
LogicalBlkSiz=''
elif [ $LogicalBlkSiz -eq 4096 ]
then
LogicalBlkSiz=',blocksize='$7
elif [ $LogicalBlkSiz -eq 512  ]
then
LogicalBlkSiz=',blocksize='$7
elif [ $LogicalBlkSiz -ne 4096 ] && [ $LogicalBlkSiz -ne 512 ]
then
echo 'Error invalid block size'
exit
fi

sleep 5

clear

echo ''
echo "======================================================"
echo "Display SCST Install settings...                      "
echo "======================================================"
echo ''

echo 'AsmRedundancy = '$AsmRedundancy
echo 'Initiatorname = '$InitiatorName
echo 'ScstGroup     = '$ScstGroup
echo 'DATEYR        = '$DATEYR
echo 'DATEMO        = '$DATEMO
echo 'Domain        = '$DOMAIN
echo 'HostName      = '$HostName
echo 'Sysd1SizeGb   = '$Sysd1SizeGb
echo 'Data1SizeGb   = '$Data1SizeGb
echo 'Reco1SizeGb   = '$Reco1SizeGb
echo 'LogicalBlkSiz = '$LogicalBlkSiz'(defaults to 512)'

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

$SUDO_PREFIX scstadmin -add_target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -driver iscsi
$SUDO_PREFIX scstadmin -add_group $ScstGroup -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle
$SUDO_PREFIX scstadmin -add_init $InitiatorName -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup
$SUDO_PREFIX scstadmin -write_config /etc/scst.conf

$SUDO_PREFIX scstadmin -list_group

echo ''
echo "======================================================"
echo "Target, group, and initiator displayed.               "
echo "======================================================"

sleep 5

clear

# Create file-backed devices for LUNS for Oracle ASM diskgroup SYSD1

if [ "$AsmRedundancy" = 'external' ]
then
	
	if [ ! -e /asm0 ]
	then
	$SUDO_PREFIX mkdir /asm0
	fi
	
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm0/asm_sysd1_00.img

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for sysd1 "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_sysd1*
	
	sleep 5

	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm0/asm_data1_00.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm0/asm_reco1_00.img

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for data1    "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_data*

	sleep 5

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for reco1     "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_reco*

	sleep 5
	
	echo ''
	echo "======================================================"
	echo "Devices for sysd1, data1, and reco1 displayed.        "
	echo "======================================================"

	sleep 5

	clear
	
	echo ''
	echo "======================================================"
	echo "Open SCST devices and create LUNs...                  "
	echo "======================================================"
	echo ''

	sleep 5

	# Open file-backed devices for Oracle ASM diskgroup SYSD1
	
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_sysd1_00.img

	# Open file-backed devices for Oracle ASM diskgroups DATA and FRA

	$SUDO_PREFIX scstadmin -open_dev asm_data1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_data1_00.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_reco1_00.img$LogicalBlkSiz

	# Add LUNs for Oracle ASM diskgroup SYSD1 to SCST iscsi target

	$SUDO_PREFIX scstadmin -add_lun 0 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_00

	# Add LUNs for Oracle ASM diskgroups DATA and FRA to SCST iscsi target

	$SUDO_PREFIX scstadmin -add_lun 1 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_00
	$SUDO_PREFIX scstadmin -add_lun 2 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_00
	
	echo ''
	echo "======================================================"
	echo "SCST devices and LUNs configured.                     "
	echo "======================================================"

	sleep 5

	clear

fi

if [ "$AsmRedundancy" = 'normal' ]
then

	if [ ! -e /asm0 ]
	then
	$SUDO_PREFIX mkdir /asm0
	fi

	if [ ! -e /asm1 ]
	then
	$SUDO_PREFIX mkdir /asm1
	fi

	if [ ! -e /asm2 ]
	then
	$SUDO_PREFIX mkdir /asm2
	fi

	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm0/asm_sysd1_00.img
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm1/asm_sysd1_01.img
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm2/asm_sysd1_02.img

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for sysd1 "
	echo "Sleeping for 10 seconds...                            "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_sysd1*
	ls -lrt /asm1/asm_sysd1*
	ls -lrt /asm2/asm_sysd1*

	sleep 10

	# Create file-backed devices for LUNS for Oracle ASM diskgroups DATA and FRA

	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm0/asm_data1_00.img
	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm1/asm_data1_01.img
	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm2/asm_data1_02.img

	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm0/asm_reco1_00.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm1/asm_reco1_01.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm2/asm_reco1_02.img

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for data     "
	echo "Sleeping for 10 seconds...                            "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_data*
	ls -lrt /asm1/asm_data*
	ls -lrt /asm2/asm_data*

	sleep 10

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for reco      "
	echo "Sleeping for 10 seconds...                            "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_reco*
	ls -lrt /asm1/asm_reco*
	ls -lrt /asm2/asm_reco*

	sleep 10

	# Open file-backed devices for Oracle ASM diskgroup SYSD1

	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_sysd1_00.img
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_01 -handler vdisk_fileio -attributes filename=/asm1/asm_sysd1_01.img
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_02 -handler vdisk_fileio -attributes filename=/asm2/asm_sysd1_02.img

	# Open file-backed devices for Oracle ASM diskgroups DATA and FRA

	$SUDO_PREFIX scstadmin -open_dev asm_data1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_data1_00.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_data1_01 -handler vdisk_fileio -attributes filename=/asm1/asm_data1_01.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_data1_02 -handler vdisk_fileio -attributes filename=/asm2/asm_data1_02.img$LogicalBlkSiz

	$SUDO_PREFIX scstadmin -open_dev asm_reco1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_reco1_00.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_01 -handler vdisk_fileio -attributes filename=/asm1/asm_reco1_01.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_02 -handler vdisk_fileio -attributes filename=/asm2/asm_reco1_02.img$LogicalBlkSiz

	# Add LUNs for Oracle ASM diskgroup SYSD1 to SCST iscsi target

	$SUDO_PREFIX scstadmin -add_lun 0 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_00
	$SUDO_PREFIX scstadmin -add_lun 1 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_01
	$SUDO_PREFIX scstadmin -add_lun 2 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_02

	# Add LUNs for Oracle ASM diskgroups DATA and FRA to SCST iscsi target

	$SUDO_PREFIX scstadmin -add_lun 3 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_00
	$SUDO_PREFIX scstadmin -add_lun 4 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_01
	$SUDO_PREFIX scstadmin -add_lun 5 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_02

	$SUDO_PREFIX scstadmin -add_lun 6 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_00
	$SUDO_PREFIX scstadmin -add_lun 7 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_01
	$SUDO_PREFIX scstadmin -add_lun 8 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_02
fi

if [ "$AsmRedundancy" = 'high' ]
then

	if [ ! -e /asm0 ]
	then
	$SUDO_PREFIX mkdir /asm0
	fi

	if [ ! -e /asm1 ]
	then
	$SUDO_PREFIX mkdir /asm1
	fi

	if [ ! -e /asm2 ]
	then
	$SUDO_PREFIX mkdir /asm2
	fi

	if [ ! -e /asm3 ]
	then
	$SUDO_PREFIX mkdir /asm3
	fi

	if [ ! -e /asm4 ]
	then
	$SUDO_PREFIX mkdir /asm4
	fi

	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm0/asm_sysd1_00.img
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm1/asm_sysd1_01.img
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm2/asm_sysd1_02.img
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm3/asm_sysd1_03.img
	$SUDO_PREFIX fallocate -l $Sysd1SizeGb /asm4/asm_sysd1_04.img

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for sysd1 "
	echo "Sleeping for 10 seconds...                            "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_sysd1*
	ls -lrt /asm1/asm_sysd1*
	ls -lrt /asm2/asm_sysd1*
	ls -lrt /asm3/asm_sysd1*
	ls -lrt /asm4/asm_sysd1*

	sleep 10

	# Create file-backed devices for LUNS for Oracle ASM diskgroups DATA and FRA

	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm0/asm_data1_00.img
	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm1/asm_data1_01.img
	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm2/asm_data1_02.img
	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm3/asm_data1_03.img
	$SUDO_PREFIX fallocate -l $Data1SizeGb /asm4/asm_data1_04.img

	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm0/asm_reco1_00.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm1/asm_reco1_01.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm2/asm_reco1_02.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm3/asm_reco1_03.img
	$SUDO_PREFIX fallocate -l $Reco1SizeGb /asm4/asm_reco1_04.img

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for data     "
	echo "Sleeping for 10 seconds...                            "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_data*
	ls -lrt /asm1/asm_data*
	ls -lrt /asm2/asm_data*
	ls -lrt /asm3/asm_data*
	ls -lrt /asm4/asm_data*

	sleep 10

	echo ''
	echo "======================================================"
	echo "Verify that device backing files created for reco     "
	echo "Sleeping for 10 seconds...                            "
	echo "======================================================"
	echo ''

	ls -lrt /asm0/asm_reco*
	ls -lrt /asm1/asm_reco*
	ls -lrt /asm2/asm_reco*
	ls -lrt /asm3/asm_reco*
	ls -lrt /asm4/asm_reco*

	sleep 10

	# Open file-backed devices for Oracle ASM diskgroup SYSD1

	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_sysd1_00.img
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_01 -handler vdisk_fileio -attributes filename=/asm1/asm_sysd1_01.img
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_02 -handler vdisk_fileio -attributes filename=/asm2/asm_sysd1_02.img
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_03 -handler vdisk_fileio -attributes filename=/asm3/asm_sysd1_03.img
	$SUDO_PREFIX scstadmin -open_dev asm_sysd1_04 -handler vdisk_fileio -attributes filename=/asm4/asm_sysd1_04.img

	# Open file-backed devices for Oracle ASM diskgroups DATA and FRA

	$SUDO_PREFIX scstadmin -open_dev asm_data1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_data1_00.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_data1_01 -handler vdisk_fileio -attributes filename=/asm1/asm_data1_01.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_data1_02 -handler vdisk_fileio -attributes filename=/asm2/asm_data1_02.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_data1_03 -handler vdisk_fileio -attributes filename=/asm3/asm_data1_03.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_data1_04 -handler vdisk_fileio -attributes filename=/asm4/asm_data1_04.img$LogicalBlkSiz

	$SUDO_PREFIX scstadmin -open_dev asm_reco1_00 -handler vdisk_fileio -attributes filename=/asm0/asm_reco1_00.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_01 -handler vdisk_fileio -attributes filename=/asm1/asm_reco1_01.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_02 -handler vdisk_fileio -attributes filename=/asm2/asm_reco1_02.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_03 -handler vdisk_fileio -attributes filename=/asm3/asm_reco1_03.img$LogicalBlkSiz
	$SUDO_PREFIX scstadmin -open_dev asm_reco1_04 -handler vdisk_fileio -attributes filename=/asm4/asm_reco1_04.img$LogicalBlkSiz

	# Add LUNs for Oracle ASM diskgroup SYSD1 to SCST iscsi target

	$SUDO_PREFIX scstadmin -add_lun 0 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_00
	$SUDO_PREFIX scstadmin -add_lun 1 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_01
	$SUDO_PREFIX scstadmin -add_lun 2 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_02
	$SUDO_PREFIX scstadmin -add_lun 3 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_03
	$SUDO_PREFIX scstadmin -add_lun 4 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_sysd1_04

	# Add LUNs for Oracle ASM diskgroups DATA and FRA to SCST iscsi target

	$SUDO_PREFIX scstadmin -add_lun 5 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_00
	$SUDO_PREFIX scstadmin -add_lun 6 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_01
	$SUDO_PREFIX scstadmin -add_lun 7 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_02
	$SUDO_PREFIX scstadmin -add_lun 8 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_03
	$SUDO_PREFIX scstadmin -add_lun 9 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_data1_04

	$SUDO_PREFIX scstadmin -add_lun 10 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_00
	$SUDO_PREFIX scstadmin -add_lun 11 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_01
	$SUDO_PREFIX scstadmin -add_lun 12 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_02
	$SUDO_PREFIX scstadmin -add_lun 13 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_03
	$SUDO_PREFIX scstadmin -add_lun 14 -driver iscsi -target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -group $ScstGroup -device asm_reco1_04

fi

echo ''
echo "======================================================="
echo "Write SCST configuration to /etc/scst.conf file...     "
echo "======================================================="

sleep 5

$SUDO_PREFIX scstadmin -write_config /etc/scst.conf
sudo cat /etc/scst.conf

echo "======================================================="
echo "Write SCST configuration to /etc/scst.conf file...     "
echo "======================================================="

sleep 10

clear

echo ''
echo "======================================================="
echo " Enable SCST target for access...                      "
echo "======================================================="
echo ''

$SUDO_PREFIX scstadmin -enable_target iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -driver iscsi
$SUDO_PREFIX scstadmin -write_config /etc/scst.conf

echo ''
echo "======================================================="
echo " Enable SCST target for access completed.              "
echo "======================================================="

sleep 5

clear

echo ''
echo "======================================================="
echo "Answer 'y' is passed automatically...                  "
echo "======================================================="
 
echo "y
quit
" | $SUDO_PREFIX scstadmin -set_drv_attr iscsi -attributes enabled=1 
sleep 5
$SUDO_PREFIX scstadmin -write_config /etc/scst.conf

echo ''
echo "======================================================="
echo "Attribute configured.                                  "
echo "======================================================="

sleep 5

clear

function GetUbuntuMajorRelease {
	lsb_release -r | cut -f1 -d'.' | cut -f2 -d':' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
UbuntuMajorRelease=$(GetUbuntuMajorRelease)

if [ $UbuntuMajorRelease -gt 14 ]
then
	echo ''
	echo "======================================================="
	echo "Create files needed for the (uekuscst) service...      "
	echo "======================================================="
	echo ''
else
	echo ''
	echo "======================================================="
	echo "Create Upstart Job and Autostart for SCST...           "
	echo "======================================================="
	echo ''
fi

sleep 5

if [ ! -d /etc/network/openvswitch ]
then
$SUDO_PREFIX mkdir -p /etc/network/openvswitch
fi

if [ ! -d /etc/network/if-down.d ]
then
$SUDO_PREFIX mkdir -p /etc/network/if-down.d
fi

Sw2Exist=sw
ifconfig sw2 >/dev/null 2>&1
if [ $? -eq 0 ]
then
if   [ $LinuxFlavor = 'Red' ]
then
	function CheckSw2Exist {
	ifconfig sw2 | cut -f1 -d':' | head -1
	}
	Sw2Exist=$(CheckSw2Exist)
elif [ $LinuxFlavor = 'Ubuntu' ] 
then
	function CheckSw2Exist {
	ifconfig sw2 | cut -f1 -d':' | head -1 | cut -f1 -d' '
	}
	Sw2Exist=$(CheckSw2Exist)
elif [ $LinuxFlavor = 'Debian' ] 
then
	function CheckSw2Exist {
	ifconfig sw2 | cut -f1 -d':' | head -1 | cut -f1 -d' '
	}
	Sw2Exist=$(CheckSw2Exist)
fi
fi

Sw3Exist=sw
ifconfig sw3 >/dev/null 2>&1
if [ $? -eq 0 ]
then
if   [ $LinuxFlavor = 'Red' ]
then
	function CheckSw3Exist {
	ifconfig sw3 | cut -f1 -d':' | head -1
	}
	Sw3Exist=$(CheckSw3Exist)
elif [ $LinuxFlavor = 'Ubuntu' ]
then
	function CheckSw3Exist {
	ifconfig sw3 | cut -f1 -d':' | head -1 | cut -f1 -d' '
	}
	Sw3Exist=$(CheckSw3Exist)
elif [ $LinuxFlavor = 'Debian' ]
then
	function CheckSw3Exist {
	ifconfig sw3 | cut -f1 -d':' | head -1 | cut -f1 -d' '
	}
	Sw3Exist=$(CheckSw3Exist)
fi
fi

sudo sh -c "echo '#!/bin/bash'																		 > /etc/network/openvswitch/stop_scst.sh"
if   [ $LinuxFlavor = 'Red' ]
then
	sudo sh -c "echo '/usr/sbin/iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1  --logout'		>> /etc/network/openvswitch/stop_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ]
then
	if [ $UbuntuMajorRelease -gt 14 ]
	then
		sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1  --logout'	>> /etc/network/openvswitch/stop_scst.sh"
	else
		sudo update-rc.d -f scst remove
		echo ''
		sudo update-rc.d scst defaults
		echo ''
		sudo sh -c "echo '!#/bin/bash'                                                                                                                           > /etc/network/openvswitch/login-scst.sh"
		sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1  --login'		>> /etc/network/openvswitch/login-scst.sh"
		sudo chmod 775 /etc/network/openvswitch/login-scst.sh
		sudo sh -c "echo 'description   \"login scst\"'														 > /etc/init/login-scst.conf"
		sudo sh -c "echo 'start on started rc'															>> /etc/init/login-scst.conf"
		sudo sh -c "echo 'task'																	>> /etc/init/login-scst.conf"
		sudo sh -c "echo 'exec /etc/network/openvswitch/login-scst.sh'												>> /etc/init/login-scst.conf"
	fi
elif [ $LinuxFlavor = 'Debian' ]
then
	if [ $UbuntuMajorRelease -gt 14 ]
	then
		sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1  --logout'	>> /etc/network/openvswitch/stop_scst.sh"
	else
		sudo update-rc.d -f scst remove
		echo ''
		sudo update-rc.d scst defaults
		echo ''
		sudo sh -c "echo '!#/bin/bash'                                                                                                                           > /etc/network/openvswitch/login-scst.sh"
		sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1  --login'		>> /etc/network/openvswitch/login-scst.sh"
		sudo chmod 775 /etc/network/openvswitch/login-scst.sh
		sudo sh -c "echo 'description   \"login scst\"'														 > /etc/init/login-scst.conf"
		sudo sh -c "echo 'start on started rc'															>> /etc/init/login-scst.conf"
		sudo sh -c "echo 'task'																	>> /etc/init/login-scst.conf"
		sudo sh -c "echo 'exec /etc/network/openvswitch/login-scst.sh'												>> /etc/init/login-scst.conf"
	fi
fi

if   [ $Sw2Exist = 'sw2' ]
then
if   [ $LinuxFlavor = 'Red' ]
then
sudo sh -c "echo '/usr/sbin/iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.40.1 --logout'	>> /etc/network/openvswitch/stop_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.40.1 --logout'	>> /etc/network/openvswitch/stop_scst.sh"
fi
fi

if   [ $Sw3Exist = 'sw3' ]
then
if   [ $LinuxFlavor = 'Red' ] 
then
sudo sh -c "echo '/usr/sbin/iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.41.1 --logout'	>> /etc/network/openvswitch/stop_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.41.1 --logout'	>> /etc/network/openvswitch/stop_scst.sh"
fi
fi

if   [ $LinuxFlavor = 'Red' ]
then
sudo sh -c "echo '/usr/sbin/multipath -F'														>> /etc/network/openvswitch/stop_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
sudo sh -c "echo '/sbin/multipath -F'															>> /etc/network/openvswitch/stop_scst.sh"
fi

sudo sh -c "echo '#!/bin/bash'																>> /etc/network/openvswitch/strt_scst.sh"
if   [ $LinuxFlavor = 'Red' ]
then																
sudo sh -c "echo '/usr/sbin/iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1   --login'	>> /etc/network/openvswitch/strt_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1   --login'	>> /etc/network/openvswitch/strt_scst.sh"
fi

if   [ $Sw2Exist = 'sw2' ]
then
if   [ $LinuxFlavor = 'Red' ]
then
sudo sh -c "echo '/usr/sbin/iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.40.1 --login'	>> /etc/network/openvswitch/strt_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.40.1 --login'	>> /etc/network/openvswitch/strt_scst.sh"
fi
fi

if   [ $Sw3Exist = 'sw3' ]
then
if   [ $LinuxFlavor = 'Red' ]
then
sudo sh -c "echo '/usr/sbin/iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.41.1 --login'	>> /etc/network/openvswitch/strt_scst.sh"
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
then
sudo sh -c "echo '/usr/bin/iscsiadm  --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.41.1 --login'	>> /etc/network/openvswitch/strt_scst.sh"
fi
fi

sudo chmod +x /etc/network/openvswitch/st*_scst.sh

sudo ls -l /etc/network/openvswitch/st*_scst.sh

if [ $UbuntuMajorRelease -gt 14 ] || [ $LinuxFlavor = 'Ubuntu' ]
then
	echo ''
	echo "======================================================="
	echo "Created files needed for the (uekuscst) service.       "
	echo "======================================================="
	echo ''
else
	echo ''
	echo "======================================================="
	echo "Created Upstart Job and Autostart for SCST.            "
	echo "======================================================="
	echo ''
fi

if [ $UbuntuMajorRelease -ge 9 ] || [ $LinuxFlavor = 'Debian' ]
then
	echo ''
	echo "======================================================="
	echo "Created files needed for the (uekuscst) service.       "
	echo "======================================================="
	echo ''
else
	echo ''
	echo "======================================================="
	echo "Created Upstart Job and Autostart for SCST.            "
	echo "======================================================="
	echo ''
fi

sleep 5

clear

echo ''
echo "======================================================"
echo "Discover portals and targets...                       "
echo "======================================================"
echo ''

sudo iscsiadm -m discovery -t sendtargets --portal 127.0.0.1
sudo iscsiadm -m node --login

echo ''
echo "======================================================"
echo "Portals and targets discovered.                       "
echo "======================================================"

sleep 5

clear

echo ''
echo "======================================================"
echo "Set Portal startups.                                  "
echo "You can change 'manual' to 'automatic' later.         "
echo "======================================================"
echo ''

sleep 7

function GetAllPortals {
sudo iscsiadm -m discovery -t sendtargets --portal 127.0.0.1 | egrep -v '10.207.40.1|10.207.41.1' | cut -f1 -d':' |  sed 's/$/ /' | tr -d '\n'
}
AllPortals=$(GetAllPortals)

function GetPortals {
sudo iscsiadm -m discovery -t sendtargets --portal 127.0.0.1 | egrep '10.207.40.1|10.207.41.1' | cut -f1 -d':' |  sed 's/$/ /' | tr -d '\n'
}
Portals=$(GetPortals)

echo 'Auxiliary portals that will NOT be used:'
echo '' 
echo $AllPortals
echo ''
echo 'Setting manual portal startups...'
echo ''

for i in $AllPortals
do
sudo iscsiadm -m node --login  >/dev/null 2>&1
sudo iscsiadm -m node -T iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -p $i --op update -n node.startup -v manual >/dev/null 2>&1
# sudo iscsiadm -m node --logout >/dev/null 2>&1
sudo multipath -F
done

# echo ''
# echo 'OpenvSwitch portals that will be used:'
# echo ''
# echo $Portals

# for i in $Portals
# do
# echo ''
# echo "Setting automatic portals $i ..."
# echo ''
# sudo iscsiadm -m node -T iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -p $i --login
# sudo iscsiadm -m node -T iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle -p $i --op update -n node.startup -v automatic
# done

echo ''
echo "======================================================"
echo "Set the startups of all portals to manual.            "
echo "======================================================"

sleep 5

clear

if [ $UbuntuMajorRelease -gt 14 ] && [ $LinuxFlavor = 'Ubuntu' ]
then
	echo ''
	echo "======================================================"
	echo "Create a service (uekuscst) to manage SCST storage    "
	echo "======================================================"
	echo ''

	sudo sh -c "echo '[Unit]'             	         					 > /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Description=uekuscst Service'  					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Wants=network-online.target sw2.service sw3.service scst.service'	>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'After=network-online.target sw2.service sw3.service scst.service'	>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Before=shutdown.target reboot.target halt.target'			>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo ''                                 					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo '[Service]'                        					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Type=oneshot'                     					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'User=root'                        					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'RemainAfterExit=yes'              					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_scst.sh'			>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/stop_scst.sh'			>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo ''                                 					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo '[Install]'                        					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'       					>> /etc/systemd/system/uekuscst.service"

	sudo chmod 644 /etc/systemd/system/uekuscst.service

	sudo systemctl enable uekuscst.service
	echo ''
	sudo cat /etc/systemd/system/uekuscst.service

	echo ''
	echo "======================================================"
	echo "Service (uekuscst) created.                           "
	echo "======================================================"

	sleep 5

	clear
fi

if [ $UbuntuMajorRelease -ge 9 ] && [ $LinuxFlavor = 'Debian' ]
then
	echo ''
	echo "======================================================"
	echo "Create a service (uekuscst) to manage SCST storage    "
	echo "======================================================"
	echo ''

	sudo sh -c "echo '[Unit]'             	         					 > /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Description=uekuscst Service'  					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Wants=network-online.target sw2.service sw3.service scst.service'	>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'After=network-online.target sw2.service sw3.service scst.service'	>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Before=shutdown.target reboot.target halt.target'			>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo ''                                 					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo '[Service]'                        					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'Type=oneshot'                     					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'User=root'                        					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'RemainAfterExit=yes'              					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_scst.sh'			>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/stop_scst.sh'			>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo ''                                 					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo '[Install]'                        					>> /etc/systemd/system/uekuscst.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'       					>> /etc/systemd/system/uekuscst.service"

	sudo chmod 644 /etc/systemd/system/uekuscst.service

	sudo systemctl enable uekuscst.service
	echo ''
	sudo cat /etc/systemd/system/uekuscst.service

	echo ''
	echo "======================================================"
	echo "Service (uekuscst) created.                           "
	echo "======================================================"

	sleep 5

	clear
fi

sleep 5

echo ''
echo "======================================================"
echo "Create the /etc/network/if-down.d/scst-net file..     "
echo "======================================================"
echo ''

sudo sh -c "echo '#!/bin/sh'  													 	>  /etc/network/if-down.d/scst-net"
sudo sh -c "echo '# This file is only used with orabuntu not with uekulele but is included in the distribution.'		 	>> /etc/network/if-down.d/scst-net"
sudo sh -c "echo 'scst-net - logout of scst targets'  										 	>> /etc/network/if-down.d/scst-net"
sudo sh -c "echo 'iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 127.0.0.1   --logout'	>> /etc/network/if-down.d/scst-net"
if [ $Sw2Exist = 'sw2' ]
then
sudo sh -c "echo 'iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.40.1 --logout'	>> /etc/network/if-down.d/scst-net"
fi
if [ $Sw2Exist = 'sw2' ]
then
sudo sh -c "echo 'iscsiadm --mode node --targetname iqn.$DATEYR-$DATEMO.$DOMAIN:$HostName.san.asm.oracle --portal 10.207.41.1 --logout'	>> /etc/network/if-down.d/scst-net"
fi

sudo cat /etc/network/if-down.d/scst-net

echo ''
echo "======================================================"
echo "File created.                                         "
echo "======================================================"

sleep 5

clear

echo ''
echo "======================================================="
echo "Verify that SCST SAN for Oracle is configured.         "
echo "======================================================="
echo ''

sleep 5

$SUDO_PREFIX scstadmin -list_group

echo ''
echo "======================================================="
echo "SCST SAN for Oracle is configured.                     "
echo "======================================================="

sleep 10

clear
