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
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.  #    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#
#    Controlling script for Orabuntu-LXC

#    Host OS Supported: Oracle Linux 7, RedHat 7, CentOS 7, Fedora 27, Ubuntu 16/17

#    Usage:
#    Passing parameters in from the command line is possible but is not described herein. The supported usage is to configure this file as described below.
#    Capital 'X' means 'not used' do not replace leave as is.

clear

sudo mkdir -p /opt/olxc/installs/logs
if [ ! -d /opt/olxc/installs/logs ]
then
        sudo mkdir -p /opt/olxc/installs/logs
	sudo chown -R $Owner:$Group /opt/olxc
	sudo touch /opt/olxc/installs/logs/$Owner.log
fi

echo ''
echo "=============================================="
echo "anylinux-services.VM.ON.HUB.HOST.1500.sh      "
echo "=============================================="
echo ''

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

if [ -f /opt/olxc/installs/logs/$USER.log ]
then
        sudo mv /opt/olxc/installs/logs/$USER.log /opt/olxc/installs/logs/$USER.log.$LOGEXT
else
	sudo touch /opt/olxc/installs/logs/$USER.log
fi

if [ ! -d /var/log/sudo-io ]
then
        sudo mkdir -m 750 /var/log/sudo-io
fi

if [ ! -f /etc/sudoers.d/orabuntu-lxc ]
then
	sudo sh -c "echo 'Defaults      logfile=\"/opt/olxc/installs/logs/$USER.log\"'	>> /etc/sudoers.d/orabuntu-lxc"
        sudo sh -c "echo 'Defaults      log_input,log_output'                           >> /etc/sudoers.d/orabuntu-lxc"
        sudo sh -c "echo 'Defaults      iolog_dir=/var/log/sudo-io/%{user}'             >> /etc/sudoers.d/orabuntu-lxc"
        sudo chmod 0440 /etc/sudoers.d/orabuntu-lxc
fi

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
elif [ $OpType = 'ovs' ]
then
	Operation=ovs
elif [ $OpType = 'add' ]
then
        Operation=addrelease
fi

if [ -z $2 ]
then
        SPOKEIP=10.209.53.193
else
        SPOKEIP=$2
fi

if [ -z $3 ]
then
        HUBIP=10.209.53.1
else
        HUBIP=$3
fi

if [ -z $4 ]
then
        HubUserAct=ubuntu
else
        HubUserAct=$4
fi

if [ -z $5 ]
then
        HubSudoPwd=ubuntu
else
        HubSudoPwd=$5
fi

if [ -z $6 ]
then
        Product=workspaces
        Product=no-product
        Product=oracle-gi-18c
        Product=oracle-db
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

                	if     [ $Release -eq 8 ]
                	then
                        	wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
                        	sudo rpm -ivh epel-release-latest-8.noarch.rpm

				if [ $LinuxFlavor = 'Oracle' ]
				then
					sudo yum -y install yum-utils
			        	sudo yum-config-manager --enable ol8_codeready_builder
                                	sudo yum-config-manager --enable ol8_appstream
                                	sudo yum-config-manager --enable ol8_u0_baseos_base
                                	sudo yum-config-manager --enable ol8_baseos_latest
                                	sudo yum-config-manager --enable ol8_addons
				fi

                	elif   [ $Release -eq 7 ]
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

			if [ $Operation = 'ovs' ]
			then
				sleep 2
			else
				sleep 5
			fi

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
			
	if [ $Operation = 'ovs' ]
	then
		sleep 2
	else
		sleep 5
	fi
	
	clear

elif [ $LinuxFlavor = 'Ubuntu' ]
then
        echo ''
        echo "=============================================="
        echo 'Install sshpass package...                    '
        echo "=============================================="
        echo ''

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

if [ $Operation != 'ovs' ]
then
	echo ''
	echo "=============================================="
	echo "Test sshpass to HUB Host $HUBIP               "
	echo "=============================================="
	echo ''

	ssh-keygen -R $HUBIP > /dev/null 2>&1
	sshpass -p $HubSudoPwd ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $HubUserAct@$HUBIP "sudo -S <<< "$HubSudoPwd" uname -a;echo '';sudo -S <<< "$HubSudoPwd" lxc-ls -f | tail -10"
	if   [ $? -eq 0 ]
	then
		echo ''
		echo "=============================================="
		echo "Done: Test sshpass to HUB Host $HUBIP         "
		echo "=============================================="
		echo ''
		sleep 5
		echo ''

		if [ $AWS -eq 1 ]
		then
       		 	if   [ $AwsMtu -ge 9000 ]
       		 	then
       		         	# Until support for jumbo frames is ready set 1500.
       		         	sudo ifconfig eth0 mtu 1500
       		         	AwsMtu=1500
       		         	MultiHost="$Operation:Y:X:X:$HUBIP:X:$AwsMtu:$HubUserAct:$HubSudoPwd:$GRE:$Product"

       		 	elif [ $AwsMtu -eq 1500 ]
       		 	then
       		         	MultiHost="$Operation:Y:X:X:$HUBIP:X:$AwsMtu:$HubUserAct:$HubSudoPwd:$GRE:$Product"
       		 	fi
		else
       		 	MultiHost="$Operation:Y:X:X:$HUBIP:X:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product"
		fi

		cd "$DistDir"/anylinux

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
elif [ $Operation = 'ovs' ]
then
	sudo tar -vP --extract --file="$DistDir"/uekulele/archives/ubuntu-host.tar /etc/orabuntu-lxc-scripts/stop_containers.sh > /dev/null 2>&1
	sudo chmod 755                                                             /etc/orabuntu-lxc-scripts/stop_containers.sh
	                                                                           /etc/orabuntu-lxc-scripts/stop_containers.sh
	cd "$DistDir"/anylinux  
	sudo chown -R $Owner:$Group /opt/olxc

        sleep 2

        clear

        # sudo yum -y remove openvswitch*

	MultiHost="$Operation:Y:X:X:$HUBIP:X:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product"
	./anylinux-services.sh $MultiHost
fi

exit
