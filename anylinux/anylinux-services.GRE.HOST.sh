#!/bin/bash

#    Copyright 2015-2018 Gilbert Standen
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

trap "exit" INT TERM; trap "kill 0" EXIT; sudo -v || exit $?; sleep 1; while true; do sleep 60; sudo -nv; done 2>/dev/null &

clear

echo ''
echo "=============================================="
echo "Script: anylinux-services.GRE.HOST.sh         "
echo "=============================================="

sleep 5

clear

GRE=Y 

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
	SPOKEIP='lan.ip.this.host'
#	SPOKEIP=192.168.7.27
else
	SPOKEIP=$2
fi

if [ -z $3 ]
then
	HUBIP='lan.ip.hub.host'
#	HUBIP=192.168.7.32
else
	HUBIP=$3
fi

if [ -z $4 ]
then
	HubUserAct=username
#	HubUserAct=orabuntu
else
	HubUserAct=$4
fi

if [ -z $4 ]
then
	HubSudoPwd=password
#	HubSudoPwd=balihigh
else
	HubSudoPwd=$5
fi

if [ $SPOKEIP = 'lan.ip.this.host' ] || [ $HUBIP = 'lan.ip.hub.host' ] || [ $HubUserAct = 'username' ] || [ $HubSudoPwd = 'password' ]
then
	echo 'You must edit this file first and set the SPOKEIIP, HUBIP, HubUserAct, and the HubSudoPwd'
	echo 'After setting these in this file re-run the script'
	echo 'Also ... be SURE to verify these values carefully before running Orabuntu-LXC install !'
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
        CutIndex=7
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
        SubDirName=uekulele
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                CutIndex=7
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                CutIndex=4
        fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        Release=$RedHatVersion
        LF=$LinuxFlavor
        RL=$Release
        SubDirName=uekulele
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
        if [ $RedHatVersion -ge 19 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
        RL=$Release
        SubDirName=uekulele
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
        SubDirName=orabuntu
fi

if [ $LinuxFlavor != 'Ubuntu' ] && [ $LinuxFlavor != 'Fedora' ]
then
        echo ''
        echo "=============================================="
        echo "Configure epel for $LinuxFlavor Linux...      "
        echo "=============================================="
        echo ''

        DocBook2XInstalled=0
        m=1
        while [ $DocBook2XInstalled -eq 0 ] && [ $m -le 5 ]
        do
                if [ $LinuxFlavor != 'Fedora' ]
                then
                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel
                        if   [ $Release -eq 7 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                                sudo rpm -ivh epel-release-latest-7.noarch.rpm
                        elif [ $Release -eq 6 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
                                sudo rpm -ivh epel-release-latest-6.noarch.rpm
                        fi
                        sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
                        sudo yum -y install docbook2X
                fi

                function CheckDocBook2XInstalled {
                        rpm -qa | grep -c docbook2X
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

sshpass -p $HubSudoPwd ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $HubUserAct@$HUBIP "sudo -S <<< "$HubSudoPwd" uname -a;echo '';sudo -S <<< "$HubSudoPwd" lxc-ls -f"
if [ $? -eq 0 ]
then
	echo ''
	echo "=============================================="
	echo "Done: Test sshpass to HUB Host $HUBIP         "
	echo "=============================================="
	echo ''
	sleep 5
	echo ''
        MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:1420:$HubUserAct:$HubSudoPwd:$GRE"
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
