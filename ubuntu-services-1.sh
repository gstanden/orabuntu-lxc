#!/bin/bash

echo "============================================"
echo "Be sure you have UPDATED your Ubuntu 15.04  "
echo "Only use a FRESH Ubuntu 15.04 install       "
echo "These scripts overwrite some configurations!"
echo "Use with customized Ubuntu at your own risk!"
echo "<CTRL> + C to exit                          "
echo "Sleeping 10 seconds...                      "
echo "============================================"

sleep 10

clear

# echo "==============================================="
# echo "DHCP service clear, start, and test...         "
# echo "Verify health status...                        "
# echo "==============================================="
# echo ''

if [ -e /var/lib/dhcp/dhcpd.leases ]
then
echo ''
echo "Destroy DHCP Leases?  [ Y | N ]:"
read input_variable2
echo ''
echo "You entered: $input_variable2"
echo ''

if [ $input_variable2 = 'Y' ]
then

	echo ''

	echo "Clearing DHCP Leases..."

	echo ''
	sudo service isc-dhcp-server stop
	if [ -e /var/lib/dhcp/dhcpd.leases~ ]
		then
		sudo rm /var/lib/dhcp/dhcpd.leases~
	fi

	if [ -e /var/lib/dhcp/dhcpd.leases ]
	then
		sudo rm /var/lib/dhcp/dhcpd.leases
	fi
	sudo service isc-dhcp-server start
	sudo service isc-dhcp-server status

fi
fi

# echo ''
# echo "==============================================="
# echo "Verify isc-dhcp-server service completed       "
# echo "==============================================="

# sleep 5

clear

echo "============================================"
echo "Verify network up....                       "
echo "============================================"
echo ''

sleep 2

ping -c 3 google.com
if [ $? -ne 0 ]
then
echo ''
echo "============================================"
echo "Network is not up.  Script exiting.         "
echo "ping google.com must succeed                "
echo "Address network issues and retry script     "
echo "============================================"
echo ''
exit
fi

echo ''
echo "============================================"
echo "Network verification complete               "
echo "============================================"
echo ''

sleep 5

clear

function CheckLXCExist {
which lxc-ls | grep -c lxc-ls
}
LXCExist=$(CheckLXCExist)


if [ $LXCExist -eq 1 ]
then

echo "==========================================="
echo "Destruction of Containers (if necessary)   "
echo "Checking...                                "
echo "==========================================="
echo ''
function CheckClonedContainersExist {
sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
}
ClonedContainersExist=$(CheckClonedContainersExist)

function CheckClonedContainersExistLength {
sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g' | sed 's/^[ \t]*//;s/[ \t]*$//' | wc -c
}
ClonedContainersExistLength=$(CheckClonedContainersExistLength)

sleep 5

if [ $ClonedContainersExistLength -gt 0 ]
then

echo ''
echo "Existing containers in the set { $ClonedContainersExist} have been found."
echo "These containers match the names of containers that are about to be created."
echo "Please answer Y to destroy the existing containers or N to keep them"
echo ''

echo "!!! WARNING:  ANSWERING Y WILL DESTROY EXISTING CONTAINERS !!!"

echo ''
echo "Destroy existing containers?  [ Y | N ]:"
read input_variable
echo ''
echo "You entered: $input_variable"
echo ''

echo "<ctrl>+c to exit program and abort container destruction"
echo "sleeping for 5 seconds..."

sleep 5

if [ ! -z "$ClonedContainersExist" ]
then
for j in $ClonedContainersExist
do
echo ''
echo "Container Name = $j"
echo "<ctrl>+c to exit"
echo ''

if [ "$input_variable" = 'N' ]
then
echo ''
echo "sudo lxc-destroy -n $j"
echo ''
echo "Container NOT destroyed"
echo ''
fi

if [ $input_variable = 'Y' ]
then
echo ''
echo "Destroying container in 5 seconds..."
echo ''
sleep 5
echo "Command running: sudo lxc-destroy -n $j"
echo ''
sudo lxc-stop -n $j 
sleep 2
sudo lxc-destroy -n $j -f
echo ''
echo "Command running: rm -rf /var/lib/lxc/$j"
echo ''
sudo rm -rf /var/lib/lxc/$j
echo ''
fi
done
fi


