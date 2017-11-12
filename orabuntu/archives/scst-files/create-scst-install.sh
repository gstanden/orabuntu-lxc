#!/bin/bash

#    Copyright 2015-2017 Gilbert Standen
#    This file is part of orabuntu-lxc:  https://github.com/gstanden/orabuntu-lxc
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
#    This software is for kernels 2.6.30 and higher but it can be used with lower kernels if you build a custom SCST kernel.
#    Read Chris Weiss post on building custom SCST kernel on Ubuntu for kernels older than 2.6.30.
#    https://gist.github.com/chrwei/42f8bbb687290b04b598.#!/bin/bash
#
#   !! SEE THE README FILE FOR COMPLETE INSTRUCTIONS FIRST BEFORE RUNNING !!
#
#   sudo ALL privilege is required      prior to running!
#   internet connectivity is required   prior to running!

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
    if [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Debian' ]
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
        echo "Get Ubuntu Release (17.04, 16.04, etc.) ...            "
        echo "======================================================="
        echo ''

	function GetUbuntuMajorRelease {
		lsb_release -r | cut -f1 -d'.' | cut -f2 -d':' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	UbuntuMajorRelease=$(GetUbuntuMajorRelease)
	
	function GetUbuntuRelease {
		lsb_release -r | cut -f2 -d':' | sed 's/^[ \t]*//;s/[ \t]*$//' 
	}
	UbuntuRelease=$(GetUbuntuRelease)

	function GetKernelVersion {
		uname -r
	}
	KernelVersion=$(GetKernelVersion)

	function GetKernelMajorVersion {
		uname -r | cut -f1-2 -d'.'
	}
	KernelMajorVersion=$(GetKernelMajorVersion)

	function GetUbuntuDistro {
		lsb_release -a | grep Codename | cut -f2 -d':' | sed 's/^[ \t]*//;s/[ \t]*$//' 
	}
	UbuntuDistro=$(GetUbuntuDistro)

	sleep 5

	clear

        echo ''
        echo "======================================================="
        echo "Distribution is: $UbuntuDistro                         "
	echo "Release is     : $UbuntuRelease                        "
        echo "======================================================="
        echo ''

	sleep 5

	clear

	if [ "$UbuntuRelease" = '16.04' ] && [ "$KernelMajorVersion" = '4.4' ]
	then
        	echo "========================================================"
        	echo "Ubuntu $UbuntuRelease must be upgraded to 16.04.3 HWE   "
		echo "if SCST DKMS install method (preferred) is used.        "
		echo "                                                        "
		echo "These Ubuntu 16.04 kernels do not work with SCST DKMS:  "
		echo "                                                        "
		echo "     4.4.0-87                                           "
		echo "     4.4.0-88                                           "
		echo "     4.4.0-89                                           "
		echo "                                                        "
		echo "Also even if you are on the earlier 16.04 kernels:      "
		echo "                                                        "
                echo "     4.4.0-31                                           "
		echo "     4.4.0-84                                           "
		echo "                                                        "
		echo "SCST DKMS will break when upgrading to the affected     "
		echo "kernels (4.4.0-87,88,89) listed above.                  " 
		echo "                                                        "
		echo "Therefore to use SCST DKMS install method, which is the "
		echo "preferred method, it is necessary to upgrade now to the "
		echo "Ubuntu 16.04.3 LTS HWE (kernel 4.10.0-30-generic).      "
		echo "                                                        "
		echo "More info on that here:                                 "
		echo "                                                        "
		echo "https://wiki.ubuntu.com/Kernel/RollingLTSEnablementStack"
		echo "                                                        "
		echo "If you want to read up on this before answering Y or N  "
		echo "then <ctrl>+c now to read the above link on Ubuntu HWE  "
		echo "updates first, then re-run create-scst.sh.              "
		echo "                                                        " 
		echo "If you answer 'Y' below your OS will be automatically   "
		echo "updated to 16.04.3 HWE (kernel 4.10.0-30-generic) and   "
		echo "the server will reboot to load the new kernel.          "
		echo "                                                        "
		echo "Answering 'N' below means SCST installer will skip the  "
		echo "DKMS SCST install and instead do non-DKMS SCST install. "
		echo "                                                        "
		echo "A non-DKMS SCST install means that the SCST kernel      "
		echo "modules will need to be manually rebuilt after every    "
		echo "kernel upgrade.  DKMS on the other hand automatically   "
		echo "rebuilds SCST kernel modules after every kernel upgrade."
		echo "                                                        "
		echo "Answer Y or N to upgrade to the 16.04.3 HWE             "
		echo "                                                        "
		echo "                !!! WARNING !!!                         "
		echo "                                                        "
		echo "Answering Y here will cause this host to be upgraded and" 
		echo "the host will reboot.  After the reboot, re-run the     "
		echo "create-scst.sh script to install SCST DKMS and configure"
		echo "SCST Linux SAN.                                         "
		echo "                                                        "
	read -e -p   "Upgrade to 16.04.3 HWE (kernel 4.10.0-30-generic)? [Y/N]" -i "Y" Upgrade1604HWE
		echo "                                                        "
        	echo "========================================================"
        	echo ''
		
		if [ "$Upgrade1604HWE" = 'Y' ]
		then
			echo ''
			echo "======================================================"
			echo "Update kernel to 16.04.x HWE ...                      "
			echo "======================================================"
			echo ''

			sudo apt install --install-recommends linux-generic-hwe-16.04 xserver-xorg-hwe-16.04
			
			echo ''
			echo "======================================================"
			echo "Completed: Update kernel to 16.04.x HWE.              "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Server will reboot in 5 seconds to load new kernel... "
			echo "======================================================"
			echo ''

			sleep 5

			sudo reboot
		fi			
	fi

	if [ $UbuntuMajorRelease -ge 14 ] || [ $UbuntuDistro = 'stretch' ]
	then
		### START: New Package-Based Build and Install ###  

		if [ $UbuntuRelease = '17.10' ]
		then
			echo ''
			echo "======================================================"
			echo "Install Required Packages...                          "
			echo "======================================================"
			echo ''

			sudo apt-get install -y perl gawk multipath-tools open-iscsi build-essential checkinstall git subversion

			echo ''
			echo "======================================================"
			echo "Set alternative gcc-6/g++-6 for Ubuntu $UbuntuRelease "
			echo "======================================================"
			echo ''
			echo "======================================================"
			echo "Install gcc-6/g++-6 for Ubuntu $UbuntuRelease ...     "
			echo "======================================================"
			echo ''

			sudo apt-get install -y gcc-6 g++-6
			
			echo ''
			echo "======================================================"
			echo "Done: Install gcc-6/g++-6 for Ubuntu $UbuntuRelease   "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Create alternatives gcc/g++ Ubuntu $UbuntuRelease     "
			echo "======================================================"
			echo ''

			sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-6 10
			sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-6 10
			sudo update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-6 30
			sudo update-alternatives --set cc /usr/bin/gcc
#			sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++ 30
#			sudo update-alternatives --set c++ /usr/bin/g++
			sudo update-alternatives --config gcc
			sudo update-alternatives --config g++
			
			echo ''
			echo "======================================================"
			echo "Done: Create alternative gcc/g++ Ubuntu $UbuntuRelease"
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Show version gcc/g++ Ubuntu $UbuntuRelease ...        "
			echo "======================================================"
			echo ''

			gcc --version
			g++ --version
			
			echo ''
			echo "======================================================"
			echo "Done: Show version gcc/g++ Ubuntu $UbuntuRelease      "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Done: Set alternative v6 for Ubuntu $UbuntuRelease    "
			echo "======================================================"
			echo ''

			sleep 5

			clear
		else
			echo ''
			echo "======================================================"
			echo "Install Required Packages...                          "
			echo "======================================================"
			echo ''

			sudo apt-get install -y perl gawk multipath-tools open-iscsi build-essential checkinstall git subversion
		fi

		echo ''
		echo "======================================================"
		echo "Install Required Packages Complete.                   "
		echo "======================================================"

		sleep 5

		clear

		echo ''

		if [ "$UbuntuMajorRelease" -ge 15 ] || [ $UbuntuDistro = 'stretch' ] 
		then
			echo ''
			echo "======================================================="
			echo "Begin DKMS-enabled SCST package build and install...   "
			echo "======================================================="
			echo ''
			
			./create-scst-dkms.sh $UbuntuRelease | tee create-scst-dkms.log
			
			echo ''
			echo "======================================================="
			echo "End DKMS-enabled SCST package build and install...   "
			echo "======================================================="
		else
			echo ''
			echo "======================================================="
			echo "Begin CheckInstall SCST package build and install...   "
			echo "======================================================="
			echo ''
			echo "======================================================="
			echo "Checkinstall is created and maintained by:             "
			echo "                                                       "
			echo "Felipe Eduardo Sánchez Díaz Durán                      "
			echo "                                                       "
			echo "...and possibly other maintainers.                     "
			echo "                                                       "
			echo "Learn more at:                                         "
			echo "                                                       "
			echo "http://checkinstall.izto.org/index.php                 "
			echo "======================================================="
			echo ''
			echo "======================================================"
			echo "Some non-fatal 'failed' messages display for ib_srpt  "
			echo "during checkinstall Debian package build next steps.  "
			echo ''
			echo "If 'MODPOST 1 modules' follows then ignore them is ok."
			echo ''
			echo "See: https://sourceforge.net/p/scst/tickets/5/ info   "
			echo ''
			echo "Additional checks are done for ib_srpt as part of this"
			echo "script to ensure that build is completely successful. "
			echo "======================================================"

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Obtain SCST Source Code Trunk (svn)...                "
			echo "======================================================"
			echo ''

			sleep 5

			svn checkout svn://svn.code.sf.net/p/scst/svn/trunk scst-latest

			cd scst-latest

			function GetTrunkVersion {
				grep -R SCST_VERSION_NAME scst/include/scst_const.h | head -1 | cut -f2 -d'"' | cut -f1 -d'-'
			}
			TrunkVersion=$(GetTrunkVersion)

			cd ..

			echo ''
			echo "======================================================"
			echo "SCST Trunk Version is $TrunkVersion                   "
			echo "======================================================"
	
			sleep 5

			clear

			sudo checkinstall -D -y --pkgversion=$TrunkVersion make 2perf scst scst_install iscsi iscsi_install scstadm scstadm_install
			
			echo ''
			echo "======================================================="
			echo "End CheckInstall SCST package build and install.       "
			echo "======================================================="

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Put SCST.pm Perl Package in Perl @INC Paths...        "
			echo "======================================================"
			echo ''

			function GetPerlIncludePaths {
				perl -e "print qq(@INC)"
			}
			PerlIncludePaths=$(GetPerlIncludePaths)

			function GetSCSTPath {
				find . -name SCST.pm | grep 'scstadmin.sysfs' | head -1
			}
			SCSTPath=$(GetSCSTPath)

			for i in $PerlIncludePaths
			do
				sudo mkdir -p $i/SCST
				sudo cp -p $SCSTPath $i/SCST/.
				echo $i
				sudo ls -l $i/SCST
			done
	
			echo ''
			echo "======================================================"
			echo "Put SCST.pm Perl Package in Perl @INC Paths Complete. "
			echo "======================================================"

			sleep 5
	
			clear

			echo ''
			echo "======================================================"
			echo "Run SCST Package Postinstall Step (modprobe, etc.)... "
			echo "======================================================"
			echo ''

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

			# GLS 20170704 So that no warning/error if re-running.
			sudo iscsi-scstd >/dev/null 2>&1

			sudo service scst start

			if [ $UbuntuMajorRelease -gt 14 ]
			then
				sudo systemctl enable scst.service
				sudo systemctl daemon-reload
			fi

			echo ''
			echo "======================================================"
			echo "SCST Package Postinstall Steps Complete.              "
			echo "======================================================"

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: sudo service scst status       "
			echo "======================================================"
			echo ''

			sudo service scst status
 
			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: Done.                          "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: ps -ef | grep scst             "
			echo "======================================================"
			echo ''

			sudo ps -ef | grep scst | egrep -v 'bash|install'

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: Done.                          "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: scstadmin -list_group          "
			echo "======================================================"
			echo ''

			sudo scstadmin -list_group

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: Done.                          "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: sudo dpkg -l | grep scst       "
			echo "======================================================"
			echo ''

			sudo dpkg -l | grep scst | sed 's/  */ /g'

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: Done.                          "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: sudo modinfo scst              "
			echo "======================================================"
			echo ''

			sudo modinfo scst

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: Done.                          "
			echo "======================================================"
			echo ''

			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify ib_srpt: sudo modinfo ib_srpt                  "
			echo "======================================================"
			echo ''

			sudo modinfo ib_srpt

			echo ''
			echo "======================================================"
			echo "Verify SCST Operation: Done.                          "
			echo "======================================================"
			echo ''
	
			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "Verify SCST:~/Downloads/scst-trunk/iscsi-scst/conftest"
			echo "======================================================"
			echo ''

			sudo ls -l ~/Downloads/scst-trunk/iscsi-scst/conftest

			echo ''
			echo "======================================================"
			echo "Verify SCST Done.                                     "
			echo "======================================================"
			echo ''
		
			sleep 5

			clear

			echo ''
			echo "======================================================"
			echo "SCST Debian Package Installed.  Ready to Create SAN.  "
			echo "======================================================"
			echo 

	
			### END: New Package-Based Build and Install ###  
		fi
	else
		echo ''
		echo "======================================================="
		echo "Installing Packages ...                                "
		echo "======================================================="
		echo ''

		sudo apt-get install -y gawk
		sudo apt-get install -y multipath-tools
		sudo apt-get install -y open-iscsi
		sudo apt-get install -y gawk
		sudo apt-get install -y subversion

		echo ''
		echo "======================================================="
		echo "Installing Packages completed.                         "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Download SCST latest source code trunk...             "
		echo "======================================================="
		echo ''
               
		sleep 5
        
		svn co https://svn.code.sf.net/p/scst/svn/trunk scst-latest
		cd scst-latest
        
		echo ''
		echo "======================================================="
		echo "Download SCST latest source trunk completed.           "
		echo "======================================================="

		sleep 5

		clear

		echo ''
		echo "======================================================="
		echo "Make SCST from source...                               "
		echo "======================================================="
		echo ''

		sleep 5

		sudo make 2perf scst scst_install iscsi iscsi_install scstadm scstadm_install
		
		if [ $UbuntuMajorRelease -gt 14 ]
		then
			sudo systemctl enable scst.service
		fi

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

		if [ $UbuntuMajorRelease -gt 14 ]
		then
			sudo systemctl enable scst.service
			sudo systemctl daemon-reload
		fi

		echo ''
		echo "======================================================="
		echo "Install SCST latest version trunk completed.           "
		echo "======================================================="
	fi

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

        sleep 5

        clear

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
        sudo yum -y remove pyparsing
        sudo yum -y install perl-devel

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
        echo "Download SCST latest source code trunk...             "
        echo "======================================================="
        echo ''
               
        sleep 5
        svn co https://svn.code.sf.net/p/scst/svn/trunk scst-latest
        cd scst-latest
        
        echo ''
        echo "======================================================="
        echo "Download SCST latest source trunk completed.           "
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
        make rpm
        cd /usr/src/packages/RPMS/x86_64/
        yum -y localinstall scst*
        systemctl enable scst.service
        service scst start
        service scst status
#	cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/scst-files/scst-latest
#       make scst scst_install iscsi iscsi_install scstadm scstadm_install
        
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
#       service scst start
#       systemctl enable scst.service
        
        echo ''
        echo "======================================================="
        echo "Modprobe SCST modules and SCST setup complete.         "
        echo "======================================================="
        echo ''

        sleep 5

        clear

        echo ''
        echo "======================================================="
        echo "Install SCST version latest from RPM completed.        "
        echo "======================================================="

        sleep 5

        clear
    else
        echo ''
        echo "======================================================="
        echo "Kernel version is lower than 2.6.30. Consider Upgrade. "
        echo "Or a handler for your linux distro is not yet in.      "
        echo "======================================================="
    fi
fi
