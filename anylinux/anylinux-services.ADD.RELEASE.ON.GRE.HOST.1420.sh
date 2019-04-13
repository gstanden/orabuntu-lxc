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
echo "Script: ADD.RELEASE.ON.GRE.HOST.1420.sh       "
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
MTU=1420
LOGEXT=`date +"%Y-%m-%d.%R:%S"`

Operation=addrelease
OpType=add

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
        read -e -p "Install Type [new/rei/add]:             " -i "new" OpType
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
        Product=no-product
        Product=workspaces
        Product=oracle-db
	Product=oracle-gi-18c
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

if [ $AWS -eq 1 ]
then
	if   [ $AwsMtu -ge 9000 ]
	then
		# Until support for jumbo frames ready set 1500.
		sudo ifconfig eth0 mtu 1500
		AwsMtu=1500
#		MultiHost="$Operation:Y:X:X:X:X:8920:X:X:$GRE"
		MultiHost="$Operation:Y:X:X:X:X:1420:X:X:$GRE"

	elif [ $AwsMtu -eq 1500 ]
	then
		MultiHost="$Operation:Y:X:X:X:X:1420:X:X:$GRE"
	fi
else
	MultiHost="$Operation:Y:X:X:X:X:$MTU:X:X:$GRE"
fi

./anylinux-services.sh $MultiHost

exit

