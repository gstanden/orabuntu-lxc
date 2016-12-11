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
#    v3.1 GLS 20160924 # Removes requirement of custom kernel for SCST deployment for Linux kernels >= 2.6.30


#    This software is for kernels 2.6.30 and higher but it can be used with lower kernels if you build a custom SCST kernel.		
#    Read Chris Weiss post on building custom SCST kernel on Ubuntu for kernels older than 2.6.30.
#    https://gist.github.com/chrwei/42f8bbb687290b04b598.

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

clear

echo ''
echo "======================================================="
echo "Check if kernel version meets minimum requirement...   "
echo "======================================================="
echo ''

# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.
# GLS 20160924 SCST 3.1 does not require a custom kernel build for kernels >= 2.6.30 so now we check that kernel is >= 2.6.30.
# GLS 20160924 If the kernel version is lower than 2.6.30 it will be necessary for you to compile a custom kernel.
# GLS 20161119 All installs will be done by "ubuntu" user with "sudo" for all distros.

function VersionKernelPassFail () {
    ./vercomp | cut -f1 -d':'
}
KernelPassFail=$(VersionKernelPassFail)
echo $KernelPassFail

echo ''
echo "======================================================="
echo "Kernel version meets minimum requirement.              "
echo "======================================================="
echo ''

sleep 5

clear

if [ $KernelPassFail = 'Pass' ]
then
	if [ $LinuxFlavor = 'Ubuntu' ]
	then
		echo ''
		echo "======================================================="
		echo "Establish sudo privileges ...                          "
		echo "======================================================="
		echo ''

		sudo date

		echo ''
		echo "======================================================="
		echo "Establish sudo privileges successful.                  "
		echo "======================================================="
		echo ''

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Installing Packages ...                                "
		echo "======================================================="
		echo ''

		sudo apt-get install -y gawk build-essential
		sudo apt-get install -y multipath-tools
		sudo apt-get install -y open-iscsi
		sudo apt-get install -y gawk
		sudo apt-get install -y subversion
		sudo apt-get install -y make

		echo ''
		echo "======================================================="
		echo "Installing Packages completed.                         "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Installing SCST version 3.1                            "
		echo "======================================================="
		echo ''

		sleep 5

		svn co https://scst.svn.sourceforge.net/svnroot/scst/branches/3.1.x scst-3.1
		cd scst-3.1
		sudo make 2perf scst scst_install iscsi iscsi_install scstadm scstadm_install
		sudo systemctl enable scst.service
		sudo service scst start
		sudo service scst status
		sudo make scst scst_install iscsi iscsi_install scstadm scstadm_install
		sudo modprobe scst
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
		sudo iscsi-scstd
		sudo service scst start
		sudo systemctl enable scst.service
		sudo systemctl daemon-reload

		echo ''
		echo "======================================================="
		echo "Install SCST version 3.1 completed.                    "
		echo "======================================================="

		sleep 5

		clear

	elif [ $LinuxFlavor = 'CentOS' ]
	then
		clear

		echo ''
		echo "======================================================="
		echo "Establish sudo privileges ...                          "
		echo "======================================================="
		echo ''

		sudo date

		echo ''
		echo "======================================================="
		echo "Establish sudo privileges successful.                  "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Installing Packages ...                                "
		echo "======================================================="
		echo ''

		sleep 5

		sudo yum -y install svn
		sudo yum -y groupinstall "Development Tools" 
		sudo yum -y install asciidoc newt-devel xmlto
		sudo yum -y install perl-ExtUtils-MakeMaker
		sudo yum -y install kernel-devel-$(uname -r)
		sudo yum -y install device-mapper-multipath
		sudo yum -y install iscsi-initiator-utils
		sudo yum -y install psmisc

		echo ''
		echo "======================================================="
		echo "Installing Packages completed.                         "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Installing SCST version 3.1                            "
		echo "======================================================="

		sleep 5

		clear

		svn co https://scst.svn.sourceforge.net/svnroot/scst/branches/3.1.x scst-3.1
		cd scst-3.1
		make 2perf scst scst_install iscsi iscsi_install scstadm scstadm_install
		sudo systemctl enable scst.service
		sudo service scst start
		sudo service scst status
		make scst scst_install iscsi iscsi_install scstadm scstadm_install
		sudo modprobe scst
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
		sudo iscsi-scstd
		sudo service scst start
		sudo systemctl enable scst.service
		
		echo ''
		echo "======================================================="
		echo "Install SCST version 3.1 completed.                    "
		echo "======================================================="

	elif [ $LinuxFlavor = 'Red' ]
	then
		echo ''
		echo "======================================================="
		echo "Kernel Version meets requirements.                     "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Installing Packages ...                                "
		echo "======================================================="
		echo ''

		sudo yum -y install svn
		sudo yum -y groupinstall "Development Tools" 
		sudo yum -y install asciidoc newt-devel xmlto
		sudo yum -y install perl-ExtUtils-MakeMaker
		function CheckKernelUek {
			uname -r | grep -c uek
		}
		KernelUek=$(CheckKernelUek)
		if [ $KernelUek -eq 1 ]
		then
			sudo yum -y install kernel-uek-devel-$(uname -r)
		else
			sudo yum -y install kernel-devel-$(uname -r)
		fi
		sudo yum -y install device-mapper-multipath
		sudo yum -y install iscsi-initiator-utils
		sudo yum -y install psmisc
		# GLS 20161119 psmisc needed for SCST killall command during service shutdown
		
		echo ''
		echo "======================================================="
		echo "Installing Packages completed.                         "
		echo "======================================================="

		sleep 5

		clear   

		echo ''
		echo "======================================================="
		echo "Download SCST 3.1 source...                 "
		echo "======================================================="
		echo ''
               
		sleep 5
 
		svn co https://scst.svn.sourceforge.net/svnroot/scst/branches/3.1.x scst-3.1
                cd scst-3.1 
		
		echo ''
		echo "======================================================="
		echo "Download SCST 3.1 source completed.                    "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Make SCST from source...                               "
		echo "======================================================="
		echo ''

		sleep 5

                make 2perf scst scst_install iscsi iscsi_install scstadm scstadm_install
                systemctl enable scst.service
                service scst start
                service scst status
                make scst scst_install iscsi iscsi_install scstadm scstadm_install
		
		echo ''
		echo "======================================================="
		echo "Make SCST from source completed.                       "
		echo "======================================================="

		sleep 5

		clear
		
		echo ''
		echo "======================================================="
		echo "Modprobe SCST modules and complete SCST setup...       "
		echo "======================================================="
		echo ''

		modprobe scst
		modprobe scst_vdisk
		modprobe scst_disk
		modprobe scst_user
		modprobe scst_modisk
		modprobe scst_processor
		modprobe scst_raid
		modprobe scst_tape
		modprobe scst_cdrom
		modprobe scst_changer
		modprobe iscsi-scst
		iscsi-scstd > /dev/null 2>&1
		service scst start
		systemctl enable scst.service
		
		echo ''
		echo "======================================================="
		echo "Modprobe SCST modules and SCST setup complete.         "
		echo "======================================================="
		echo ''

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Install SCST version 3.1 completed.                    "
		echo "======================================================="
	else
		echo ''
		echo "======================================================="
		echo "Kernel version is lower than 2.6.30. Consider Upgrade. "
		echo "Or a handler for your linux distro is not yet in.      " 
		echo "======================================================="
	fi
fi
