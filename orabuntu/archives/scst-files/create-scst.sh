#!/bin/bash
# Note:		Following line shows options you can set for running create-scst-oracle.sh in this file.
#       	Set the com.yourdomain, the scstadmin groupname, the ASM redundancy, the sizes of your LUNs, and the logical blocksize in this file if you want non-default values.
#       	Review the create-scst-oracle.sh for more details and/or the README file.
#
# Example1:	create-scst-oracle.sh com.orabuntu-lxc lxc1 external 10G 30G 30G 4096
# IMPORTANT!    Remeber that if you use non-default settings for create-scst-oracle.sh BE SURE TO SPECIFY ALL OF THEM $1 through $7 !!  Otherwise they will be misinterpreted by the script.
#    Note1:     If you do not pass in a "com.yourdomain" parameter it will be set to default value of com.orabuntu-lxc
#    Note2:     If you do not pass in a "ScstGroupName"  parameter it will be set to default value of lxc1
#    Note3:     If you do not pass in a "AsmRedundancy"  parameter it will be set to default value of external
#    Note4:     If you do not pass in a "Sysd1SizeGb"    parameter it will be set to default value of 1Gb
#    Note5:     If you do not pass in a "Data1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note6:     If you do not pass in a "Reco1SizeGb"    parameter it will be set to default value of 1Gb 
#    Note7:     If you do not pass in a "LogicalBlkSiz"  parameter it will be set to default value of null (SCST by default uses 512-byte logical sector.  Optionally set this to 4096).)
#
# Network WAN connectivity is required for these scripts.  The following code tests that WAN is available so that packages can be downloaded.

clear

echo ''
echo "======================================================="
echo "Orabuntu-LXC / Uekulele SCST Installer Automation...   "
echo "======================================================="

sleep 5

clear

echo ''
echo "======================================================="
echo "Ping test...                                           "
echo "======================================================="
echo ''

ping -c 3 google.com

function CheckNetworkUp {
ping -c 3 google.com | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -lt 5 ]
do
NetworkUp=$(CheckNetworkUp)
let n=$n+1
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "======================================================="
echo "WAN is not up or is hiccuping badly.                   "
echo "ping google.com test must succeed                      "
echo "<ctrl>+c to exit script NOW                            "
echo "Script will automatically exit in 15 seconds...        "
echo "Address network issues/hiccups & rerun script.         "
echo "======================================================="
sleep 15
exit
else
echo ''
echo "======================================================="
echo "Network ping test verification complete.               "
echo "======================================================="
echo ''
fi

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

sleep 5

clear

echo ''
echo "======================================================="
echo "Check Kernel Version of running kernel...                "
echo "======================================================="
echo ''

# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.
# GLS 20160924 SCST 3.1 does not require a custom kernel build for kernels >= 2.6.30 so now we check that kernel is >= 2.6.30.
# GLS 20160924 If the kernel version is lower than 2.6.30 it will be necessary for you to compile a custom kernel.

function VersionKernelPassFail () {
    ./vercomp | cut -f1 -d':'
}
KernelPassFail=$(VersionKernelPassFail)
echo $KernelPassFail

if [ $KernelPassFail = 'Pass' ]
then
echo ''
echo "======================================================="
echo "Kernel Version Passed for SCST 3.1 Install Method.     "
echo "======================================================="

sleep 5

clear

echo ''
echo "======================================================="
echo "Check that user is root or has wheel privileges...     "
echo "======================================================="
echo ''

	if [ $LinuxFlavor = 'Red' ]
	then
		function CheckUser {
			id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
		}
		User=$(CheckUser)
		if [ $User = 'root' ]
		then
			echo 'Proceeding with install user root is valid.'
		else
			echo "======================================================="
			echo "For $LinuxFlavor SCST install linux user must be root."
			echo "Connect as root and rerun create-scst.sh script again."
			echo "======================================================="
			exit
		fi
	fi

	if [ $LinuxFlavor = 'CentOS' ]
	then
		function CheckUser {
			id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
		}
		User=$(CheckUser)
		if [ $User = 'root' ]
		then
			echo 'Proceeding with install user root is valid.'
		else
			echo "======================================================="
			echo "For $LinuxFlavor SCST install linux user must be root."
			echo "Connect as root and rerun create-scst.sh script again."
			echo "======================================================="
			exit
		fi
	fi

	if [ $LinuxFlavor = 'Ubuntu' ]
	then
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
	fi

echo "======================================================="
echo "Install user has required wheel privileges.            "
echo "======================================================="

sleep 5

clear

echo ''
echo "======================================================="
echo "Next script:  create-scst-install.sh                   "
echo "======================================================="

sleep 5

clear

./create-scst-install.sh

# Uncomment next line if you want to set variables for the Oracle SCST Linux SAN creation script. (If you uncomment the line, be sure to comment out the 'vanilla defaults ./create-oracle-scst.sh below).
# Be sure to set values for ALL parameters!
# Be sure you have enough disk space for the LUN sizes and ASM Redundancy [external|normal|high] that you have chosen!
#
# ./create-scst-oracle.sh com.orabuntu-lxc lxc1 high 50M 50M 50M 4096
#
# Otherwise if you set no parameters for create-scst-oracle.sh it will run with default settings (see notes above).
# If you want SCST for other purposes different from running an Oracle database, you can edit the create-scst-oracle.sh manually to suit your own needs (change names. lun sizes, etc.)

sleep 5

clear

echo ''
echo "======================================================="
echo "Next script:  create-scst-oracle.sh                   "
echo "======================================================="

sleep 5

clear
 
./create-scst-oracle.sh com.urdomain1 lxc1 external 10G 30G 30G

sleep 5

clear

echo ''
echo "======================================================="
echo "Next script:  create-scst-multipath.sh                   "
echo "======================================================="

sleep 5

clear
 
./create-scst-multipath.sh

fi