echo ''
echo "==========================================="
echo "Destruction of Containers complete         "
echo "==========================================="
else
echo ''
echo "==========================================="
echo "No Containers to Destroy                   "
echo "Continuing in 5 seconds...                 "
echo "==========================================="
fi
fi

sleep 5

clear

if [ $LXCExist -eq 1 ]
then

echo "==========================================="
echo "Show Running Containers...                 "
echo "(no containers lxcora* running)            "
echo "==========================================="
echo ''

sudo lxc-ls -f

echo ''
echo "==========================================="
echo "Running Container Check completed          "
echo "==========================================="

sleep 5

fi

clear

echo "==========================================="
echo "Ubuntu Package Installation...             "
echo "==========================================="
echo ''

sudo apt-get install -y synaptic
sudo apt-get install -y cpu-checker
sudo apt-get install -y lxc
sudo apt-get install -y uml-utilities
sudo apt-get install -y openvswitch-switch
sudo apt-get install -y openvswitch-common
sudo apt-get install -y openvswitch-controller
sudo apt-get install -y bind9
sudo apt-get install -y bind9utils
sudo apt-get install -y isc-dhcp-server
sudo apt-get install -y apparmor-utils
sudo apt-get install -y openssh-server
sudo apt-get install -y uuid
sudo apt-get install -y qemu-kvm
sudo apt-get install -y libvirt-bin
sudo apt-get install -y virt-manager
sudo apt-get install -y rpm
sudo apt-get install -y yum
sudo apt-get install -y hugepages
sudo apt-get install -y nfs-kernel-server
sudo apt-get install -y nfs-common portmap
sudo apt-get install -y multipath-tools
sudo apt-get install -y open-iscsi 
sudo apt-get install -y multipath-tools 
sudo apt-get install -y ntp
sudo apt-get install -y iotop
sudo apt-get install -y flashplugin-installer

sudo aa-complain /usr/bin/lxc-start

echo ''
echo "==========================================="
echo "Ubuntu Package Installation complete       "
echo "==========================================="
echo ''

sleep 5

clear

echo "==========================================="
echo "Create the LXC oracle container...         "
echo "==========================================="
echo ''

sudo lxc-create -t oracle -n lxcora0

echo ''
echo "==========================================="
echo "Create the LXC oracle container complete   "
echo "(Passwords are the same as the usernames)  "
echo "Sleeping 15 seconds...                     "
echo "==========================================="
echo ''

sleep 15

clear

sudo service bind9 stop
sudo service isc-dhcp-server stop
sudo service multipath-tools stop

# Backup existing files before untar of updated files.
~/Downloads/ubuntu-host-backup-1a.sh

# Check existing file backups to be sure they were made successfully
echo "==============================================="
echo "Checking existing file backups before writing  "
echo "===============================================" 
echo ''

~/Downloads/ubuntu-host-backup-check-1a.sh

sleep 2 

echo ''
echo "==============================================="
echo "Existing file backups check complete           "
echo "===============================================" 

sleep 5

clear

# Unpack customized OS host files for Oracle on Ubuntu LXC host server
echo "==============================================="
echo "Unpacking custom files for Oracle on Ubuntu... "
echo "==============================================="

sleep 5

sudo tar -P -xvf ubuntu-host.tar

sudo cp -p ~/Downloads/rc.local.ubuntu.host /etc/rc.local
sudo chown root:root /etc/rc.local
sudo sed -i 's/10\.207\.39\.10/10\.207\.39\.9/' /etc/dhcp/dhcpd.conf

echo ''
echo "==============================================="
echo "Custom files for Ubuntu unpack complete        "
echo "==============================================="

sleep 5

clear

# echo "==============================================="
# echo "Restarting Networking on the Ubuntu host...    "
# echo "Be patient...                                  "
# echo "==============================================="
# echo ''

# sudo /etc/init.d/networking restart

# echo ''
# echo "==============================================="
# echo "Restarting Network complete.                   "
# echo "==============================================="

# sleep 2

# clear

echo "==============================================="
echo "Copying required /etc/resolv.conf file         "
echo "On reboot it will be auto-generated.           "
echo "==============================================="
sudo cp ~/Downloads/resolv.conf.temp /etc/resolv.conf

sleep 2

echo "==============================================="
echo "Copying required /etc/resolv.conf complete     "
echo "==============================================="

