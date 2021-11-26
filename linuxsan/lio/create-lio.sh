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

#   !! SEE THE README FILE FOR COMPLETE INSTRUCTIONS FIRST BEFORE RUNNING !!
#
#   sudo ALL privilege is required 	prior to running! (for Debian-y Linuxes)
#   root is required                    prior to running! (for RedHat-y Linuxes)
#   internet connectivity is required 	prior to running!
#
#   Note:	Following line shows options you can set for running create-scst-target.sh in this file.
#           	Set the com.yourdomain, the scstadmin groupname, the ASM redundancy, the sizes of your LUNs, and the logical blocksize in this file if you want non-default values.
#       	Review the create-scst-target.sh for more details and/or the README file.
#
#   Example:	create-scst-target.sh com.urdomain1 lxc1 [external|normal|high] 10G 30G 30G [512|4096]
#
#   IMPORTANT!    Remeber that if you use non-default settings for create-scst-target.sh BE SURE TO SPECIFY ALL OF THEM $1 through $7 !!  Otherwise they will be misinterpreted by the script.
#    Note1:     If you do not pass in a "com.yourdomain" parameter it will be set to default value of com.urdomain1
#    Note2:     If you do not pass in a "ScstGroupName"  parameter it will be set to default value of lxc1
#    Note3:     If you do not pass in a "AsmRedundancy"  parameter it will be set to default value of external
#    Note4:     If you do not pass in a "Sysd1SizeGb"    parameter it will be set to default value of 1Gb
#    Note5:     If you do not pass in a "Data1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note6:     If you do not pass in a "Reco1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note7:     If you do not pass in a "LogicalBlkSiz"  parameter it will be set to default value of null (LIO by default uses 512-byte logical sector.  Optionally set this to 4096).)
#
#   Note:	Following line shows options you can set for running create-scst-multipath.sh in this file.
#       	Set the owner, group, mode and ContainerName if you want non-default values.
#       	Review the create-scst-multipath.sh for more details and/or the README file.
#
#   Example:	create-scst-multipath.sh Owner Group Mode ContainerName
#
#    Note1:     If you do not pass in a "Owner"          parameter it will be set to default value of grid
#    Note2:     If you do not pass in a "Group"          parameter it will be set to default value of asmadmin
#    Note3:     If you do not pass in a "Mode"           parameter it will be set to default value of 0660
#    Note4:     If you do not pass in a "ContainerName"  parameter it will be set to default value of $StoragePrefix_luns

#   Network WAN connectivity is required for these scripts.

clear

echo ''
echo "======================================================="
echo "Orabuntu-LXC / Uekulele LIO Installer Automation...   "
echo "======================================================="

sleep 5

clear

LXDStorageDriver=$1
if [ -z $1 ]
then
        LXDStorageDriver=none
fi

RevDomain1=$2
if [ -z $2 ]
then
        RevDomain1=com.urdomain1
fi

Lun1Name=$3
if [ -z $3 ]
then
        Lun1Name=lun1
fi

Lun2Name=$4
if [ -z $4 ]
then
        Lun2Name=lun2
fi

Lun3Name=$5
if [ -z $5 ]
then
        Lun3Name=lun3
fi

Lun1Size=$6
if [ -z $6 ]
then
        Lun1Size=1G
fi

Lun2Size=$7
if [ -z $7 ]
then
        Lun2Size=1G
fi

Lun3Size=$8
if [ -z $8 ]
then
        Lun3Size=1G
fi

LogBlkSz=$9
if [ -z $9 ]
then
        LogBlkSz=512
fi

ScstLunPrefix=${10}
if [ -z ${10} ]
then
        ScstLunPrefix=lxc
fi

if [ $LXDStorageDriver = 'none' ]
then
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
else
        echo ''
        echo "======================================================="
        echo "Establish sudo privileges ...                          "
        echo "======================================================="
        echo ''

        $SUDO_PREFIX date

        echo ''
        echo "======================================================="
        echo "Establish sudo privileges successful.                  "
        echo "======================================================="
        echo ''
fi

sleep 5

clear

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

		if [ $OracleDistroRelease -eq 6 ]
		then
			echo ''
			echo "======================================================="
			echo "Oracle Corporation desupports Oracle Linux 6 March 2021"
			echo "======================================================="
			echo ''

			sleep 5

			clear
		fi

        elif [ $OracleDistroRelease -eq 8 ]
        then
                CutIndex=6
        fi

        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }

        function GetRedHatMinorVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f2 -d'.'
        }

        RedHatVersion=$(GetRedHatVersion)
        RedHatMinorVersion=$(GetRedHatMinorVersion)
        RHV=$RedHatVersion
        RHMV=$RedHatMinorVersion
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
                        sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
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

