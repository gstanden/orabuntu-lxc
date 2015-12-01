#!/bin/bash
echo "The gstanden5 user is currently needed for this release of the software to work."
echo "Therefore, the gstanden5 user is created below"
echo "Accept defaults for all settings.  Set whatever password you want for the account."
echo "After this script runs, the Ubuntu host will reboot."
echo "After reboot, login as the gstanden5 user and run the orabuntu-lxc scripts."
sudo adduser gstanden5
sudo adduser gstanden5 sudo
sudo wget -P /home/gstanden5/Downloads/ https://github.com/gstanden/orabuntu-lxc/archive/master.zip
sudo unzip /home/gstanden5/Downloads/master.zip -d /home/gstanden5/Downloads
sudo cd /home/gstanden5/Downloads/orabuntu-lxc/
sudo cp -pr * ../.
# sleep 15
# sudo reboot

