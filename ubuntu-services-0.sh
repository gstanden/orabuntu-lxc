#    Copyright 2015-2017 Gilbert Standen
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
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container

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
echo 'facter lxc uml-utilities openvswitch-switch openvswitch-common apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop flashplugin-installer sshpass db5.1-util'
}
fi

if [ $UbuntuVersion = '16.04' ]
then
function CheckPackageInstalled {
echo 'facter lxc uml-utilities openvswitch-switch openvswitch-common apparmor-utils openssh-server uuid rpm yum hugepages ntp iotop flashplugin-installer sshpass db5.3-util'
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

sleep 2

clear

echo ''
echo "============================================"
echo "Next script to run: ubuntu-services-1.sh    "
echo "============================================"

sleep 5

