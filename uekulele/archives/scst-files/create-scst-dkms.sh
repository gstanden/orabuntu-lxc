#!/bin/bash

#    Copyright 2015-2017 Gilbert Standen
#    This file is part of orabuntu-lxc: https://github.com/gstanden/orabuntu-lxc
#
#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.
#
#    v2.8 GLS 20151231
#    v3.0 GLS 20160710
#    v3.1 GLS 20160925
#    v4.0 GLS 20170906
#
#   !! SEE THE README FILE FOR COMPLETE INSTRUCTIONS FIRST BEFORE RUNNING !!
#
#   sudo ALL privilege is required 	prior to running!
#   internet connectivity is required 	prior to running!
#
#   Builds and installs SCST DKMS modules
#   Gilbert Standen 2017-07-29

clear

echo ''
echo "============================================================"
echo "Install additional packages required for DKMS build...      "
echo "============================================================"
echo '' 

sudo apt-get -y install subversion dkms quilt debhelper

echo ''
echo "============================================================"
echo "Completed: Install DKMS additional packages.                "
echo "============================================================"
echo ''

sleep 2

echo ''
echo "============================================================"
echo "Get SCST source code from SVN...                            "
echo "============================================================"
echo '' 

sleep 2

svn checkout svn://svn.code.sf.net/p/scst/svn/trunk scst-latest

echo ''
echo "============================================================"
echo "Completed:  Get SCST source code from SVN.                  "
echo "============================================================"
echo ''

sleep 2

echo ''
echo "============================================================"
echo "Dynamic Discovery SCST Version and Rename Directory...      "
echo "============================================================"
echo '' 

function GetVersionString {
	cat scst-latest/usr/include/version.h | grep VERSION_STR | cut -f2 -d'"' | cut -f1 -d'-'
}
VersionString=$(GetVersionString)
echo "SCST Version:  $VersionString"

mv scst-latest scst-"$VersionString"

echo ''
echo "============================================================"
echo "Completed:  Dynamic Discovery SCST Version and Rename Dir.  "
echo "============================================================"
echo ''

sleep 2

echo ''
echo "============================================================"
echo "Download Github scst-3.x-debian (gstanden fork)...          "
echo "============================================================"
echo '' 

sleep 2

wget https://github.com/gstanden/scst-3.x-debian/archive/master.zip
unzip master.zip
mv scst-3.x-debian-master scst-"$VersionString"/debian
sudo sed -i "/DKMSMODVER=3.3.0/c\DKMSMODVER=$VersionString" scst-"$VersionString"/debian/rules
sudo sed -i "/3.3.0/s/3.3.0/$VersionString/g"               scst-"$VersionString"/debian/changelog

echo ''
echo "============================================================"
echo "Completed: Download Github scst-3.x-debian (gstanden fork). "
echo "============================================================"
echo ''

sleep 2

echo ''
echo "============================================================"
echo "Prepare Directories...                                      "
echo "============================================================"
echo '' 

sudo rm -rf /usr/src/scst-"$VersionString"/
sudo rm -rf /var/lib/dkms/scst/"$VersionString"/dsc/
sudo mkdir -p /usr/src/scst-"$VersionString"/
ls -l /usr/src/scst-"$VersionString"
sudo mkdir -p /var/lib/dkms/scst/"$VersionString"/dsc/
ls -l /var/lib/dkms/scst/"$VersionString"/dsc
cp scst-"$VersionString"/debian/dkms.conf scst-"$VersionString"/debian/dkms.conf.in
sudo cp scst-"$VersionString"/debian/dkms.conf /usr/src/scst-"$VersionString"/dkms.conf
sudo cp scst-"$VersionString"/debian/dkms.conf /usr/src/scst-"$VersionString"/dkms.conf.in
ls -l /usr/src/scst-"$VersionString"/dkms*

echo ''
echo "============================================================"
echo "Completed: Prepare Directories.                             "
echo "============================================================"
echo ''

sleep 2

