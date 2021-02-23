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

################ MultiHost Settings ########################

            GRE=Y 
            MTU=1420
         LOGEXT=`date +"%Y-%m-%d.%R:%S"`

################# Kubernetes Settings ######################

           K8S=N		# Change to Y with Ubuntu Linux only.

################### Docker Settings ########################

           Docker=N

################ LXD Cluster Settings ######################

### Ubuntu Linux LXD Storage (optional)

StoragePoolName=olxc-002        # Relevant only if LXDCluster=Y
StorageDriver=zfs               # Relevant only if LXDCluster=Y

### Oracle Linux LXD Storage (optional)

BtrfsLun="\/dev\/sdXn"          # Relevant only if LXDCluster=Y (e.g. Set to /dev/sdb1)
LXD=N                           # This value is currently unused.  Leave set to N.

LXDCluster=N                    # Default value
PreSeed=N                       # Default value

if   [ $LinuxFlavor = 'Ubuntu' ] && [ $UbuntuMajorVersion -ge 20 ]
then
        echo ''
        echo "=============================================="
        echo "Display Optional LXD Cluster Values...        "
        echo "=============================================="
        echo ''

        LXDCluster=N    # Set to Y for automated LXD Cluster creation (optional).
        PreSeed=N       # Set to Y for automated LXD Cluster creation (optional).

        echo 'LXDCluster = '$LXDCluster
        echo 'PreSeed    = '$PreSeed

        echo ''
        echo "=============================================="
        echo "Done: Display LXD Cluster Values.             "
        echo "=============================================="
        echo ''

        sleep 5

        clear

        if [ $LXDCluster = 'Y' ]
        then
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
        fi
fi

if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 8 ]
then
        LXDCluster=N
        PreSeed=N

        if [ $LXDCluster = 'Y' ]
        then
                echo ''
                echo "=============================================="
                echo "                WARNING !!                    "
                echo "=============================================="
                echo ''
                echo "=============================================="
                echo "LXD Cluster will RE-FORMAT $BtrfsLun as a     "
                echo "BTRFS file system for LXD.                    "
                echo "                                              "
                echo "If you do NOT want to use /dev/sdXn for this  "
                echo "purpose, hit CTRL+c now to exit.              "
                echo "=============================================="
                echo ''

                sleep 20
        fi
fi

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
	SPOKEIP='lan.ip.this.host'
 	SPOKEIP=192.168.1.136
else
	SPOKEIP=$2
fi

if [ -z $3 ]
then
	HUBIP='lan.ip.hub.host'
 	HUBIP=192.168.1.121
else
	HUBIP=$3
fi

if [ -z $4 ]
then
	HubUserAct=username
 	HubUserAct=ubuntu
else
	HubUserAct=$4
fi

if [ -z $5 ]
then
	HubSudoPwd=password
 	HubSudoPwd=ubuntu
else
	HubSudoPwd=$5
fi

if [ -z $6 ]
then
 	Product=workspaces
 	Product=oracle-db
	Product=oracle-gi-18c
        Product=no-product
else
	Product=$6
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
                function GetRedHatVersion {
                        sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
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
        			echo "Install epel...                               "
        			echo "=============================================="
        			echo ''

                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                                sudo rpm -ivh epel-release-latest-7.noarch.rpm
				
				echo ''
        			echo "=============================================="
        			echo "Done: Install epel.                           "
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

				sudo yum -y install oracle-epel-release-el8
				sudo yum -y install yum-utils
				sudo yum-config-manager --enable ol8_codeready_builder
				sudo yum-config-manager --enable ol8_addons
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
		MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product:$LXD:$K8S:$PreSeed:$LXDCluster:$StorageDriver:$StoragePoolName:$BtrfsLun:$Docker"
	else
		MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product:$LXD:$K8S:$PreSeed:$LXDCluster:$StorageDriver:$StoragePoolName:$BtrfsLun:$Docker"
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
