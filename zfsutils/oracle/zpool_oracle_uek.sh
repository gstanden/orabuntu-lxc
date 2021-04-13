echo ''
echo "=============================================="
echo "Configure ZFS Storage ...                     "
echo "=============================================="
echo ''

GRE=$(source /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux/CONFIG; echo $GRE)
GRE=Y

sudo yum -y install kernel-uek-devel-$(uname -r) kernel-devel yum-utils
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo yum config-manager --enable epel
sudo yum repolist
sudo yum -y install dkms
sudo rpm -Uvh http://download.zfsonlinux.org/epel/zfs-release.el8_3.noarch.rpm
sudo yum -y install -y zfs
sudo modprobe zfs
sudo systemctl list-unit-files | grep zfs

if   [ $GRE = 'N' ]
then
        sudo zpool create olxc-001 mirror /dev/sdb /dev/sdc

elif [ $GRE = 'Y' ]
then
        sudo zpool create olxc-002 mirror /dev/sdb /dev/sdc
fi

sudo zpool list
sudo zpool status

echo ''
echo "=============================================="
echo "Done: Configure ZFS Storage.                  "
echo "=============================================="
echo ''
