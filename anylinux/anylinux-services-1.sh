#!/bin/bash
#
#    Copyright 2015-2021 Gilbert Standen
#    This file is part of Orabuntu-LXC.

#    Orabuntu-LXC is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-LXC is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Orabuntu-LXC.  If not, see <http://www.gnu.org/licenses/>.

#    v2.4 		GLS 20151224
#    v2.8 		GLS 20151231
#    v3.0 		GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 		GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 		GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta	GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)
#    v7.0-ELENA-beta    GLS 20210428 Enterprise LXD Edition New AMIDE

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC

MajorRelease=$1
PointRelease=$2
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
OSMemRes=$6
NumCon=$7
MultiHost=$8
LxcOvsVersion=$9
DistDir=${10}
Product=${11}
SubDirName=${12}
Sx1Net=${13}
Sw1Net=${14}

NameServerBase="$NameServer"-base

if [ -e /sys/hypervisor/uuid ]
then
        function CheckAWS {
                cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
        }
        AWS=$(CheckAWS)
else
        AWS=0
fi

if [ $AWS -eq 1 ]
then
	PFM=EC2
fi

# trap "exit" INT TERM; trap "kill 0" EXIT; sudo -v || exit $?; sleep 1; while true; do sleep 60; sudo -nv; done 2>/dev/null &

function GetLxcVersion {
echo $LxcOvsVersion | cut -f1 -d':'
}
LxcVersion=$(GetLxcVersion)

function GetOvsVersion {
echo $LxcOvsVersion | cut -f2 -d':'
}
OvsVersion=$(GetOvsVersion)

function GetMultiHostVar1 {
	echo $MultiHost | cut -f1 -d':'
}
MultiHostVar1=$(GetMultiHostVar1)

function GetMultiHostVar4 {
	echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

function GetMultiHostVar7 {
	echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)
MTU=$MultiHostVar7

GetLinuxFlavors(){
if   [[ -e /etc/oracle-release ]]
then
        LinuxFlavors=$(cat /etc/oracle-release | cut -f1 -d' ')
elif [[ -e /etc/redhat-release ]]
then
        LinuxFlavors=$(cat /etc/redhat-release | cut -f1 -d' ')
elif [[ -e /usr/bin/lsb_release ]]
then
        LinuxFlavors=$(lsb_release -d | awk -F ':' '{print $2}' | cut -f1 -d' ')
elif [[ -e /etc/issue ]]
then
        LinuxFlavors=$(cat /etc/issue | cut -f1 -d' ')
else
        LinuxFlavors=$(cat /proc/version | cut -f1 -d' ')
fi
}
GetLinuxFlavors

function TrimLinuxFlavors {
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//' | sed 's/\!//'
}
LinuxFlavor=$(TrimLinuxFlavors)

if   [ $LinuxFlavor = 'Oracle' ]
then
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)

	if   [ $OracleDistroRelease -eq 7 ] || [ $OracleDistroRelease -eq 6 ]
	then
		CutIndex=7
	elif [ $OracleDistroRelease -eq 8 ]
	then
		CutIndex=6
	fi

	LF=$LinuxFlavor
	LFA=$LinuxFlavor

        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)

	RHV=$RedHatVersion
        Release=$OracleDistroRelease
        RL=$Release

elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
        if   [ $LinuxFlavor = 'Red' ]
        then
                function GetRedHatVersion {
                	sudo cat /etc/redhat-release | rev | cut -f2 -d' ' | cut -f2 -d'.'
                }
                RedHatVersion=$(GetRedHatVersion)
		LF=$LinuxFlavor'Hat'
		LinuxFlavor=$LF
		LFA=$LinuxFlavor

        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
                RedHatVersion=$(GetRedHatVersion)
		LF=$LinuxFlavor
		LFA=$LinuxFlavor
        fi
        RHV=$RedHatVersion
        Release=$RedHatVersion
        RL=$Release
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
	RHV=$RedHatVersion
        if   [ $RedHatVersion -ge 28 ]
        then
                Release=8
        elif [ $RedHatVersion -ge 19 ] && [ $RedHatVersion -le 27 ]
        then
                Release=7
        elif [ $RedHatVersion -ge 12 ] && [ $RedHatVersion -le 18 ]
        then
                Release=6
        fi
        LF=$LinuxFlavor
	LFA=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Pop_OS' ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
        LF=$LinuxFlavor
	LFA=$LinuxFlavor
        RL=$UbuntuVersion
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
	Release=0
