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
#    v7.0-AMIDE-beta    GLS 20210428 Orabuntu-LXC AmazonS3 Multi-Host LXD Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#    See CONFIG file for user-settable configuration variables.

clear

echo ''
echo "=============================================="
echo "Script: anylinux-services.ADD.CLONES.sh       "
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

LOGEXT=`date +"%Y-%m-%d.%R:%S"`

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

GRE=N

MultiHost="addclones:X:X:X:X:X:X:X:X:$GRE"

./anylinux-services.sh $MultiHost | tee "$DistDir/installs/logs/orabuntu-lxc.install.$(date +%F_%R).log"

exit

