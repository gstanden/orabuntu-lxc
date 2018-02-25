#!/bin/bash

if [ ! -f /etc/sudoers.d/orabuntu-lxc ]
then
	sudo sh -c "echo 'Defaults      logfile=\"/home/amide/Downloads/orabuntu-lxc-master/installs/logs/$USER.log\"'	>> /etc/sudoers.d/orabuntu-lxc"
	sudo sh -c "echo 'Defaults      log_input,log_output'								>> /etc/sudoers.d/orabuntu-lxc"
	sudo chmod 0440 /etc/sudoers.d/orabuntu-lxc
fi