fi

echo ''
echo "=============================================="
echo "Oracle container automation.                  "
echo "=============================================="
echo ''
echo 'Author:  Gilbert Standen                      '
echo 'Email :  gilbert@orabuntu-lxc.com             '
echo ''
echo 'Motto :  Anything on Any Linux (sm)           '
echo ''
echo "=============================================="
echo "Oracle container automation.                  "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "==============================================" 
echo "Establish sudo privileges...                  "
echo "=============================================="
echo ''

echo $MultiHostVar4 | sudo -S date

echo ''
echo "==============================================" 
echo "Privileges established.                       "
echo "=============================================="

sleep 5

clear

function CheckAptProcessRunning {
        ps -ef | grep -v '_apt' | grep apt | grep -v grep | wc -l
}
AptProcessRunning=$(CheckAptProcessRunning)

while [ $AptProcessRunning -gt 0 ]
do
        echo 'Waiting for running apt update process(es) to finish...sleeping for 10 seconds'
        echo ''
        ps -ef | grep -v '_apt' | grep apt | grep -v grep
        sleep 10
        AptProcessRunning=$(CheckAptProcessRunning)
done

sleep 5

clear

echo ''
echo "==============================================" 
echo "Verify networking up...                       "
echo "=============================================="
echo ''

n=1

if [ $Release -gt 6 ] && [ $LinuxFlavor = 'Oracle' ]
then
	function CheckNetworkUp {
		ping -c 3 yum.oracle.com -4 > /dev/null 2>&1
		echo $?
	}
else
	function CheckNetworkUp {
		ping -c 3 yum.oracle.com -4 > /dev/null 2>&1
		echo $?
	}
fi

NetworkUp=$(CheckNetworkUp)
if [ "$NetworkUp" -ne 0 ]
then
        echo ''
        echo "=============================================="
        echo "yum.oracle.com ping test must succeed.        "
        echo "=============================================="

        sleep 1

        if [ $MultiHostVar1 = 'reinstall' ]
        then
		echo ''
                echo "=============================================="
                echo "Networking is not up or site is not pinging.  "
                echo "yum.oracle.com ping test must succeed.        "
                echo "Backing up:                                   "
                echo "                                              "
                echo "/etc/resolv.conf                              "
                echo "to                                            "
                echo "/etc/resolv.conf.orabuntu-lxc.reinstall.bak   "
                echo "                                              "
                echo "and attempting basic reconfiguration and      "
                echo "retrying network verification test            "
                echo "=============================================="

                sudo cp -p /etc/resolv.conf /etc/resolv.conf.orabuntu-lxc.reinstall.bak
		sudo sed -i 's/^/#/' /etc/resolv.conf
                sudo sh -c "echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"

                while [ "$NetworkUp" -ne 0 ] && [ "$n" -lt 5 ]
                do
                        NetworkUp=$(CheckNetworkUp)
                        let n=$n+1
                done
		n=1
		echo ''

		if [ $Release -gt 6 ] && [ $LinuxFlavor = 'Oracle' ]
		then
			ping -c 3 yum.oracle.com -4
		else
			ping -c 3 yum.oracle.com -4
		fi

		echo ''
		echo "=============================================="
	        echo "Network ping test verification complete.      "
		echo "=============================================="
		echo ''

        elif [ $MultiHostVar1 = 'new' ]
        then
                echo "=============================================="
                echo "yum.oracle.com ping test must succeed.        "
                echo "=============================================="
        fi
else
	if [ $Release -gt 6 ] && [ $LinuxFlavor = 'Oracle' ]
	then
		ping -c 3 yum.oracle.com -4
	else
		ping -c 3 yum.oracle.com -4
	fi
