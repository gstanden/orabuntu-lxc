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
#    Controlling script for Orabuntu-LXC

#    Host OS Supported: Oracle Linux 7, RedHat 7, CentOS 7, Fedora 27, Ubuntu 16/17

#    Usage:
#    Passing parameters in from the command line is possible but is not described herein. The supported usage is to configure this file as described below.
#    Capital 'X' means 'not used' do not replace leave as is.

clear

echo ''
echo "=============================================="
echo "Script: ADD.RELEASE.ON.HUB.HOST.1500.sh       "
echo "=============================================="
echo ''

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

                if [ -f /usr/bin/ol_yum_configure.sh ]
                then
                        sudo /usr/bin/ol_yum_configure.sh > /dev/null 2>&1
                fi

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

trap "exit" INT TERM; trap "kill 0" EXIT; sudo -v || exit $?; sleep 1; while true; do sleep 60; sudo -nv; done 2>/dev/null &

GRE=N
MTU=1500
LOGEXT=`date +"%Y-%m-%d.%R:%S"`

# Operation=addrelease
# OpType=add

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
        read -e -p "Install Type [new/rei/add]:             " -i "add" OpType
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
elif [ $OpType = 'add' ]
then
	Operation=addrelease
fi

if [ -z $2 ]
then
        Product=workspaces
        Product=oracle-db
	Product=oracle-gi-18c
        Product=no-product
else
        Product=$2
fi

if [ ! -d "$DistDir"/installs/logs ]
then
        sudo mkdir -p "$DistDir"/installs/logs
fi

if [ -f "$DistDir"/installs/logs/$USER.log ]
then
        sudo mv "$DistDir"/installs/logs/$USER.log "$DistDir"/installs/logs/$USER.log.$LOGEXT
fi

if [ ! -d /var/log/sudo-io ]
then
        sudo mkdir -m 750 /var/log/sudo-io
fi

if [ ! -f /etc/sudoers.d/orabuntu-lxc ]
then
        sudo sh -c "echo 'Defaults      logfile=\"$DistDir/installs/logs/$USER.log\"'  					>> /etc/sudoers.d/orabuntu-lxc"
        sudo sh -c "echo 'Defaults      log_input,log_output'                                                           >> /etc/sudoers.d/orabuntu-lxc"
        sudo sh -c "echo 'Defaults      iolog_dir=/var/log/sudo-io/%{user}'                                             >> /etc/sudoers.d/orabuntu-lxc"
        sudo chmod 0440 /etc/sudoers.d/orabuntu-lxc
fi

sudo yum -y     install net-tools > /dev/null 2>&1
sudo apt-get -y install net-tools > /dev/null 2>&1

if [ $AWS -eq 1 ]
then
        if   [ $AwsMtu -ge 9000 ]
        then
                # Until support for jumbo frames ready set 1500.
                sudo ifconfig eth0 mtu 1500
                AwsMtu=1500
		MultiHost="$Operation:N:X:X:X:X:$AwsMtu:X:X:$GRE:$Product"

        elif [ $AwsMtu -eq 1500 ]
        then
		MultiHost="$Operation:N:X:X:X:X:$AwsMtu:X:X:$GRE:$Product"
        fi
else
	MultiHost="$Operation:N:X:X:X:X:$MTU:X:X:$GRE:$Product"
fi

if [ $OpType = 'add' ]
then
	echo ''
	echo "=============================================="
	echo "Display Installation Parameters ...           "
	echo "=============================================="
	echo ''

	echo 'Linux Host Flavor         = '$LinuxFlavor

	if [ $LinuxFlavor != 'Ubuntu' ] && [ $LinuxFlavor != 'Pop_OS' ]
	then
        	echo 'Linux Host Release        = '$RedHatVersion
        	echo 'Linux Host Base Release   = '$Release
	else
        	echo 'Linux Host Release        = '$UbuntuVersion
        	echo 'Linux Host Base Release   = '$UbuntuMajorVersion
	fi

        MajorRelease=$8
        if [ -z $8 ]
        then
                MajorRelease=8
        fi
        # echo 'Oracle Container Release  = '$MajorRelease

        PointRelease=$2
        if [ -z $2 ]
        then
                PointRelease=3
        fi
        echo 'Oracle Container Version  = '$MajorRelease.$PointRelease

        NumCon=$3
        if [ -z $3 ]
        then
                NumCon=2
        fi
        echo 'Oracle Container Count    = '$NumCon

        Domain1=$4
        if [ -z $4 ]
        then
                Domain1=urdomain1.com
        fi
        echo 'Domain1                   = '$Domain1

        Domain2=$5
        if [ -z $5 ]
        then
                Domain2=urdomain2.com
        fi
        echo 'Domain2                   = '$Domain2

        NameServer=$6
        if [ -z $6 ]
        then
                NameServer=afns1
        fi
        echo 'NameServer                = '$NameServer

	/opt/olxc/home/ubuntu/Downloads/orabuntu-lxc-master/orabuntu/archives/product.tar

        /opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
        /opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
        /opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
        /opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
        /opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir

echo ''
echo "=============================================="
echo "Display Installation Parameters complete.     "
echo "=============================================="

else
	./anylinux-services.sh $MultiHost 
fi

exit