if [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ] || [ $LinuxFlavor = 'Pop_OS' ]
then
        SUDO_PREFIX=sudo
        echo ''
        echo "======================================================="
        echo "Install iscsi-initiator-utils...                       "
        echo "======================================================="
        echo ''

        $SUDO_PREFIX date
        $SUDO_PREFIX yum -y install iscsi-initiator-utils

        echo ''
        echo "======================================================="
        echo "Done: Install iscsi-initiator-utils.                   "
        echo "======================================================="

elif [ $LinuxFlavor = 'CentOS' ]
then
        SUDO_PREFIX=sudo

        echo ''
        echo "======================================================="
        echo "Install iscs-initiator-utils package...                "
        echo "======================================================="
        echo ''

        $SUDO_PREFIX yum -y install iscsi-initiator-utils

        echo ''
        echo "======================================================="
        echo "Done: Install iscsi-initiator-utils.                   "
        echo "======================================================="

elif [ $LinuxFlavor = 'Fedora' ]
then
        SUDO_PREFIX=sudo

        echo ''
        echo "======================================================="
        echo "Install iscs-initiator-utils package...                "
        echo "======================================================="
        echo ''

        $SUDO_PREFIX dnf -y install iscsi-initiator-utils

        echo ''
        echo "======================================================="
        echo "Done: Install iscsi-initiator-utils.                   "
        echo "======================================================="

elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'Oracle' ]
then
        SUDO_PREFIX=sudo

        echo ''
        echo "======================================================="
        echo "Install iscs-initiator-utils package...                "
        echo "======================================================="
        echo ''

        $SUDO_PREFIX yum -y install iscsi-initiator-utils

        echo ''
        echo "======================================================="
        echo "Done: Install iscsi-initiator-utils.                   "
        echo "======================================================="
fi

sleep 5

clear

echo ''
echo "======================================================="
echo "                                                       "
echo "LIO target is maintained by Datera, Inc.               "
echo "                                                       "
echo "In January 2011 LIO was mered in Linux kernel mainline."
echo "                                                       "
echo "Learn more at:                                         "
echo "                                                       "
echo "https://en.wikipedia.org/wiki/LIO_(SCSI_target)        "
echo "                                                       "
echo "======================================================="

sleep 7

clear 

echo ''
echo "======================================================="
echo "                                                       "
echo "Orabuntu-LXC is created and maintained by:             "
echo "                                                       "
echo "Gilbert Standen                                        "
echo "                                                       "
echo "This LIO SAN building script is part of Orabuntu-LXC  "
echo "                                                       "
echo "Learn more at:                                         "
echo "                                                       "
echo "https://gstanden.github.io/brandydandyoracle           "
echo "https://github.com/gstanden/orabuntu-lxc               "
echo "                                                       "
echo "======================================================="

sleep 7

clear

echo ''
echo "======================================================="
echo "                                                       "
echo "This LIO automated script has been tested & works on: "
echo "                                                       "
echo "DISTRO VERSION            PKG     KERNEL               "
echo "                                                       "
echo "Ubuntu 20.04 focal        DKMS    kernel 5.4+          "
echo "Ubuntu 19.10 eoan         DKMS    kernel 5.0+          "
echo "Ubuntu 19.04 disco        DKMS    kernel 5.0+          "
echo "Ubuntu 18.10 cosmic       DKMS    kernel 4.12+         "
echo "Ubuntu 18.04 bionic       DKMS    kernel 4.12+         "
echo "Ubuntu 17.10 artful       DKMS    kernel 4.12+         "
echo "Ubuntu 17.04 zesty        DKMS    kernel 4.10+         "
echo "Ubuntu 16.04 xenial       DKMS    kernel 4.4+          "
echo "Ubuntu 15.04 vivid        DKMS    kernel 3.19+         "
echo "Ubuntu 14.04 trusty       DKMS    kernel 3.13+         "
echo "Debian  9.1  stretch      DKMS    kernel See Note 2    "
echo "Oracle  7,8  linux        RPM     kernel See Note 1    "
echo "CentOS  7,8  linux        RPM     kernel See Note 1    "
echo "RedHat  7,8  linux        RPM     kernel See Note 1    "
echo "Oracle  6.x  linux        RPM     kernel See Note 1    "
echo "CentOS  6.x  linux        RPM     kernel See Note 1    "
echo "RedHat  6.x  linux        RPM     kernel See Note 1    "
echo "                                                       "
echo "======================================================="
echo ''