fi

sleep 5 

clear

echo ''
echo "=============================================="
echo "Check Kernel Version of running kernel...     "
echo "=============================================="
echo ''

uname -a

# GLS 20151126 Added function to get kernel version of running kernel to support linux 4.x kernels in Ubuntu Wily Werewolf etc.
# GLS 20160924 SCST 3.1 does not require a custom kernel build for kernels >= 2.6.30 so now we check that kernel is >= 2.6.30.
# GLS 20160924 If the kernel version is lower than 2.6.30 and if you use the options SCST Linux SAN archive it will be necessary to compile a custom kernel.

function VersionKernelPassFail () {
    /opt/olxc/"$DistDir"/anylinux/vercomp | cut -f1 -d':'
}
KernelPassFail=$(VersionKernelPassFail)

if [ $KernelPassFail = 'Pass' ] # $KernelPassFail = 'Pass'
then
	echo ''
	echo "=============================================="
	echo "Kernel Version is greater than 2.6.30 - Pass  "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	if [ $LinuxFlavor = 'RedHat' ] || [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Fedora' ] # $LinuxFlavor = 'Red'
	then
 		RedHatVersion=$(GetRedHatVersion)

		if [ $RedHatVersion -ge 6 ] # [ $RedHatVersion -ge 6 ]
		then
 			echo ''
			echo "=============================================="
			echo "Script:  anylinux-services-1.sh               "
			echo "=============================================="

			sleep 5
			
			clear
			
			echo ''
			echo "=============================================="
			echo "Linux OS version check...                     "
			echo "=============================================="
			echo ''
  
			if [ -f /etc/oracle-release ] # 1
			then
				cat /etc/oracle-release
			else
				cat /etc/redhat-release
			fi # OK 1

			echo ''
			echo "=============================================="
			echo "Linux OS version displayed.                   "
			echo "=============================================="
			echo ''	
			echo "=============================================="
			echo "OS Versions Compatibility Notice Begin        "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "              !!! NOTICE !!!                  "
			echo "                                              "
			echo "All OS version compatibility tests shown below"
			echo "done on NEW FRESH INSTALL physical or VM hosts"
			echo "AFTER ALL UPDATES applied and using LVM.      "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "DISTRO RELEASE	   KERNEL		    "
			echo "CentOS Linux 6	   ELREPO-4	   	    "
			echo "CentOS Linux 7	   ALL			    "
			echo "CentOS Linux 8	   ALL			    "
			echo "Fedora Linux 22-34 ALL			    "
			echo "Oracle Linux 6	   RH,UEK	    	    "
			echo "Oracle Linux 7	   RH,UEK		    "
			echo "Oracle Linux 8	   RH,UEK		    "
			echo "RedHat Linux 7	   ALL			    "
			echo "RedHat Linux 8	   ALL			    "
			echo "Ubuntu Linux 16	   ALL,AWS		    "
			echo "Ubuntu Linux 17	   ALL			    "
			echo "Ubuntu Linux 18	   ALL			    "
			echo "Ubuntu Linux 19	   ALL			    "
			echo "Ubuntu Linux 20	   ALL			    "
			echo "                                              "
			echo "Legend:                                       "
			echo "                                              "
			echo "	ALL=All Editions			    "
			echo "	AWS=Amazon Web Services EC2		    "
			echo "	UEK=Oracle Unbreakable Enterprise Kernel    "
			echo "	RH=RedHat                                   "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "OS Versions Compatibility Notice End          "
			echo "=============================================="
		
			sleep 5

			clear

			function CheckUser {
				id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
			}
			User=$(CheckUser)

			if [ $User = 'root' ] # 4
			then
				echo ''
				echo "=============================================="
				echo "Check if install user is root...              "
				echo "=============================================="
				echo ''
				echo "For $LF Linux $RHV user must be non-root user."
				echo "Connect as non-root and run scripts again.    "
				echo ''
				echo "=============================================="
				echo "Install user check completed.                 "
				echo "=============================================="
				echo ''
				exit
			fi # OK 4

			echo ''
			echo "=============================================="
			echo "Check if host is physical or virtual...       "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Facter package required for phys/VM check...  "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			function CheckFacterInstalled {
				sudo which facter > /dev/null 2>&1; echo $?
			}
			FacterInstalled=$(CheckFacterInstalled)

			if [ $FacterInstalled -ne 0 ] # 5
			then
				if [ $LinuxFlavor = 'Fedora' ] && [ $RedHatVersion -ge 28 ]
				then	
       			 		echo ''
       			 		echo "=============================================="
       			 		echo "Install Facter on $LF $RedHatVersion...       "
       			 		echo "=============================================="
       			 		echo ''

					sudo dnf -y install facter
       			 	
					echo ''
       			 		echo "=============================================="
       			 		echo "Done: Install Facter on $LF $RedHatVersion.   "
       			 		echo "=============================================="
       			 		echo ''
				else
       			 		echo ''
       			 		echo "=============================================="
       			 		echo "Install package prerequisites for facter...   "
       			 		echo "=============================================="
       			 		echo ''

					if   [ $Release -eq 8 ] && [ $LinuxFlavor != 'Fedora' ]
					then
						sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
						sudo yum -y install ruby curl tar yum-utils which facter

					elif [ $Release -eq 7 ] && [ $LinuxFlavor = 'CentOS' ]
					then
       				 		sudo yum -y install which ruby curl tar yum-utils

					else
       				 		sudo yum -y install which ruby curl tar yum-utils
					fi

					if [ $Release -le 7 ] && [ $LinuxFlavor != 'Fedora' ]
					then
						sudo yum-complete-transaction
					fi

					if [ $Release -eq 7 ] && [ $LinuxFlavor = 'Fedora' ]
					then
						sudo dnf -y install ruby facter
					fi
       	 	
					echo ''
       				 	echo "=============================================="
       				 	echo "Facter package prerequisites installed.       "
       			 		echo "=============================================="
		
					sleep 5

					clear

       				 	echo ''
       				 	echo "=============================================="
       				 	echo "Build and install Facter ...                  "
       				 	echo "=============================================="
       				 	echo ''

					sleep 5

					if [ $RedHatVersion -eq 8 ]
					then
						if [ $LinuxFlavor = 'Oracle' ]
						then
							sudo yum -y install facter ruby curl tar yum-utils which

						elif [ $LinuxFlavor = 'Red' ]
						then
							sudo yum -y install ruby curl tar yum-utils which
							curl -s --ipv4 http://downloads.puppetlabs.com/facter/facter-2.4.4.tar.gz | sudo tar xz; sudo ruby facter*/install.rb
						fi
					else
       				 		echo ''
       				 		echo "=============================================="
       				 		echo "Build and install Facter (Ruby Method)...     "
       				 		echo "=============================================="
       				 		echo ''

						sleep 5

						mkdir -p /opt/olxc/"$DistDir"/uekulele/facter
						cd /opt/olxc/"$DistDir"/uekulele/facter
						curl -s --ipv4 http://downloads.puppetlabs.com/facter/facter-2.4.4.tar.gz | sudo tar xz; sudo ruby facter*/install.rb
       				 		
						echo ''
       				 		echo "=============================================="
       				 		echo "Done: Build and install Facter (Ruby Method). "
       				 		echo "=============================================="
       				 		echo ''

						sleep 5

						clear
					fi

					echo ''
       				 	echo "=============================================="
       				 	echo "Build and install Facter completed.           "
       				 	echo "=============================================="
				fi
			else
			 	echo ''
       	 			echo "=============================================="
       			 	echo "Facter already installed.                     "
       	 			echo "=============================================="
       			 	echo ''

			fi # OK 5

			if   [ $Release -gt 7 ] && [ $LinuxFlavor = 'Oracle' ]
			then
				function GetFacter {
					facter --no-ruby virtual
				}
			elif [ $Release -ge 8 ] && [ $LinuxFlavor = 'Fedora' ]
			then
				function GetFacter {
					facter --no-ruby virtual
				}
			else
				function GetFacter {
					facter virtual
				}
			fi
			Facter=$(GetFacter)

			sleep 2

			clear

			sudo yum -y     install net-tools > /dev/null 2>&1
			sudo apt-get -y install net-tools > /dev/null 2>&1

			if [ $Facter != 'physical' ] # 6
			then
				if   [ $Release -eq 7 ] || [ $Release -eq 8 ]
				then
					function GetVirtualInterfaces {
						sudo ifconfig | grep enp | cut -f1 -d':' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
					}

				elif [ $Release -eq 6 ]
				then
					function GetVirtualInterfaces {
						sudo ifconfig | grep eth | cut -f1 -d':' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
					}
				fi

				VirtualInterfaces=$(GetVirtualInterfaces)

				for i in $VirtualInterfaces
				do
					function CheckIpOnVirtualInterface1 {
						sudo ifconfig $i | grep 10.207.39 | wc -l
					}
					IpOnVirtualInterface1=$(CheckIpOnVirtualInterface1)

					function CheckIpOnVirtualInterface2 {
						sudo ifconfig $i | grep 10.207.29 | wc -l
					}
					IpOnVirtualInterface2=$(CheckIpOnVirtualInterface2)

					sudo mkdir -p /etc/network/openvswitch

					if [ $IpOnVirtualInterface1 -eq 1 ] || [ -f /etc/network/openvswitch/sw1.info ]
					then
						function GetIpVirtualInterface1 {
							sudo ifconfig $i | grep inet | grep 10.207.39 | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f2 -d' '
						}
						IpVirtualInterface1=$(GetIpVirtualInterface1)
						
						if [ ! -f /etc/network/openvswitch/sw1.info ]
						then
							sudo sh -c "echo '$i:$IpVirtualInterface1:Y' > /etc/network/openvswitch/sw1.info"
						fi
					fi
	
					if [ $IpOnVirtualInterface2 -eq 1 ] || [ -f /etc/network/openvswitch/sx1.info ]
					then
						function GetIpVirtualInterface2 {
							sudo ifconfig $i | grep inet | grep 10.207.29 | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f2 -d' '
						}
						IpVirtualInterface2=$(GetIpVirtualInterface2)
						
						if [ ! -f /etc/network/openvswitch/sx1.info ]
						then
							sudo sh -c "echo '$i:$IpVirtualInterface2:Y' > /etc/network/openvswitch/sx1.info"
						fi
					fi
				done

				sleep 5

 				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC $LFA Linux $RHV on $Facter $PFM. "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				if [ -f /etc/orabuntu-lxc-release ] # 7
				then
