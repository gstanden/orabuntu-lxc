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

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

function CheckLxcNetInstalled {
	systemctl | grep -c lxc-net
}
LxcNetInstalled=$(CheckLxcNetInstalled)

echo ''
echo "=============================================="
echo "Copy nameserver $NameServer...                "
echo "=============================================="
echo ''

# rsync -hP --rsh="sshpass -p $MultiHostVar9 ssh -l $MultiHostVar8" $MultiHostVar5:~/Manage-Orabuntu/$NameServer.tar.gz ~/Manage-Orabuntu/.
rsync -hP --rsh="sshpass -p $MultiHostVar9 ssh -l $MultiHostVar8" $MultiHostVar5:~/Manage-Orabuntu/"$NameServer".export."$HOSTNAME".tar.gz ~/Manage-Orabuntu/.

echo ''
echo "=============================================="
echo "Destroy nameserver $NameServer if it exists..."
echo "=============================================="
echo ''

sudo lxc-info -n $NameServer > /dev/null 2>&1
if [ $? -eq 1 ]
then
	sudo lxc-info -n $NameServer
else
	sudo lxc-stop    -n $NameServer > /dev/null 2>&1
	sudo lxc-destroy -n $NameServer > /dev/null 2>&1
fi

echo ''
echo "=============================================="
echo "Unpack tar file...                            "
echo "=============================================="
echo ''

# sudo tar -P -xzf ~/Manage-Orabuntu/$NameServer.tar.gz --checkpoint=10000 --totals
sudo tar -P -xzf ~/Manage-Orabuntu/"$NameServer".export."$HOSTNAME".tar.gz --checkpoint=10000 --totals

echo ''
echo "=============================================="
echo "Done: Copy nameserver container $NameServer.  "
echo "=============================================="
echo ''
echo "=============================================="
echo "LXC containers for Oracle Status...           "
echo "=============================================="
echo ''

if [ $SystemdResolvedInstalled -ge 1 ]
then
	sudo service systemd-resolved restart
fi

if [ $LxcNetInstalled -ge 1 ]
then
	sudo service lxc-net restart > /dev/null 2>&1
fi