sleep 15

clear

echo ''
echo "======================================================="
echo "                                                       "
echo "Reminder:  create a LUN resizing guide for LIO.        "
echo "                                                       "
echo "======================================================="

sleep 7

clear

echo ''
echo "======================================================="
echo "Set file ownerships ...                                "
echo "======================================================="
echo ''

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

sudo chown -R $Owner:$Group /opt/olxc/home/lio-files
sudo ls -l /opt/olxc/home/lio-files

echo ''
echo "======================================================="
echo "Done: Set file ownerships.                             "
echo "======================================================="
echo ''

sleep 5

clear

echo ''
echo "======================================================="
echo "Ping test ...                                          "
echo "======================================================="
echo ''

ping -4 -c 3 yum.oracle.com
Png1=`echo $?`

if [ "$Png1" -ne 0 ]
then
	echo ''
	echo "======================================================="
	echo "Possible network issues...                             "
	echo "======================================================="
	sleep 5
else
	echo ''
	echo "======================================================="
	echo "Network ping test verification complete.               "
	echo "======================================================="
	echo ''
fi

sleep 5

clear

echo ''
echo "======================================================="
echo "Check Kernel Version of running kernel...                "
echo "======================================================="
echo ''

# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.
# GLS 20160924 LIO 3.1 does not require a custom kernel build for kernels >= 2.6.30 so now we check that kernel is >= 2.6.30.
# GLS 20160924 If the kernel version is lower than 2.6.30 it will be necessary for you to compile a custom kernel.

function VersionKernelPassFail () {
    ./vercomp | cut -f1 -d':'
}
KernelPassFail=$(VersionKernelPassFail)
echo $KernelPassFail

if [ $KernelPassFail = 'Pass' ]
then
echo ''
echo "======================================================="
echo "Done: Check Kernel Version of running kernel.          "
echo "======================================================="

sleep 5

clear

if [ $LinuxFlavor = 'Oracle' ]
then
	echo ''
	echo "======================================================="
	echo "Check Kernel Version of Oracle Linux 6 UEK ...         "
	echo "======================================================="
	echo ''

	function GetOracleLinuxVersion {
		cat /etc/oracle-release | cut -f5 -d' '
	}
	OracleLinuxVersion=$(GetOracleLinuxVersion)

	if [ $OracleLinuxVersion = '6.10' ]
	then

		function CheckAvailableUEK {
			sudo yum list updates | xargs -n3 | grep kernel-uek | tail -1 | cut -f2 -d' ' | rev | cut -f2-100 -d'.' | rev
		}
		AvailableUEK=$(CheckAvailableUEK)

		function GetLenAvailableUEK {
        		echo $AvailableUEK | wc -c
		}
		LenAvailableUEK=$(GetLenAvailableUEK)

		function GetRunningUEK {
        		uname -r | rev | cut -f3-100 -d'.' | rev
		}
		RunningUEK=$(GetRunningUEK)

		if [ $LenAvailableUEK -gt 1 ]
		then
        		function GetGrubUEK {
                		sudo sh -c "grep -c $AvailableUEK /boot/grub/grub.conf"
        		}
        		GrubUEK=$(GetGrubUEK)
		fi

 		echo ''
 	#	echo '============================================'
 		echo "AvailableUEK    = "$AvailableUEK
 	#	echo "LenAvailableUEK = "$LenAvailableUEK
 		echo "RunningUEK      = "$RunningUEK
	#	echo "GrubUEK         = "$GrubUEK
	#	echo '============================================'

		function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

		if [ $LenAvailableUEK -gt 1 ] && [ $(SoftwareVersion $AvailableUEK) -gt $(SoftwareVersion $RunningUEK) ]
		then
			echo ''
	        	echo "=============================================="
        		echo "                                              "
        		echo "    Install LIO:  Oracle 6.10 UEK UPDATE     "
        		echo "                                              "
        		echo "            !! NOTE IMPORTANT !!              "
        		echo "                                              "
        		echo "  UPDATE TO KERNEL VERSION CAN BREAK OTHER    "
        		echo "   KERNEL MODULES (SUCH AS ORACLE ASMLib).    "
        		echo "                                              "
			echo "            IF YOU ARE NOT SURE               "
        		echo "  HOW THIS KERNEL UPDATE WOULD AFFECT OTHER   "
        		echo "  MODULES RUNNING ON CURRENT KERNEL VERSION   "
        		echo "      THEN YOU CAN REJECT THIS UPDATE.        "
        		echo "                                              "
			echo "   To REJECT this update ANSWER 'N' below.    "
        		echo "   To ACCEPT this update ANSWER 'Y' below.    "
        		echo "                                              "
        		echo "   Answer 'Y' will cause AUTOMATIC UPDATE!    "
        		echo "   Answer 'Y' will cause AUTOMATIC REBOOT!    "
        		echo "                                              "
        		echo "After reboot login again as 'root' and re-run "
        		echo "             'create-scst.sh'                 "
        		echo "                                              "
        		echo "=============================================="
        		echo "                                              "
        		read -e -p "Install Type New or Reinstall [Y/N]     " -i "Y" UEKdate 
        		echo "                                              "
        		echo "=============================================="
        		echo ''

			if [ $UEKdate = 'Y' ]
			then
				sudo yum -y update
				echo ''
				sudo /usr/bin/ol_yum_configure.sh
				echo ''
				sleep 5
				sudo reboot
			fi
		fi
	fi
	
	echo ''
	echo "======================================================="
	echo "Done: Check Kernel Version of Oracle Linux 6 UEK.      "
	echo "======================================================="
	echo ''