#					echo ''
#					echo "=============================================="
#					echo "                                              "
#					echo "If you already have an Orabuntu-LXC install   "
#					echo "on this host and just want to add more        "
#					echo "containers then answer 'Y' to this.           "
#					echo "                                              "
#					echo "If you are doing a complete Orabuntu-LXC      "
#					echo "reinstall then answer 'N' to this.            "
#					echo "                                              "
#					echo "=============================================="
#					echo "                                              " 
#				read -e -p   "Adding Orabuntu-LXC containers? [Y/N]         " -i "N" CloningAdditional
#					echo "                                              "
#					echo "=============================================="
#					
#					sleep 5
#	
#					clear

					if [ $MultiHostVar1 = 'addrelease' ]
					then
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 8

					if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ] # 8
					then
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $LxcOvsVersion $DistDir $Sx1Net $Sw1Net
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 8

					if [ $MultiHostVar1 = 'addclones' ] # 9
					then
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 9
				fi # OK 7

				if [ ! -f /etc/orabuntu-lxc-release ] # 10
				then
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $LxcOvsVersion $DistDir $Sx1Net $Sw1Net
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
 					/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
				fi # OK 10

 				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC for $LFA Linux $RHV complete.    "
				echo "=============================================="
	
				sleep 5

 			else # OK 6

				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC $LFA Linux $RHV on $Facter $PFM. " 
				echo "=============================================="
				echo ''

				sleep 5

				clear

				if [ -f /etc/orabuntu-lxc-release ] # 11
				then
