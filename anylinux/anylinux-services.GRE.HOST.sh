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

GRE=Y 
	
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

SPOKEIP=192.168.7.27

HUBIP=192.168.7.32
HubUserAct=orabuntu
HubSudoPwd=balihigh

if [ $SPOKEIP = 'lan.ip.this.host' ] || [ $HUBIP = 'lan.ip.hub.host' ] || [ $HubUserAct = 'username' ] || [ $HubSudoPwd = 'password' ]
then
	echo 'You must edit this file first and set the SPOKEIIP, HUBIP, HubUserAct, and the HubSudoPwd'
	echo 'After setting these in this file re-run the script'
	echo 'Also ... be SURE to verify these values carefully before running Orabuntu-LXC install !'
	exit
fi

echo ''
sshpass -p $HubSudoPwd ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $HubUserAct@$HUBIP "sudo -S <<< "$HubSudoPwd" uname -a;echo '';sudo -S <<< "$HubSudoPwd" lxc-ls -f"
if [ $? -eq 0 ]
then
        MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:1420:$HubUserAct:$HubSudoPwd:$GRE"
        ./anylinux-services.sh $MultiHost
else
        echo "The sshpass to the Orabuntu-LXC HUB host at $HUBIP failed. Recheck settings in this file and re-run."
        exit
fi
