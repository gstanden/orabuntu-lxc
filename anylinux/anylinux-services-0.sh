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

clear

SubDirName=$1

ArchiveList="dns-dhcp-cont.tar dns-dhcp-host.tar lxc-oracle-files.tar $SubDirName-files.tar scst-files.tar tgt-files.tar ubuntu-host.tar"

function GetDistDir {
	pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

sudo cp -p GNU3    /etc/.
sudo cp -p COPYING /etc/.

sudo cp -p GNU3    /var/.
sudo cp -p COPYING /var/.

sudo mkdir -p      "$DistDir"/"$SubDirName"/archives/rootfs/.
sudo cp -p GNU3    "$DistDir"/"$SubDirName"/archives/rootfs/.
sudo cp -p COPYING "$DistDir"/"$SubDirName"/archives/rootfs/.

sudo cp -p COPYING "$DistDir"/"$SubDirName"/.
sudo cp -p COPYING "$DistDir"/"$SubDirName"/archives/.

sudo cp -p GNU3    "$DistDir"/"$SubDirName"/.
sudo cp -p GNU3    "$DistDir"/"$SubDirName"/archives/.

cd "$DistDir"/"$SubDirName"/archives

for i in $ArchiveList
do
	function GetStripFiles {
		tar -P -tvf $i | egrep 'GNU3|COPYING' | sed 's/  */ /g' | cut -f6 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	StripFiles=$(GetStripFiles)
	echo $StripFiles

	clear

	echo ''
	echo '############################################'
	echo "Archive $i                                  "
	echo '############################################'
	echo ''

	for j in $StripFiles
	do
		tar -vP --delete --file=$i $j
	done

	if   [ $i = 'dns-dhcp-host.tar' ] || [ $i = 'ubuntu-host.tar' ]
	then
		sudo chown root:root /etc/GNU3 > /dev/null 2>&1
		sudo chown root:root /etc/COPYING > /dev/null 2>&1
		tar -vP --append --file=$i /etc/GNU3
		tar -vP --append --file=$i /etc/COPYING
	elif [ $i = 'scst-files.tar' ] || [ $i = 'tgt-files.tar' ]
	then
		tar -vP --append --file=$i "$DistDir"/"$SubDirName"/archives/GNU3 	--numeric-owner
		tar -vP --append --file=$i "$DistDir"/"$SubDirName"/archives/COPYING 	--numeric-owner
	elif [ $i = 'dns-dhcp-cont.tar' ]
	then
		sudo chown root:root /var/GNU3 > /dev/null 2>&1
		sudo chown root:root /var/COPYING > /dev/null 2>&1
		tar -vP --append --file=$i /var/GNU3 --numeric-owner
		tar -vP --append --file=$i /var/COPYING --numeric-owner
	elif [ $i = 'lxc-oracle-files.tar' ]
	then
		sudo chown root:root rootfs/GNU3 > /dev/null 2>&1
		sudo chown root:root rootfs/COPYING > /dev/null 2>&1
		sudo tar -vP --append --file=$i rootfs/GNU3
		sudo tar -vP --append --file=$i rootfs/COPYING
	elif [ $i = "$SubDirName-services.tar" ]
	then
		tar -vP --append --file=$i "$DistDir"/"$SubDirName"/archives/GNU3	--numeric-owner
		tar -vP --append --file=$i "$DistDir"/"$SubDirName"/archives/COPYING	--numeric-owner
	else
		tar -vP --append --file=$i "$DistDir"/"$SubDirName"/archives/GNU3
		tar -vP --append --file=$i "$DistDir"/"$SubDirName"/archives/COPYING
	fi

	echo ''
	echo '***********************************************'
	tar -tvPf $i 
	echo '***********************************************'
	echo ''

	sleep 2
done

sudo rm -rf "$DistDir"/"$SubDirName"/archives/rootfs
