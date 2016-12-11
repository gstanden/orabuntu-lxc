#    Copyright 2015-2016 Gilbert Standen
#    This file is part of orabuntu-lxc.

#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.

#    v2.8 GLS 20151231
#    v3.0 GLS 20160710

#!/bin/bash

GetLinuxFlavor(){
	if [[ -e /etc/redhat-release ]]
	then
		LinuxFlavor=$(cat /etc/redhat-release | cut -f1 -d' ')
	elif [[ -e /usr/bin/lsb_release ]]
	then
		LinuxFlavor=$(lsb_release -d | awk -F ':' '{print $2}' | cut -f1 -d' ')
	elif [[ -e /etc/issue ]]
	then
		LinuxFlavor=$(cat /etc/issue | cut -f1 -d' ')
	else
		LinuxFlavor=$(cat /proc/version | cut -f1 -d' ')
	fi
}
GetLinuxFlavor

function TrimLinuxFlavor {
echo $LinuxFlavor | sed 's/^[ \t]//;s/[ \t]$//'
}
LinuxFlavor=$(TrimLinuxFlavor)

if [ $LinuxFlavor = 'Ubuntu' ]
then
	echo ''
	echo "===================================================="
	echo "Create multipath.conf for $LinuxFlavor Linux...     "
	echo "===================================================="

	sleep 5

	attrs='ATTRS{rev}|ATTRS{model}|ATTRS{vendor}'

	echo '' > multipath.conf
	echo 'blacklist {' >> multipath.conf
	echo '    devnode      "sd[a]$"' >> multipath.conf

	function GetDevNode {
	sudo ls /dev/sd* | sed 's/$/ /' | tr -d '\n'
	}
	DevNode=$(GetDevNode)

	if [ -f /etc/udev/rules.d/99-oracle.rules ]
	then
		sudo mv /etc/udev/rules.d/99-oracle.rules /etc/udev/rules.d/99-oracle.rules.pre-orabuntu.bak 
	fi

	for k in $DevNode
	do
		function GetVendor {
		sudo udevadm info -a -p  $(udevadm info -q path -n $k) | egrep 'ATTRS{vendor}' | grep -v '0x' | sed 's/  *//g' | rev | cut -f1 -d'=' | sed 's/"//g' | rev | sed 's/$/_DEVICE/'
		}
		Vendor=$(GetVendor)
 		function GetProduct {
 		sudo udevadm info -a -p  $(udevadm info -q path -n $k) | egrep 'ATTRS{model}' | grep -v '0x' | sed 's/  *//g' | rev | cut -f1 -d'=' | rev
 		}
 		Product=$(GetProduct)
		function CheckProductExist {
		cat multipath.conf | grep $Product | rev | cut -f1 -d' ' | rev | sort -u | wc -l
		}
		ProductExist=$(CheckProductExist)
		function GetExistId {
		sudo /lib/udev/scsi_id -g -u -d $k
		}
		ExistId=$(GetExistId)
		if [ "$Vendor" != "SCST_FIO_DEVICE" ] && [ "$ProductExist" -eq 0 ] && [ ! -z $ExistId ]
		then
			ExistId=$(GetExistId)
			function CheckIdExist {
			grep -c $ExistId multipath.conf
			}
			IdExist=$(CheckIdExist)
			if [ "$IdExist" -eq 0 ]
			then
				sudo /lib/udev/scsi_id -g -u -d $k | sed 's/^/    wwid         "/' | sed 's/$/"/' >> multipath.conf
			fi
		echo '    device {' >> multipath.conf
		sudo udevadm info -a -p  $(udevadm info -q path -n $k) | egrep "$attrs" | grep -v 0x | grep vendor | cut -f3 -d'=' | sed 's/  *//g' | sed 's/^/        vendor   /' >> multipath.conf
		sudo udevadm info -a -p  $(udevadm info -q path -n $k) | egrep "$attrs" | grep -v 0x | grep model  | cut -f3 -d'=' | sed 's/  *//g' | sed 's/^/        product  /' >> multipath.conf
		sudo udevadm info -a -p  $(udevadm info -q path -n $k) | egrep "$attrs" | grep -v 0x | grep rev    | cut -f3 -d'=' | sed 's/  *//g' | sed 's/^/        revision /' >> multipath.conf
		echo '    }' >> multipath.conf
		fi
	done
	echo '}' >> multipath.conf

	echo 'defaults {' >> multipath.conf
	echo '    user_friendly_names  yes' >> multipath.conf
	echo '}' >> multipath.conf
	echo 'devices {' >> multipath.conf
	echo '    device {' >> multipath.conf
	echo '    vendor               "SCST_FIO"' >> multipath.conf
	echo '    product              "asm*"' >> multipath.conf
	echo '    revision             "310"' >> multipath.conf
	echo '    path_grouping_policy group_by_serial' >> multipath.conf
	echo '    getuid_callout       "/lib/udev/scsi_id --whitelisted --device=/dev/%n"' >> multipath.conf
	echo '    hardware_handler     "0"' >> multipath.conf
	echo '    features             "1 queue_if_no_path"' >> multipath.conf
	echo '    fast_io_fail_tmo     5' >> multipath.conf
	echo '    dev_loss_tmo         30' >> multipath.conf
	echo '    failback             immediate' >> multipath.conf
	echo '    rr_weight            uniform' >> multipath.conf
	echo '    no_path_retry        fail' >> multipath.conf
	echo '    path_checker         tur' >> multipath.conf
	echo '    rr_min_io            4' >> multipath.conf
	echo '    path_selector        "round-robin 0"' >> multipath.conf
	echo '    }' >> multipath.conf
	echo '}' >> multipath.conf
	echo 'multipaths {' >> multipath.conf

	# Old function line
	# sudo scstadmin -list_group | grep systemdg | rev | cut -f1 -d' ' | rev | sed 's/$/ /' | tr -d '\n'

	function GetLunName {
	cat /etc/scst.conf | grep LUN | rev | cut -f1 -d' ' | rev | sed 's/$/ /' | tr -d '\n'
	}
	LunName=$(GetLunName)

	for i in $LunName
	do
		function GetDevNode {
		sudo ls /dev/sd* | sed 's/$/ /' | tr -d '\n'
		}
		DevNode=$(GetDevNode)
		for j in $DevNode
		do
			function GetModelName {
		sudo udevadm info -a -p  $(udevadm info -q path -n $j) | egrep 'ATTRS{model}' | sed 's/  *//g' | rev | cut -f1 -d'=' | sed 's/"//g' | rev | sed 's/^[ \t]*//;s/[ \t]*$//' | grep $i 
			}
			function CheckEntryExist {
			cat multipath.conf | grep $i
			}
			EntryExist=$(CheckEntryExist)
			ModelName=$(GetModelName)
			if [ "$ModelName" = "$i" ] && [ -z "$EntryExist" ]
			then
				function Getwwid {
				sudo /lib/udev/scsi_id -g -u -d $j
				}
			wwid=$(Getwwid)
			echo "     multipath {" >> multipath.conf
			echo "         wwid $wwid" >> multipath.conf
			echo "         alias $i" >> multipath.conf
			echo "     }" >> multipath.conf
			sudo sh -c "echo 'ENV{DM_UUID}==\"mpath-$wwid\", SYMLINK+=\"asm/$i\", OWNER:=\"grid\", GROUP:=\"asmadmin\", MODE:=\"660\"' >> /etc/udev/rules.d/99-oracle.rules"
			sleep 5
			fi
		done
	done
	echo '}' >> multipath.conf

	# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.

	function GetRunningKernelVersion {
	uname -r | cut -f1-2 -d'.'
	}
	RunningKernelVersion=$(GetRunningKernelVersion)

	# GLS 20151126 Added function to get kernel directory path for running kernel version to support linux 4.x and linux 3.x kernels etc.

	function GetKernelDirectoryPath {
	uname -a | cut -f3 -d' ' | cut -f1 -d'-' | cut -f1 -d'.' | sed 's/^/linux-/'
	}
	KernelDirectoryPath=$(GetKernelDirectoryPath)

	if [ $KernelDirectoryPath = 'linux-4' ]
	then
	sed -i 's/revision "/# revision "/' multipath.conf
	fi

	cat multipath.conf

	echo "===================================================="
	echo "File multipath.conf created for $LinuxFlavor Linux  "
	echo "===================================================="
	echo ''

	sleep 10

	clear

	echo ''
	echo "===================================================="
	echo "Backup old /etc/multipath.conf and install new...   "
	echo "===================================================="
	echo ''
	
	if [ -f /etc/multipath.conf ]
	then
	sudo cp -p /etc/multipath.conf /etc/multipath.conf.pre-scst.orabuntu-lxc.bak
	fi
	sudo cp -p multipath.conf /etc/multipath.conf

	sudo ls -l /etc/multipath.conf*

	echo ''
	echo "===================================================="
	echo "Backup complete.                                    "
	echo "===================================================="

	sleep 5

	clear

	echo ''
	echo "===================================================="
	echo "Restart multipath service...                        "
	echo "===================================================="
	echo ''

	sudo service multipath-tools stop
	sudo multipath -F
	sudo service multipath-tools start

	echo ''
	echo "===================================================="
	echo "Restart multipath service completed.                "
	echo "===================================================="

	sleep 5

	clear

	echo ''
	echo "===================================================="
	echo "Check Oracle SCST LUNs present and using aliases... "
	echo "===================================================="
	echo ''

	ls -l /dev/mapper | grep asm

	echo ''
	echo "===================================================="
	echo "SCST LUNs present and using aliases.                "
	echo "===================================================="

	sleep 5

	clear

	echo ''
	echo "===================================================="
	echo "Check multipath...                                  "
	echo "===================================================="
	echo ''

	sudo multipath -ll -v2
	
	echo ''
	echo "===================================================="
	echo "Check multipath...                                  "
	echo "===================================================="

	sleep 5

	clear
