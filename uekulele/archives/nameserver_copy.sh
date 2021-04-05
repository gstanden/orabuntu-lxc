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

clear

MultiHostVar5=$1
MultiHostVar6=$2
MultiHostVar8=$3
MultiHostVar9=$4
NameServer=$5
Release=$6
LinuxFlavor=$7

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

if [ $Release -ge 7 ]
then
	function CheckLxcNetInstalled {
		systemctl | grep -c lxc-net
	}
	LxcNetInstalled=$(CheckLxcNetInstalled)
elif [ $Release -eq 6 ]
then
	function CheckLxcNetInstalled {
		chkconfig | grep -c lxc-net
	}
	LxcNetInstalled=$(CheckLxcNetInstalled)
fi

echo ''
echo "=============================================="
echo "Copy nameserver $NameServer...                "
echo "=============================================="
echo ''

echo ''
echo "=============================================="
echo "Install rsync ...                             "
echo "=============================================="
echo ''

sudo yum -y install rsync

echo ''
echo "=============================================="
echo "Done: Install rsync.                          "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Nameserver rsync...                           "
echo "=============================================="
echo ''

rsync -XhP --rsh="sshpass -p $MultiHostVar9 ssh -l $MultiHostVar8" $MultiHostVar5:~/Manage-Orabuntu/$NameServer.tar.gz ~/Manage-Orabuntu/.

echo ''
echo "=============================================="
echo "Done: Nameserver rsync...                     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Destroy nameserver $NameServer...             "
echo "=============================================="
echo ''

if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 6 ]
then
        sudo lxc-stop -n $NameServer -k > /dev/null 2>&1
else
        sudo lxc-stop -n $NameServer    > /dev/null 2>&1
fi

sudo lxc-destroy -n $NameServer

echo ''
echo "=============================================="
echo "Unpack tar file...                            "
echo "=============================================="
echo ''

sudo tar -P -xzf ~/Manage-Orabuntu/$NameServer.tar.gz --checkpoint=10000 --totals

echo ''
echo "=============================================="
echo "Done: Copy nameserver container $NameServer.  "
echo "=============================================="
echo ''
echo "=============================================="
echo "LXC containers for Oracle Status...           "
echo "=============================================="

if [ $SystemdResolvedInstalled -ge 1 ]
then
	sudo service systemd-resolved restart
fi

if [ $LxcNetInstalled -ge 1 ]
then
	sudo service lxc-net restart > /dev/null 2>&1
fi