fi

sleep 5

clear

echo ''
echo "======================================================="
echo "Next script:  create-scst-install.sh                   "
echo "======================================================="

sleep 5

clear

./create-lio-install.sh $SUDO_PREFIX

sleep 5

clear

echo ''
echo "======================================================="
echo "Check if LIO Standalone Install ...                   "
echo "======================================================="
echo ''

sleep 5

clear

function GetStandAlone {
        ip link | grep -c sw1
}
StandAlone=$(GetStandAlone)

if [ $StandAlone = 0 ]
then
	echo ''
	echo "======================================================="
	echo "Verify LIO to Standalone Install...                   "
	echo "======================================================="
	echo ''

	echo 'Setting SWITCH_IP to 1'
	sudo sed -i "s/SWITCH_IP/1/g"   /opt/olxc/home/scst-files/create-scst-target.sh
	
	echo ''
	echo "======================================================="
	echo "Done: Verify LIO to Standalone Install.               "
	echo "======================================================="
else
	echo ''
	echo "======================================================="
	echo "Verify LIO to Standalone Install...                   "
	echo "======================================================="
	echo ''

	echo "Not an LIO Standalone Install.                        "
	
	echo ''
	echo "======================================================="
	echo "Done: Verify LIO to Standalone Install.               "
	echo "======================================================="
	echo ''
fi

sleep 5

clear

echo ''
echo "======================================================="
echo "Done: Check if LIO Standalone Install.                "
echo "======================================================="
echo ''

sleep 5

clear

echo ''
echo "======================================================="
echo "Next script:  create-lio-target.sh                   "
echo "======================================================="

sleep 5

clear

# ZFS Pool
  ./create-lio-target.sh ubuntu ubuntu 0660 "$ScstLunPrefix"_luns ubuntu $ScstLunPrefix $RevDomain1 "$ScstLunPrefix"1 external $Lun1Name $Lun2Name $Lun3Name $Lun1Size $Lun2Size $Lun3Size $LogBlkSz orabuntu $SUDO_PREFIX $LXDStorageDriver

# Oracle Grid Infrastructure 18c
# ./create-lio-target.sh grid asmadmin 0660 asm_luns grid asm $RevDomain1 lxc1 external sysd data mgmt 1G 1G 1G 512 oracle $SUDO_PREFIX $LXDStorageDriver

# Blackberry WatchDox
# ./create-lio-target.sh watchdox watchdox 0660 wdx_luns watchdox wdx $RevDomain1 wksp1 external data fspa fcac 1G 1G 1G 512 blackberry $SUDO_PREFIX $LXDStorageDriver

echo ''
echo "======================================================="
echo "Next script:  create-scst-multipath.sh                   "
echo "======================================================="

sleep 5

clear
 
# ZFS Pool
  sudo ./create-lio-multipath.sh ubuntu 1000 ubuntu 1000 0660 "$ScstLunPrefix"_luns $ScstLunPrefix new $Release $SUDO_PREFIX

# Oracle Grid Infrastructure 18c
# sudo ./create-lio-multipath.sh grid 1098 asmadmin 1100 0660 asm_luns asm new $Release $SUDO_PREFIX

# Blackberry WatchDox
# sudo ./create-lio-multipath.sh watchdox 700 watchdox 700 0660 wdx_luns wdx new $Release $SUDO_PREFIX

fi
