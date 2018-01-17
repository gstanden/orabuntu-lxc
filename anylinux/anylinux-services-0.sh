clear

ArchiveList="dns-dhcp-cont.tar dns-dhcp-host.tar lxc-oracle-files.tar orabuntu-services.tar scst-files.tar tgt-files.tar ubuntu-host.tar"

function GetDistDir {
	pwd | rev | cut -f2-20 -d'/' | rev
}
DistDir=$(GetDistDir)

sudo cp -p GNU3    /etc/.
sudo cp -p COPYING /etc/.

sudo cp -p GNU3    /var/.
sudo cp -p COPYING /var/.

sudo mkdir -p      "$DistDir"/orabuntu/archives/rootfs/.
sudo cp -p GNU3    "$DistDir"/orabuntu/archives/rootfs/.
sudo cp -p COPYING "$DistDir"/orabuntu/archives/rootfs/.

sudo cp -p COPYING "$DistDir"/orabuntu/.
sudo cp -p COPYING "$DistDir"/orabuntu/archives/.

sudo cp -p GNU3    "$DistDir"/orabuntu/.
sudo cp -p GNU3    "$DistDir"/orabuntu/archives/.

cd "$DistDir"/orabuntu/archives

for i in $ArchiveList
do
	clear

	echo ''
	echo '############################################'
	echo "Archive $i                                  "
	echo '############################################'
	echo ''
	tar -tvPf $i | grep GNU3
	if [ $? -eq 0 ]
	then
		tar -vP --delete --file=$i GNU3 > /dev/null 2>&1
		tar -vP --delete --file=$i /var/GNU3 > /dev/null 2>&1
		tar -vP --delete --file=$i /etc/GNU3 > /dev/null 2>&1
		tar -vP --delete --file=$i rootfs/GNU3 > /dev/null 2>&1
		tar -vP --delete --file=$i "$DistDir"/orabuntu/archives/GNU3 > /dev/null 2>&1
	fi

	tar -tvPf $i | grep COPYING
	if [ $? -eq 0 ]
	then
		tar -vP --delete --file=$i COPYING > /dev/null 2>&1
		tar -vP --delete --file=$i /var/COPYING > /dev/null 2>&1
		tar -vP --delete --file=$i /etc/COPYING > /dev/null 2>&1
		tar -vP --delete --file=$i rootfs/COPYING > /dev/null 2>&1
		tar -vP --delete --file=$i "$DistDir"/orabuntu/archives/COPYING > /dev/null 2>&1
	fi

	if   [ $i = 'dns-dhcp-host.tar' ] || [ $i = 'ubuntu-host.tar' ]
	then
		sudo chown root:root /etc/GNU3
		sudo chown root:root /etc/COPYING
		tar -vP --append --file=$i /etc/GNU3
		tar -vP --append --file=$i /etc/COPYING
	elif [ $i = 'dns-dhcp-cont.tar' ]
	then
		sudo chown root:root /var/GNU3
		sudo chown root:root /var/COPYING
		tar -vP --append --file=$i /var/GNU3 --numeric-owner
		tar -vP --append --file=$i /var/COPYING --numeric-owner
	elif [ $i = 'lxc-oracle-files.tar' ]
	then
		sudo chown root:root rootfs/GNU3
		sudo chown root:root rootfs/COPYING
		sudo tar -vP --append --file=$i rootfs/GNU3
		sudo tar -vP --append --file=$i rootfs/COPYING
	else
		tar -vP --append --file=$i "$DistDir"/orabuntu/archives/GNU3
		tar -vP --append --file=$i "$DistDir"/orabuntu/archives/COPYING
	fi

	echo ''
	echo '***********************************************'
	tar -tvPf $i 
	echo '***********************************************'
	echo ''

	sleep 2
done

sudo rm -rf "$DistDir"/orabuntu/archives/rootfs
