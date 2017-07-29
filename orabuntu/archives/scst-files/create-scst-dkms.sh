#!/bin/bash
# Builds and installs SCST DKMS modules
# Gilbert Standen 2017-07-29
clear
sudo apt-get -y install subversion dkms quilt debhelper
svn checkout svn://svn.code.sf.net/p/scst/svn/trunk scst-latest
mv scst-latest scst-3.3.0
wget https://github.com/gstanden/scst-3.x-debian/archive/master.zip
unzip master.zip
mv scst-3.x-debian-master scst-3.3.0/debian
sudo rm -rf /usr/src/scst-3.3.0/
sudo rm -rf /var/lib/dkms/scst/3.3.0/dsc/
sudo mkdir -p /usr/src/scst-3.3.0/
sudo mkdir -p /var/lib/dkms/scst/3.3.0/dsc/
cp scst-3.3.0/debian/dkms.conf scst-3.3.0/debian/dkms.conf.in
sudo cp scst-3.3.0/debian/dkms.conf /usr/src/scst-3.3.0/dkms.conf
sudo cp scst-3.3.0/debian/dkms.conf /usr/src/scst-3.3.0/dkms.conf.in
sudo cat /usr/src/scst-3.3.0/dkms.conf
sudo dkms add -m scst -v 3.3.0
cd ~/Downloads/scst-3.3.0/
sudo cp -a . /usr/src/scst-3.3.0/.
sudo dkms mkdsc -m scst -v 3.3.0 --source-only
sudo tar -xzf /var/lib/dkms/scst/3.3.0/dsc/scst-dkms_3.3.0.tar.gz -C /usr/src/scst-3.3.0
sudo mv /usr/src/scst-3.3.0/scst-dkms-3.3.0 /usr/src/scst-3.3.0/scst-dkms-mkdsc
cd /usr/src/scst-3.3.0/
sudo fakeroot debian/rules clean
sudo fakeroot debian/rules binary
cd ..
ls -lrt *.deb
ScstRelease=3.3.0
echo $ScstRelease
sudo dkms remove scst/3.3.0 --all
sudo rm -rf /var/lib/dkms/scst
echo ''
echo "============================================================"
echo "Building initial module for `uname -r` can take awhile      "
echo "depending on the processing power of your system.           "
echo "Be patient...                                               "
echo "============================================================"
echo ''
sudo dpkg -D2 -i /usr/src/scst-dkms_"$ScstRelease"_amd64.deb
sudo dpkg -D2 -i /usr/src/iscsi-scst_"$ScstRelease"_amd64.deb
sudo dpkg -D2 -i /usr/src/scstadmin_"$ScstRelease"_amd64.deb
sudo dpkg -D2 -i /usr/src/scst-fileio-tgt_"$ScstRelease"_amd64.deb
sudo modprobe scst
sudo depmod
sudo modprobe iscsi-scst
if ! pgrep iscsi-scstd; then sudo iscsi-scstd; fi > /dev/null
sudo modprobe scst_vdisk
sudo modprobe scst_disk
sudo modprobe scst_user
sudo modprobe scst_modisk
sudo modprobe scst_processor
sudo modprobe scst_raid
sudo modprobe scst_tape
sudo modprobe scst_cdrom
sudo modprobe scst_changer
sudo modprobe iscsi-scst
sudo systemctl enable scst.service
sudo modprobe iscsi-scst
sudo systemctl enable scst.service
sudo service scst start
sudo scstadmin -write_config /etc/scst.conf
grep iscsi_scst /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'iscsi-scst'									>> /etc/modules"
fi
grep scst_vdisk /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_vdisk'									>> /etc/modules"
fi
grep scst_disk /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_disk'									>> /etc/modules"
fi
grep scst_user /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_user'									>> /etc/modules"
fi
grep scst_moddisk /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_modisk'									>> /etc/modules"
fi
grep scst_processor /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_processor'								>> /etc/modules"
fi
grep scst_raid /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_raid'									>> /etc/modules"
fi
grep scst_tape /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_tape'									>> /etc/modules"
fi
grep scst_cdrom /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_cdrom'									>> /etc/modules"
fi
grep scst_changer /etc/modules
if [ $? -ne 0 ]
then
sudo sh -c "echo 'scst_changer'									>> /etc/modules"
fi
sudo sh -c "echo '[Unit]'									>  /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'Description=SCST SAN Service'							>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'After=scst.service'								>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo ''										>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo '[Service]'									>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'Type=oneshot'									>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'ExecStart=/usr/bin/sudo /usr/sbin/iscsi-scstd'				>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'ExecStart=/usr/bin/sudo /usr/sbin/scstadmin -config /etc/scst.conf'		>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'RemainAfterExit=true'								>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'ExecStop=/usr/bin/sudo /bin/kill -9 /usr/sbin/iscsi-scstd'			>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'StandardOutput=journal'							>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo ''										>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo '[Install]'									>> /etc/systemd/system/scst-san.service"
sudo sh -c "echo 'WantedBy=multi-user.target'							>> /etc/systemd/system/scst-san.service"
sudo chmod 644 /etc/systemd/system/scst-san.service
sudo systemctl enable scst-san.service
echo ''
echo "=============================================="
echo "Run a few checks on SCST now...               "
echo "=============================================="
echo ''
ps -ef | grep scst
echo ''
lsmod | grep scst
echo ''
cat /etc/modules
echo ''
sudo service scst status
echo ''
echo "To use the scst-files.tar archive now to build an SCST Linux SAN run the following commands from the same directory as create-scst-dkms.sh"
echo "If you just finished the install of SCST DKMS for Debian-based systemd-enabled Linuxes, then run these commands from the current directory."
echo ''
echo "=============================================="
echo "tar -xvf ./scst-3.3.0/debian/scst-files.tar   "
echo "cd scst-files                                 "
echo "./create-scst.sh                              "
echo "=============================================="
echo ''
echo "The scst-files.tar will build the target, create LUNs, create the multipath.conf, and create required UDEV rules, all AUTOMATICALLY."
echo "The default SAN is customized for Oracle RAC."
echo "Edit create-scst-oracle.sh file to customize the SAN as required for other non-Oracle datbases and requirement as needed."
echo ''