#					echo ''
#					echo "=============================================="
#					echo "                                              "
#					echo "If you already have an Orabuntu-LXC install   "
#					echo "on this host and just want to add more        "
#					echo "containers then answer 'Y' to this.           "
#					echo "                                              "
#					echo "If you are doing a complete Orabuntu-LXC      "
#					echo "reinstall then answer 'N' to this.            "
#					echo "                                              "
#					echo "=============================================="
#					echo "                                              " 
#				read -e -p   "Adding Orabuntu-LXC containers? [Y/N]  " -i "N" CloningAdditional
#					echo "                                              "
#					echo "=============================================="
#					echo ''
#
#					sleep 5
#
#					clear

					if [ $MultiHostVar1 = 'addrelease' ]
					then
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir 
					fi # OK 8

					if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ] # 8
					then
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $LxcOvsVersion $DistDir $Sx1Net $Sw1Net
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
 						/opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 8

					if [ $MultiHostVar1 = 'addclones' ] # 9
					then
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 9
				fi # OK 11
		
				if [ ! -f /etc/orabuntu-lxc-release ] # 14
				then
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $LxcOvsVersion $DistDir $Sx1Net $Sw1Net
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-3.sh $MajorRelease $PointRelease $Domain2 $MultiHost $DistDir $Product
 					/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
					/opt/olxc/"$DistDir"/uekulele/uekulele-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
				fi # OK 14

				sleep 5

				clear
			
				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC for $LFA Linux $RHV complete.    "
				echo "=============================================="

			fi # OK 6

 		fi # [ $RedHatVersion -ge 6 ]

	fi # $LinuxFlavor = 'RedHat'

	if [ $LinuxFlavor = 'Ubuntu' ] || [ $LinuxFlavor = 'Pop_OS' ] # $LinuxFlavor = 'Ubuntu'
	then
		function GetUbuntuVersion {
		cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
		}
		UbuntuVersion=$(GetUbuntuVersion)

		function GetUbuntuMajorVersion {
			cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
		}
		UbuntuMajorVersion=$(GetUbuntuMajorVersion)

		if [ $UbuntuMajorVersion -ge 15 ] # $UbuntuMajorVersion -ge 15
		then
 			echo ''
			echo "=============================================="
			echo "Script:  anylinux-services-1.sh               "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Ubuntu Release Version Check....              "
			echo "=============================================="
			echo ''

			sudo cat /etc/lsb-release # 1 OK 1

			echo ''
			echo "=============================================="
			echo "Linux OS version displayed.                   "
			echo "=============================================="
			echo ''	
			echo "=============================================="
			echo "OS Versions Compatibility Notice Begin        "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "              !!! NOTICE !!!                  "
			echo "                                              "
			echo "All OS version compatibility tests shown below"
			echo "done on NEW FRESH INSTALL physical or VM hosts"
			echo "AFTER ALL UPDATES applied and using LVM.      "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "DISTRO RELEASE	   KERNEL		    "
			echo "CentOS Linux 6	   ELREPO-4	   	    "
			echo "CentOS Linux 7	   ALL			    "
			echo "CentOS Linux 8	   ALL			    "
			echo "Fedora Linux 22-34 ALL			    "
			echo "Oracle Linux 6	   RH,UEK	    	    "
			echo "Oracle Linux 7	   RH,UEK		    "
			echo "Oracle Linux 8	   RH,UEK		    "
			echo "RedHat Linux 7	   ALL			    "
			echo "RedHat Linux 8	   ALL			    "
			echo "Ubuntu Linux 16	   ALL,AWS		    "
			echo "Ubuntu Linux 17	   ALL			    "
			echo "Ubuntu Linux 18	   ALL			    "
			echo "Ubuntu Linux 19	   ALL			    "
			echo "Ubuntu Linux 20	   ALL			    "
			echo "                                              "
			echo "Legend:                                       "
			echo "                                              "
			echo "	ALL=All Editions			    "
			echo "	AWS=Amazon Web Services EC2		    "
			echo "	UEK=Oracle Unbreakable Enterprise Kernel    "
			echo "	RH=RedHat                                   "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "OS Versions Compatibility Notice End          "
			echo "=============================================="
	
			sleep 5

			clear

			function CheckUser {
				id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
			}
			User=$(CheckUser)

			if [ $User = 'root' ] # 4
			then
				echo ''
				echo "=============================================="
				echo "Check if install user is root...              "
				echo "=============================================="
				echo ''
				echo "For $LF Linux $RHV user must be non-root user."
				echo "Connect as non-root and run scripts again.    "
				echo ''
				echo "=============================================="
				echo "Install user check completed.                 "
				echo "=============================================="
				echo ''
				exit

			fi # OK 4

			echo ''
			echo "=============================================="
			echo "Check if host is physical or virtual...       "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Facter package required for phys/VM check...  "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			function CheckFacterInstalled {
				sudo which facter > /dev/null 2>&1; echo $?
			}
			FacterInstalled=$(CheckFacterInstalled)

			if [ $FacterInstalled -ne 0 ] # 5
			then
       				echo ''
       				echo "=============================================="
       				echo "Install facter package...                     "
       				echo "=============================================="
       				echo ''

       	 			sudo apt-get -o Acquire::ForceIPv4=true update
				sudo apt-get -o Acquire::ForceIPv4=true -y install facter

				echo ''
       			 	echo "=============================================="
       			 	echo "Done:  Install facter package.                "
       			 	echo "=============================================="
				
				sleep 5

				clear
			else
       			 	echo ''
       			 	echo "=============================================="
       			 	echo "Facter already installed.                     "
       			 	echo "=============================================="
       			 	echo ''

				sleep 5

				clear

			fi # OK 5
       
	                if [ $UbuntuMajorVersion -ge 18 ]
                        then
                                function GetFacter {
                                        facter virtual --log-level=none
                                }
                                Facter=$(GetFacter)
                        else
                                function GetFacter {
                                        facter virtual
                                }
                                Facter=$(GetFacter)
                        fi

			if [ $Facter != 'physical' ] # 6
			then
				function GetVirtualInterfaces {
					sudo ifconfig | grep enp | cut -f1 -d':' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
				}
				VirtualInterfaces=$(GetVirtualInterfaces)

				for i in $VirtualInterfaces
				do
					function CheckIpOnVirtualInterface1 {
						sudo ifconfig $i | grep 10.207.39 | wc -l
					}
					IpOnVirtualInterface1=$(CheckIpOnVirtualInterface1)

					function CheckIpOnVirtualInterface2 {
						sudo ifconfig $i | grep 10.207.29 | wc -l
					}
					IpOnVirtualInterface2=$(CheckIpOnVirtualInterface2)

					sudo mkdir -p /etc/network/openvswitch

					if [ $IpOnVirtualInterface1 -eq 1 ] || [ -f /etc/network/openvswitch/sw1.info ]
					then
						function GetIpVirtualInterface1 {
							sudo ifconfig $i | grep inet | grep 10.207.39 | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f2 -d' '
						}
						IpVirtualInterface1=$(GetIpVirtualInterface1)
						
						if [ ! -f /etc/network/openvswitch/sw1.info ]
						then
							sudo sh -c "echo '$i:$IpVirtualInterface1:Y' > /etc/network/openvswitch/sw1.info"
						fi
					fi
	
					if [ $IpOnVirtualInterface2 -eq 1 ] || [ -f /etc/network/openvswitch/sx1.info ]
					then
						function GetIpVirtualInterface2 {
							sudo ifconfig $i | grep inet | grep 10.207.29 | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f2 -d' '
						}
						IpVirtualInterface2=$(GetIpVirtualInterface2)
						
						if [ ! -f /etc/network/openvswitch/sx1.info ]
						then
							sudo sh -c "echo '$i:$IpVirtualInterface2:Y' > /etc/network/openvswitch/sx1.info"
						fi
					fi
				done

 				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC $LFA Linux $RL on $Facter $PFM.  "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				if [ -f /etc/orabuntu-lxc-release ] # 7
				then