fi

if [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Red' ]
then
	echo ''
	echo "===================================================="
	echo "Create multipath.conf for $LinuxFlavor Linux...     "
	echo "===================================================="
	echo ''

	attrs='ATTRS{rev}|ATTRS{model}|ATTRS{vendor}'

	echo '' > multipath.conf
	echo 'blacklist {' >> multipath.conf
	echo '    devnode      "sd[a]$"' >> multipath.conf

	function GetDevNode {
	ls /dev/sd* | sed 's/$/ /' | tr -d '\n'
	}
	DevNode=$(GetDevNode)
	for k in $DevNode
	do
		function GetVendor {
			udevadm info -a -p  $(udevadm info -q path -n $k) | egrep 'ATTRS{vendor}' | grep -v '0x' | sed 's/  *//g' | rev | cut -f1 -d'=' | sed 's/"//g' | rev | sed 's/$/_DEVICE/'
		}
		Vendor=$(GetVendor)
 		function GetProduct {
 			udevadm info -a -p  $(udevadm info -q path -n $k) | egrep 'ATTRS{model}' | grep -v '0x' | sed 's/  *//g' | rev | cut -f1 -d'=' | rev
 		}
 		Product=$(GetProduct)
		function CheckProductExist {
			cat multipath.conf | grep $Product | rev | cut -f1 -d' ' | rev | sort -u | wc -l
		}
		ProductExist=$(CheckProductExist)
		function GetExistId {
	 		/lib/udev/scsi_id -g -u -d $k
		}
		ExistId=$(GetExistId)
		if [ "$Vendor" != "SCST_FIO_DEVICE" ] && [ "$ProductExist" -eq 0 ] && [ ! -z $ExistId ]
		then
			ExistId=$(GetExistId)
			function CheckIdExist {
			grep -c $ExistId multipath.conf
			}
			IdExist=$(CheckIdExist)
			if [ "$IdExist" -eq 0 ]
			then
				 /lib/udev/scsi_id -g -u -d $k | sed 's/^/    wwid         "/' | sed 's/$/"/' >> multipath.conf
			fi
		echo '    device {' >> multipath.conf
		udevadm info -a -p  $(udevadm info -q path -n $k) | egrep "$attrs" | grep -v 0x | grep vendor | cut -f3 -d'=' | sed 's/  *//g' | sed 's/^/        vendor   /' >> multipath.conf
		udevadm info -a -p  $(udevadm info -q path -n $k) | egrep "$attrs" | grep -v 0x | grep model  | cut -f3 -d'=' | sed 's/  *//g' | sed 's/^/        product  /' >> multipath.conf
		udevadm info -a -p  $(udevadm info -q path -n $k) | egrep "$attrs" | grep -v 0x | grep rev    | cut -f3 -d'=' | sed 's/  *//g' | sed 's/^/        revision /' >> multipath.conf
		echo '    }' >> multipath.conf
		fi
	done
	echo '}' >> multipath.conf

		echo 'defaults {' 									>> multipath.conf
		echo '    user_friendly_names  yes' 							>> multipath.conf
		echo '}' 										>> multipath.conf
		echo 'devices {' 									>> multipath.conf
		echo '    device {' 									>> multipath.conf
		echo '    vendor               "SCST_FIO"' 						>> multipath.conf
		echo '    product              "asm*"' 							>> multipath.conf
	
	function GetLinuxRelease {
		cat /etc/redhat-release | grep -c 'release 7'
	}
	LinuxRelease=$(GetLinuxRelease)
	if [ $LinuxRelease -eq 1 ]
	then
		echo '#   revision             "310"' 							>> multipath.conf
		echo '#   getuid_callout       "/lib/udev/scsi_id --whitelisted --device=/dev/%n"' 	>> multipath.conf
	else
		echo '    getuid_callout       "/lib/udev/scsi_id --whitelisted --device=/dev/%n"'	>> multipath.conf
		echo '    revision             "310"'							>> multipath.conf
	fi
		echo '    path_grouping_policy group_by_serial' 					>> multipath.conf
		echo '    hardware_handler     "0"' 							>> multipath.conf
		echo '    features             "1 queue_if_no_path"' 					>> multipath.conf
		echo '    fast_io_fail_tmo     5' 							>> multipath.conf
		echo '    dev_loss_tmo         30' 							>> multipath.conf
		echo '    failback             immediate' 						>> multipath.conf
		echo '    rr_weight            uniform' 						>> multipath.conf
		echo '    no_path_retry        fail' 							>> multipath.conf
		echo '    path_checker         tur' 							>> multipath.conf
		echo '    rr_min_io            4' 							>> multipath.conf
		echo '    path_selector        "round-robin 0"' 					>> multipath.conf
		echo '    }' 										>> multipath.conf
		echo '}' 										>> multipath.conf
		echo 'multipaths {' 									>> multipath.conf

	# Old function line
	#  scstadmin -list_group | grep systemdg | rev | cut -f1 -d' ' | rev | sed 's/$/ /' | tr -d '\n'

	function GetLunName {
	cat /etc/scst.conf | grep LUN | rev | cut -f1 -d' ' | rev | sed 's/$/ /' | tr -d '\n'
	}
	LunName=$(GetLunName)

	for i in $LunName
	do
		function GetDevNode {
			ls /dev/sd* | sed 's/$/ /' | tr -d '\n'
		}
		DevNode=$(GetDevNode)
			for j in $DevNode
			do
			     function GetModelName {
			     udevadm info -a -p  $(udevadm info -q path -n $j) | egrep 'ATTRS{model}' | sed 's/  *//g' | rev | cut -f1 -d'=' | sed 's/"//g' | rev | sed 's/^[ \t]*//;s/[ \t]*$//' | grep $i 
			     }
			     function CheckEntryExist {
					cat multipath.conf | grep $i
			     }
			EntryExist=$(CheckEntryExist)
			ModelName=$(GetModelName)
			if [ "$ModelName" = "$i" ] && [ -z "$EntryExist" ]
			then
				function Getwwid {
					/lib/udev/scsi_id -g -u -d $j
				}
				wwid=$(Getwwid)
				echo "     multipath {" >> multipath.conf
				echo "         wwid $wwid" >> multipath.conf
				echo "         alias $i" >> multipath.conf
				echo "     }" >> multipath.conf
			fi
		done
	done
	echo '}' >> multipath.conf

	# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.

	function GetRunningKernelVersion {
		uname -r | cut -f1-2 -d'.'
	}
	RunningKernelVersion=$(GetRunningKernelVersion)

	# GLS 20151126 Added function to get kernel directory path for running kernel version to support linux 4.x and linux 3.x kernels etc.

	function GetKernelDirectoryPath {
		uname -a | cut -f3 -d' ' | cut -f1 -d'-' | cut -f1 -d'.' | sed 's/^/linux-/'
	}
	KernelDirectoryPath=$(GetKernelDirectoryPath)

	if [ $KernelDirectoryPath = 'linux-4' ]
	then
		sed -i 's/revision "/# revision "/' multipath.conf
	fi

	echo ''	
	echo "===================================================="
	echo "File multipath.conf created for $LinuxFlavor Linux  "
	echo "===================================================="

	sleep 5

	clear
	
	echo ''
	echo "===================================================="
	echo "Install multipath.conf file (backup old first)...   "
	echo "===================================================="

	if [ -f /etc/multipath.conf ]
	then
	sudo cp -p /etc/multipath.conf /etc/multipath.conf.pre-scst.orabuntu-lxc.bak
	fi
	sudo cp -p multipath.conf /etc/multipath.conf

	cat /etc/multipath.conf

	echo ''
	echo "===================================================="
	echo "Install multipath.conf file completed.              "
	echo "===================================================="

	sleep 10

	clear

	echo ''
	echo "===================================================="
	echo "Restart multipath service...                        "
	echo "===================================================="
	echo ''

	sudo service multipathd stop
	sudo service multipath -F
	sudo service multipathd start

	echo ''
	echo "===================================================="
	echo "Restart multipath service completed.                "
	echo "===================================================="

	sleep 5

	clear
	
	echo ''
	echo "===================================================="
	echo "Check Oracle SCST /dev/mapper LUNs and aliases...   "
	echo "===================================================="
	echo ''

	ls -l /dev/mapper/asm*

	echo ''
	echo "===================================================="
	echo "Oracle SCST /dev/mapper LUNs and aliases displayed. "
	echo "===================================================="

	sleep 5

	clear

	echo ''
	echo "===================================================="
	echo "Check multipaths ...                                "
	echo "===================================================="
	echo ''

	sudo multipath -ll -v2

	echo ''
	echo "===================================================="
	echo "Check multipaths completed.                         "
	echo "===================================================="
	echo ''
fi
