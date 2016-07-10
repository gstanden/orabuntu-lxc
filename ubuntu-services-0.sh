#    Copyright 2015-2016 Gilbert Standen
#    This file is part of orabuntu-lxc.

#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.

#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04

#!/bin/bash

export DATEXT=`date +"%Y%m%d%H%M"`

echo ''
echo "============================================"
echo "Check required packages status...           "
echo "============================================"
echo ''

function GetUbuntuVersion {
cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
}
UbuntuVersion=$(GetUbuntuVersion)

if [ $UbuntuVersion = '15.10' ] || [ $UbuntuVersion = '15.04' ]
then
function CheckPackageInstalled {
echo 'lxc uml-utilities openvswitch-switch openvswitch-common bind9 bind9utils isc-dhcp-server apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop flashplugin-installer sshpass db5.1-util'
}
fi

if [ $UbuntuVersion = '16.04' ]
then
function CheckPackageInstalled {
echo 'lxc uml-utilities openvswitch-switch openvswitch-common bind9 bind9utils isc-dhcp-server apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop flashplugin-installer sshpass db5.3-util'
}
fi

PackageInstalled=$(CheckPackageInstalled)

for i in $PackageInstalled
do
sudo dpkg -l $i | cut -f3 -d' ' | tail -1 | sed 's/^/Installed:/'
done

echo '' 
echo "============================================"
echo "Check required packages status completed.   "
echo "============================================"
echo ''

sleep 10

clear

echo ''
echo "============================================"
echo "Check existing files status...              "
echo "initiatorname.iscsi may not be found on run1"
echo "rndc.key may not be found on run1           "
echo "named.conf.options may not be found on run1 "
echo "============================================"
echo ''

if [ -e backup-copies.txt ]
then
rm backup-copies.txt
fi

function CheckFilesExist {
echo "/etc/iscsi/initiatorname.iscsi /etc/bind/rndc.key /etc/bind/named.conf.options /etc/apparmor.d/lxc/lxc-default /etc/sysctl.conf /etc/security/limits.conf /etc/network/if-down.d/scst-net /etc/default/bind9 /etc/network/openvswitch/del-bridges.sh /etc/default/isc-dhcp-server /etc/NetworkManager/dnsmasq.d/local /etc/bind/named.conf.local /etc/dhcp/dhcpd.conf /etc/dhcp/dhclient.conf /run/resolvconf/resolv.conf /etc/multipath.conf /etc/multipath.conf.example /etc/init/openvswitch-switch.conf /etc/default/openvswitch-switch" 
}

FilesExist=$(CheckFilesExist)

for i in $FilesExist
do
if [ -e $i ]
then
sudo ls $i
sudo cp -p $i $i.original.bak.$DATEXT
sudo ls $i.original.bak.$DATEXT
sudo ls $i.original.bak.$DATEXT >> backup-copies.txt
echo ''
fi
done

echo "This script evaluated your system for orabuntu-lxc installation."
echo "This script identified files that will be overwritten by orabuntu-lxc installation."
echo "This script backed up any existing configuration files that will be overwritten by orabuntu-lxc installation."
echo ''
echo "WARNING:"
echo ''
echo '!!! REVIEW the output of this script and evaluate any existing configuration file conflicts before installing orabuntu-lxc !!!'
echo ''
echo 'Files that will be affected can be reviewed in ~/Downloads/orabuntu-lxc-master/backup-copies.txt file.'
echo ''
echo 'You can <ctrl>+c at this point to review the files that will be affected if you want and then re-run orabuntu-lxc when ready.'
echo ''
echo "============================================"
echo "Check existing files status complete.       "
echo "============================================"
echo ''

sleep 25

clear

echo ''
echo "============================================"
echo "Next script to run: ubuntu-services-1.sh    "
echo "============================================"

sleep 5
