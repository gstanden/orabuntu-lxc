#!/bin/bash
echo "==============================="
echo "The gstanden user is currently needed for this release of the software to work."
echo "Therefore, the gstanden user is created below"
echo "Accept defaults for all settings.  Set whatever password you want for the account."
echo "After this script runs, the Ubuntu host will reboot."
echo "After reboot, login as the gstanden user and run the orabuntu-lxc scripts."
echo "==============================="
echo ''
echo "Script execution will continue in 15 seconds..."
echo ''
sleep 15
sudo adduser gstanden
sudo adduser gstanden sudo
sudo wget -P /home/gstanden/Downloads/ https://github.com/gstanden/orabuntu-lxc/archive/master.zip
sudo unzip /home/gstanden/Downloads/master.zip -d /home/gstanden/Downloads
cd /home/gstanden/Downloads/orabuntu-lxc-master/
sudo cp -pr * ../.
sudo reboot

