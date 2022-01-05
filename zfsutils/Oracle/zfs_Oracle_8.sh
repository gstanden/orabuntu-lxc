#!/bin/bash

clear

echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
echo "                                              "
echo "(some steps take awhile ... patience)         " 
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Build ZFS from source ...                     "
echo "=============================================="
echo ''

sudo yum -y update
sudo yum -y install net-tools wget unzip tar
sudo yum -y install oracle-epel-release-el8
# sudo yum-config-manager --enable ol8_optional_latest
sudo yum -y update
sudo yum -y install perl bc cpio git gcc make autoconf automake libtool rpm-build libtirpc-devel libblkid-devel libuuid-devel libudev-devel openssl-devel zlib-devel libaio-devel libattr-devel elfutils-libelf-devel kernel-uek-devel-$(uname -r) python3 python3-devel python3-setuptools python3-cffi libffi-devel git ncompress libcurl-devel python3-packaging dkms sysstat mdadm ksh fio kernel-devel
sleep 10
git clone https://github.com/openzfs/zfs
cd zfs
sh autogen.sh
./configure
make rpm -j4
sleep 5
sudo rpm -ivh *.rpm

n=1
function CheckZfsInstalled {
	sudo rpm -qa | grep -c zfs
}
ZfsInstalled=$(CheckZfsInstalled)

if [ -z $ZfsInstalled ]
then
	ZfsInstalled=1
fi

while [ $ZfsInstalled -lt 8 ] && [ $n -le 5 ]
do
	echo 'Re-run make ...'
	echo ''
	make rpm -j4
	sleep 5
	sudo rpm -ivh *.rpm
	sleep 5
	ZfsInstalled=$(CheckZfsInstalled)
	n=$((n+1))
	echo ''
done

echo 'ZFS is installed.'

sudo modprobe zfs
sudo zpool list

echo ''
echo "=============================================="
echo "Done: Install packages.                       "
echo "=============================================="
echo ''