sleep 2

clear

echo "==============================================="
echo "Starting bind9 service...                      "
echo "Verify healthy status...                       "
echo "==============================================="
echo ''
sudo service bind9 start
sudo service bind9 status
echo ''
echo "==============================================="
echo "Verify bind9 service completed                 "
echo "==============================================="

sleep 5

clear

echo "==============================================="
echo "Starting DHCP service...                       "
echo "Verify health status...                        "
echo "==============================================="
echo ''

sudo service isc-dhcp-server start
sudo service isc-dhcp-server status

echo ''
echo "==============================================="
echo "Verify isc-dhcp-server service completed       "
echo "==============================================="

sleep 5

clear

sudo cp -p ~/Downloads/create-ovs-sw-files-v2.sh.bak /etc/network/if-up.d/openvswitch/create-ovs-sw-files-v2.sh

cd /etc/network/if-up.d/openvswitch
sudo mv lxcora01-asm1-ifup-sw8  lxcora00-asm1-ifup-sw8
sudo mv lxcora01-asm2-ifup-sw9  lxcora00-asm2-ifup-sw9
sudo mv lxcora01-priv1-ifup-sw4 lxcora00-priv1-ifup-sw4
sudo mv lxcora01-priv2-ifup-sw5 lxcora00-priv2-ifup-sw5
sudo mv lxcora01-priv3-ifup-sw6 lxcora00-priv3-ifup-sw6 
sudo mv lxcora01-priv4-ifup-sw7 lxcora00-priv4-ifup-sw7
sudo mv lxcora01-pub-ifup-sw1   lxcora00-pub-ifup-sw1

sudo cp lxcora00-asm1-ifup-sw8  lxcora0-asm1-ifup-sw8
sudo cp lxcora00-asm2-ifup-sw9  lxcora0-asm2-ifup-sw9
sudo cp lxcora00-priv1-ifup-sw4 lxcora0-priv1-ifup-sw4
sudo cp lxcora00-priv2-ifup-sw5 lxcora0-priv2-ifup-sw5
sudo cp lxcora00-priv3-ifup-sw6 lxcora0-priv3-ifup-sw6 
sudo cp lxcora00-priv4-ifup-sw7 lxcora0-priv4-ifup-sw7
sudo cp lxcora00-pub-ifup-sw1   lxcora0-pub-ifup-sw1

sudo rm lxcora02* lxcora03* lxcora04* lxcora05* lxcora06* 

cd /etc/network/if-down.d/openvswitch
sudo mv lxcora01-asm1-ifdown-sw8  lxcora00-asm1-ifdown-sw8
sudo mv lxcora01-asm2-ifdown-sw9  lxcora00-asm2-ifdown-sw9
sudo mv lxcora01-priv1-ifdown-sw4 lxcora00-priv1-ifdown-sw4
sudo mv lxcora01-priv2-ifdown-sw5 lxcora00-priv2-ifdown-sw5
sudo mv lxcora01-priv3-ifdown-sw6 lxcora00-priv3-ifdown-sw6
sudo mv lxcora01-priv4-ifdown-sw7 lxcora00-priv4-ifdown-sw7
sudo mv lxcora01-pub-ifdown-sw1   lxcora00-pub-ifdown-sw1

sudo cp lxcora00-asm1-ifdown-sw8  lxcora0-asm1-ifdown-sw8
sudo cp lxcora00-asm2-ifdown-sw9  lxcora0-asm2-ifdown-sw9
sudo cp lxcora00-priv1-ifdown-sw4 lxcora0-priv1-ifdown-sw4
sudo cp lxcora00-priv2-ifdown-sw5 lxcora0-priv2-ifdown-sw5
sudo cp lxcora00-priv3-ifdown-sw6 lxcora0-priv3-ifdown-sw6
sudo cp lxcora00-priv4-ifdown-sw7 lxcora0-priv4-ifdown-sw7
sudo cp lxcora00-pub-ifdown-sw1   lxcora0-pub-ifdown-sw1

sudo rm lxcora02* lxcora03* lxcora04* lxcora05* lxcora06* 
sudo useradd -u 1098 grid

echo "==============================================="
echo "Next script to run: ubuntu-services-2a.sh      "
echo "Rebooting in 5 seconds...                      "
echo "==============================================="

sleep 5
sudo reboot