echo ''
echo "============================================================"
echo "Display /usr/src/scst-"$VersionString"/dkms.conf file...    "
echo "============================================================"
echo '' 

sleep 2

sudo cat /usr/src/scst-"$VersionString"/dkms.conf

echo ''
echo "============================================================"
echo "Completed:  Display dkms.conf file.                         "
echo "============================================================"

sleep 2

echo ''
echo "============================================================"
echo "Register SCST to DKMS                                       "
echo "============================================================"
echo '' 

sleep 2

sudo dkms add -m scst -v "$VersionString"

echo ''
echo "============================================================"
echo "Completed: Register SCST to DKMS                            "
echo "============================================================"

sleep 2

echo ''
echo "============================================================"
echo "Run: sudo dkms mkdsc -m scst -v "$VersionString" --source-only"
echo "============================================================"
echo '' 

sleep 2

cd scst-"$VersionString"
sudo cp -a . /usr/src/scst-"$VersionString"/.
sudo dkms mkdsc -m scst -v "$VersionString" --source-only
sudo tar -xzf /var/lib/dkms/scst/"$VersionString"/dsc/scst-dkms_"$VersionString".tar.gz -C /usr/src/scst-"$VersionString"
sudo mv /usr/src/scst-"$VersionString"/scst-dkms-"$VersionString" /usr/src/scst-"$VersionString"/scst-dkms-mkdsc
cd /usr/src/scst-"$VersionString"/

echo ''
echo "============================================================"
echo "Completed: sudo dkms mkdsc -m scst -v "$VersionString" --source-only" 
echo "============================================================"

sleep 2

echo ''
echo "============================================================"
echo "Build the Debian SCST DKMS deb packages...                  "
echo "============================================================"
echo '' 

sleep 2

sudo fakeroot debian/rules clean
sudo fakeroot debian/rules binary

echo ''
echo "============================================================"
echo "Completed:  Build the Debian SCST DKMS deb packages.        "
echo "============================================================"

sleep 2

echo ''
echo "============================================================"
echo "Install the Debian SCST DKMS deb packages...                "
echo "============================================================"
echo '' 

cd ..
ls -lrt *.deb
sudo dkms remove scst/"$VersionString" --all
sudo rm -rf /var/lib/dkms/scst

echo ''
echo "============================================================"
echo "Building initial module for `uname -r` can take awhile      "
echo "depending on the processing power of your system.           "
echo "Be patient...                                               "
echo "============================================================"
echo ''
sudo dpkg -D2 -i /usr/src/scst-dkms_"$VersionString"_amd64.deb
sudo dpkg -D2 -i /usr/src/iscsi-scst_"$VersionString"_amd64.deb
sudo dpkg -D2 -i /usr/src/scstadmin_"$VersionString"_amd64.deb
sudo dpkg -D2 -i /usr/src/scst-fileio-tgt_"$VersionString"_amd64.deb

echo ''
echo "============================================================"
echo "Completed: Install the Debian SCST DKMS deb packages.       "
echo "============================================================"

echo ''
echo "============================================================"
echo "Perform post-installation actions (modprobe, etc)...        "
echo "============================================================"
echo '' 

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

echo ''
echo "============================================================"
echo "Completed: Post-installation actions.                       "
echo "============================================================"

sleep 2

echo ''
echo "============================================================"
echo "Update File /etc/modules                                    "
echo "============================================================"
echo '' 

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

cat /etc/modules

echo ''
echo "============================================================"
echo "Completed: Update File /etc/modules.                        "
echo "============================================================"

sleep 2

echo ''
echo "============================================================"
echo "Create Service: scst-san (start iscsi-scstd load scst.conf) "
echo "============================================================"
echo '' 

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
cat /etc/systemd/system/scst-san.service

echo ''
echo "============================================================"
echo "Completed: Create Service scst-san                          "
echo "============================================================"

sleep 2

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

sleep 10

echo "=============================================="
echo "Completed:  Run SCST checks.                  "
echo "=============================================="
echo ''