#					echo ''
#					echo "=============================================="
#					echo "                                              "
#					echo "If you already have an Orabuntu-LXC install   "
#					echo "on this host and just want to add more        "
#					echo "containers then answer 'Y' to this.           "
#					echo "                                              "
#					echo "If you are doing a complete Orabuntu-LXC      "
#					echo "reinstall then answer 'N' to this.            "
#					echo "                                              "
#					echo "=============================================="
#					echo "                                              "
#					echo "=============================================="
#					echo "                                              " 
#				read -e -p   "Adding Orabuntu-LXC containers? [Y/N]  " -i "N" CloningAdditional
#					echo "                                              "
#					echo "=============================================="
#				
#					sleep 5
#
#					clear

					if [ $MultiHostVar1 = 'addrelease' ]
					then	
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $NameServer $DistDir
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-3.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi

					if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ] # 8
					then
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $DistDir $Sx1Net $Sw1Net
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $NameServer $DistDir
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-3.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 8

					if [ $MultiHostVar1 = 'addclones' ] # 9
					then
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 9

				fi # OK 7
		
				if [ ! -f /etc/orabuntu-lxc-release ] # 10
				then
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $DistDir $Sx1Net $Sw1Net
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $NameServer $DistDir
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-3.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $DistDir $Product
 					/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
				fi # OK 10

				clear

 				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC $LFA Linux $RL complete.         "
				echo "=============================================="
	
				sleep 5

 			else # OK 6

				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC $LFA Linux $RL on $Facter $PFM.  "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				if [ -f /etc/orabuntu-lxc-release ] # 11
				then
