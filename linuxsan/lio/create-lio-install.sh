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

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

clear

SUDO_PREFIX=$1

echo ''
echo "======================================================="
echo "Check if kernel version meets minimum requirement...   "
echo "======================================================="
echo ''

# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.
# GLS 20160924 SCST 3.1 does not require a custom kernel build for kernels >= 2.6.30 so now we check that kernel is >= 2.6.30.
# GLS 20160924 If the kernel version is lower than 2.6.30 it will be necessary for you to compile a custom kernel.
# GLS 20161119 All installs will be done by "ubuntu" user with "sudo" for all distros.

function VersionKernelPassFail () {
    ./vercomp | cut -f1 -d':'
}
KernelPassFail=$(VersionKernelPassFail)
echo $KernelPassFail

echo ''
echo "======================================================="
echo "Kernel version meets minimum requirement.              "
echo "======================================================="
echo ''

sleep 5

clear

echo ''
echo "======================================================="
echo "Install LIO iSCST target...                            "
echo "======================================================="
echo ''

sudo yum -y install targetcli
sudo systemctl start target
sudo systemctl enable target

echo ''
echo "======================================================="
echo "Done: Install LIO iSCST target.                        "
echo "======================================================="
echo ''

sleep 5

clear
