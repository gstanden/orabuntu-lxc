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

SubDirName=$1
Product=$2

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

sudo cp -p GNU3    		/etc/.
sudo cp -p COPYING 		/etc/.

sudo cp -p GNU3    		/var/.
sudo cp -p COPYING 		/var/.

sudo mkdir -p      		"$DistDir"/"$SubDirName"/archives/rootfs
sudo cp -p GNU3    		"$DistDir"/"$SubDirName"/archives/rootfs/.
sudo cp -p COPYING 		"$DistDir"/"$SubDirName"/archives/rootfs/.

sudo cp -p COPYING 		"$DistDir"/"$SubDirName"/.
sudo cp -p COPYING 		"$DistDir"/"$SubDirName"/archives/.

sudo cp -p GNU3    		"$DistDir"/"$SubDirName"/.
sudo cp -p GNU3    		"$DistDir"/"$SubDirName"/archives/.

sudo mkdir -p			/opt/olxc/home/scst-files
sudo mkdir -p			/opt/olxc/home/tgt-files
sudo mkdir -p			/opt/olxc/home/lio-files
sudo chown -R $Owner:$Group 	/opt/olxc/home/scst-files
sudo chown -R $Owner:$Group	/opt/olxc/home/tgt-files
sudo chown -R $Owner:$Group	/opt/olxc/home/lio-files
sudo chown -R $Owner:$Group	/opt/olxc/
sudo cp -p COPYING		/opt/olxc/.
sudo cp -p COPYING		/opt/olxc/home/.
sudo cp -p COPYING		/opt/olxc/home/tgt-files/.
sudo cp -p COPYING		/opt/olxc/home/scst-files/.
sudo cp -p COPYING		/opt/olxc/home/lio-files/.
sudo cp -p GNU3			/opt/olxc/.
sudo cp -p GNU3			/opt/olxc/home/.
sudo cp -p GNU3			/opt/olxc/home/tgt-files/.
sudo cp -p GNU3			/opt/olxc/home/scst-files/.
sudo cp -p GNU3			/opt/olxc/home/lio-files/.

cd "$DistDir"/"$SubDirName"/archives

cp -p "$DistDir"/products/"$Product"/"$Product".tar "$DistDir"/"$SubDirName"/archives/product.tar
cp -p "$DistDir"/products/"$Product"/"$Product".lst "$DistDir"/"$SubDirName"/archives/product.lst
cp -p "$DistDir"/linuxsan/scst/scst-files.tar       "$DistDir"/"$SubDirName"/archives/scst-files.tar
cp -p "$DistDir"/linuxsan/scst/scst-files.lst       "$DistDir"/"$SubDirName"/archives/scst-files.lst
cp -p "$DistDir"/linuxsan/tgt/tgt-files.tar         "$DistDir"/"$SubDirName"/archives/tgt-files.tar
cp -p "$DistDir"/linuxsan/tgt/tgt-files.lst         "$DistDir"/"$SubDirName"/archives/tgt-files.lst
cp -p "$DistDir"/linuxsan/lio/lio-files.tar         "$DistDir"/"$SubDirName"/archives/lio-files.tar
cp -p "$DistDir"/linuxsan/lio/lio-files.lst         "$DistDir"/"$SubDirName"/archives/lio-files.lst

ArchiveList="dns-dhcp-cont.tar dns-dhcp-host.tar lxc-oracle-files.tar product.tar $SubDirName-files.tar scst-files.tar tgt-files.tar lio-files.tar ubuntu-host.tar"

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
	elif [ $i = 'scst-files.tar' ]
	then
		tar -vP --append --file=$i /opt/olxc/home/scst-files/GNU3    --numeric-owner
		tar -vP --append --file=$i /opt/olxc/home/scst-files/COPYING --numeric-owner
	elif [ $i = 'tgt-files.tar' ]
	then
		tar -vP --append --file=$i /opt/olxc/home/tgt-files/GNU3    --numeric-owner
		tar -vP --append --file=$i /opt/olxc/home/tgt-files/COPYING --numeric-owner
	elif [ $i = 'lio-files.tar' ]
	then
		tar -vP --append --file=$i /opt/olxc/home/lio-files/GNU3    --numeric-owner
		tar -vP --append --file=$i /opt/olxc/home/lio-files/COPYING --numeric-owner
	elif [ $i = 'dns-dhcp-cont.tar' ]
	then
		sudo chown root:root /var/GNU3 > /dev/null 2>&1
		sudo chown root:root /var/COPYING > /dev/null 2>&1
		tar -vP --append --file=$i /var/GNU3 --numeric-owner
		tar -vP --append --file=$i /var/COPYING --numeric-owner
	elif [ $i = 'lxc-oracle-files.tar' ] || [ $i = 'product.tar' ]
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