#					echo ''
#					echo "=============================================="
#					echo "                                              "
#					echo "If you already have an Orabuntu-LXC install   "
#					echo "on this host and just want to add more        "
#					echo "containers then answer 'Y' to this.           "
#					echo "                                              "
#					echo "If you are doing a complete Orabuntu-LXC      "
#					echo "reinstall then answer 'N' to this.            "
#					echo "                                              "
#					echo "=============================================="
#					echo "                                              "
#					echo "=============================================="
#					echo "                                              " 
#				read -e -p   "Adding Orabuntu-LXC containers? [Y/N]  " -i "N" CloningAdditional
#					echo "                                              "
#					echo "=============================================="
#				
#					sleep 5
#
#					clear

					if [ $MultiHostVar1 = 'addrelease' ]
					then	
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $NameServer $DistDir
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-3.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi

					if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ] # 12
					then
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $DistDir $Sx1Net $Sw1Net
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $NameServer $DistDir
 						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-3.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $DistDir $Product
 						/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 12

					if [ $MultiHostVar1 = 'addclones' ] # 13
					then
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
						/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
					fi # OK 13

				fi # OK 11
		
				if [ ! -f /etc/orabuntu-lxc-release ] # 14
				then
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-1.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServerBase $OSMemRes $MultiHost $DistDir $Sx1Net $Sw1Net
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-2.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $NameServer $DistDir
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-3.sh $MajorRelease $PointRelease $Domain1 $Domain2 $MultiHost $DistDir $Product
 					/opt/olxc/"$DistDir"/products/$Product/$Product $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $OSMemRes $MultiHost $LxcOvsVersion $DistDir $SubDirName
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-4.sh $MajorRelease $PointRelease $NumCon $NameServer $MultiHost $DistDir $Product
					/opt/olxc/"$DistDir"/orabuntu/orabuntu-services-5.sh $MajorRelease $PointRelease $Domain1 $Domain2 $NameServer $MultiHost $DistDir
				fi # OK 14

				sleep 5

				clear
			
				echo ''
				echo "=============================================="
				echo "Orabuntu-LXC for $LFA Linux $RL complete.     "
				echo "=============================================="
	
				sleep 5

			fi # OK 6

 		fi # $UbuntuMajorVersion -ge 15

	fi # $LinuxFlavor = 'Ubuntu'

fi # OK $KernelPassFail = 'Pass'
