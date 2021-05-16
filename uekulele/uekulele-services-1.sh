#/bin/bash

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

clear

MajorRelease=$1
PointRelease=$2
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
OSMemRes=$6
MultiHost=$7
LxcOvsVersion=$8
DistDir=$9
Sx1Net=${10}
Sw1Net=${11}

# function CheckFacterValue {
#         facter --no-ruby virtual
# }
# FacterValue=$(CheckFacterValue)

if [ -e /sys/hypervisor/uuid ]
then
        function CheckAWS {
                cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
        }
        AWS=$(CheckAWS)
else
        AWS=0
fi

function GetNameServerBase {
        echo $NameServer | cut -f1 -d'-'
}
NameServerBase=$(GetNameServerBase)

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

function GetLxcVersion {
	echo $LxcOvsVersion | cut -f1 -d':'
}
LxcVersion=$(GetLxcVersion)

function GetOvsVersion {
	echo $LxcOvsVersion | cut -f2 -d':'
}
OvsVersion=$(GetOvsVersion)

# MultiHost for reference
# MultiHost="$Operation:Y:X:X:$HUBIP:$SPOKEIP:$MTU:$HubUserAct:$HubSudoPwd:$GRE:$Product:$LXD:$K8S:$PreSeed:$LXDCluster:$StorageDriver:$StoragePoolName:$BtrfsLun"

function GetMultiHostVar1 {
	echo $MultiHost | cut -f1 -d':'
}
MultiHostVar1=$(GetMultiHostVar1)

function GetMultiHostVar2 {
	echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

function GetMultiHostVar3 {
	echo $MultiHost | cut -f3 -d':'
}
MultiHostVar3=$(GetMultiHostVar3)

function GetMultiHostVar4 {
	echo $MultiHost | cut -f4 -d':'
}
MultiHostVar4=$(GetMultiHostVar4)

function GetMultiHostVar5 {
	echo $MultiHost | cut -f5 -d':'
}
MultiHostVar5=$(GetMultiHostVar5)

function GetMultiHostVar6 {
	echo $MultiHost | cut -f6 -d':'
}
MultiHostVar6=$(GetMultiHostVar6)

function GetMultiHostVar7 {
	echo $MultiHost | cut -f7 -d':'
}
MultiHostVar7=$(GetMultiHostVar7)

function GetMultiHostVar8 {
	echo $MultiHost | cut -f8 -d':'
}
MultiHostVar8=$(GetMultiHostVar8)

function GetMultiHostVar9 {
	echo $MultiHost | cut -f9 -d':'
}
MultiHostVar9=$(GetMultiHostVar9)

function GetMultiHostVar10 {
	echo $MultiHost | cut -f10 -d':'
}
MultiHostVar10=$(GetMultiHostVar10)
GRE=$MultiHostVar10
GREValue=$MultiHostVar10

function GetMultiHostVar11 {
        echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)

function GetMultiHostVar12 {
        echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)
LXDValue=$MultiHostVar12
LXD=$LXDValue

function GetMultiHostVar13 {
        echo $MultiHost | cut -f13 -d':'
}
MultiHostVar13=$(GetMultiHostVar13)
K8S=$MultiHostVar13

function GetMultiHostVar14 {
        echo $MultiHost | cut -f14 -d':'
}
MultiHostVar14=$(GetMultiHostVar14)
PreSeed=$MultiHostVar14

function GetMultiHostVar15 {
        echo $MultiHost | cut -f15 -d':'
}
MultiHostVar15=$(GetMultiHostVar15)
LXDCluster=$MultiHostVar15

function GetMultiHostVar16 {
        echo $MultiHost | cut -f16 -d':'
}
MultiHostVar16=$(GetMultiHostVar16)
LXDStorageDriver=$MultiHostVar16

function GetMultiHostVar17 {
        echo $MultiHost | cut -f17 -d':'
}
MultiHostVar17=$(GetMultiHostVar17)
StoragePoolName=$MultiHostVar17

function GetMultiHostVar18 {
        echo $MultiHost | cut -f18 -d':'
}
MultiHostVar18=$(GetMultiHostVar18)
BtrfsLun=$MultiHostVar18

function GetMultiHostVar19 {
        echo $MultiHost | cut -f19 -d':'
}
MultiHostVar19=$(GetMultiHostVar19)
Docker=$MultiHostVar19

function GetMultiHostVar20 {
        echo $MultiHost | cut -f20 -d':'
}
MultiHostVar20=$(GetMultiHostVar20)
TunType=$MultiHostVar20

function CheckSystemdResolvedInstalled {
        sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

function CheckNetworkManagerRunning {
	ps -ef | grep NetworkManager | grep -v grep | wc -l
}
NetworkManagerRunning=$(CheckNetworkManagerRunning)

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
echo $LinuxFlavors | sed 's/^[ \t]//;s/[ \t]$//'
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
         
	function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
	
	function GetRedHatMinorVersion {
		sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f2 -d'.'
	}

        RedHatVersion=$(GetRedHatVersion)
	RedHatMinorVersion=$(GetRedHatMinorVersion)
	RHV=$RedHatVersion
	RHMV=$RedHatMinorVersion
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
elif [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ]
then
	if   [ $LinuxFlavor = 'Red' ]
        then
                function GetRedHatVersion {
                        sudo cat /etc/redhat-release | rev | cut -f2 -d' ' | cut -f2 -d'.'
                }
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
        fi
	RedHatVersion=$(GetRedHatVersion)
	RHV=$RedHatVersion
        Release=$RedHatVersion
        LF=$LinuxFlavor
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
        RL=$Release
elif [ $LinuxFlavor = 'Ubuntu' ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
        LF=$LinuxFlavor
        RL=$UbuntuVersion
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

function GetOperation {
echo $MultiHost | cut -f1 -d':'
}
Operation=$(GetOperation)

if   [ $Release -ge 7 ]
then
	function CheckLxcNetRunning {
		sudo systemctl | grep lxc-net | grep 'loaded active exited' | wc -l
	}
	LxcNetRunning=$(CheckLxcNetRunning)

elif [ $Release -eq 6 ]
then
	function CheckLxcNetRunning {
		sudo chkconfig | grep lxc-net | grep -c on
	}
	LxcNetRunning=$(CheckLxcNetRunning)
fi

echo ''
echo "=============================================="
echo "Script: uekulele-services-1.sh                "
echo "=============================================="

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

if [ $Release -ge 7 ]
then
	echo ''
	echo "=============================================="
	echo "Performance settings for sshd_config.         "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "These make the install of Orabuntu-LXC faster."
	echo "You can change these back after install or    "
	echo "leave them at the new settings shown below.   "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Orabuntu-LXC has made a backup of sshd_config "
	echo "located in the /etc/ssh directory if you want "
	echo "to revert sshd_config to original settings    "
	echo "after Orabuntu-LXC install is completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	sudo cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.olxc
	sudo sed -i '/GSSAPIAuthentication/s/yes/no/'	/etc/ssh/sshd_config
	sudo sed -i '/UseDNS/s/yes/no/'			/etc/ssh/sshd_config
	sudo sed -i '/GSSAPIAuthentication/s/#//'	/etc/ssh/sshd_config
	sudo sed -i '/UseDNS/s/#//'			/etc/ssh/sshd_config
	sudo egrep 'GSSAPIAuthentication|UseDNS'	/etc/ssh/sshd_config | sort -u

	echo ''
	echo "=============================================="
	echo "Done: edit sshd_config.                       "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Restart sshd...                               "
	echo "=============================================="
	echo ''

	sudo service sshd restart

	echo ''
	echo "=============================================="
	echo "Done: Restart sshd.                           "
	echo "=============================================="

	sleep 5

	clear
fi

if [ -f /etc/orabuntu-lxc-release ] 
then
	which lxc-ls > /dev/null 2>&1
	if [ $? -eq 0 ] && [ $Operation = 'reinstall' ]
	then
		echo ''
		echo "=============================================="
		echo "Orabuntu-LXC Reinstall delete lxc & reboot... "
		echo "=============================================="
		echo '' 
		echo "=============================================="
		echo "Re-run anylinux-services.sh after reboot...   "
		echo "=============================================="
		echo ''

		sudo /etc/orabuntu-lxc-scripts/stop_containers.sh

		if [ -d /var/lib/lxc ]
		then
			function CheckContainersExist {
				sudo ls /var/lib/lxc | more | sed 's/$/ /' | tr -d '\n' | sed 's/  */ /g'
			}
			ContainersExist=$(CheckContainersExist)

			echo "=============================================="
			read -e -p   "Delete All LXC  Containers? [ Y/N ]   " -i "Y" DestroyAllContainers
			echo "=============================================="
			echo ''

			if [ $DestroyAllContainers = 'Y' ] || [ $DestroyContainers = 'y' ]
			then
				DestroyContainers=$(CheckContainersExist)
				for j in $DestroyContainers
				do
					if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 6 ]
					then
						sudo lxc-stop -n $j -k
					else
						sudo lxc-stop -n $j
					fi
					sleep 2
					sudo lxc-destroy -n $j -f -s
					sudo rm -rf /var/lib/lxc/$j
				done

				echo ''
				echo "=============================================="
				echo "Destruction of Containers complete            "
				echo "=============================================="
			else
				echo "=============================================="
				echo "Destruction of Containers not executed.       "
				echo "=============================================="
			fi
		fi

		echo ''
		echo "=============================================="
		echo "Delete OpenvSwitch bridges...                 "
		echo "=============================================="
		echo ''

		sudo /etc/network/openvswitch/del-bridges.sh >/dev/null 2>&1
		sudo ovs-vsctl show

		echo ''
		echo "=============================================="
		echo "Done: Delete OpenvSwitch bridges.             "
		echo "=============================================="
		echo ''

                sudo rm -f  /etc/network/if-up.d/openvswitch/*
                sudo rm -f  /etc/network/if-down.d/openvswitch/*

                sudo systemctl disable sw4 > /dev/null 2>&1
                sudo systemctl disable sw5 > /dev/null 2>&1
                sudo systemctl disable sw6 > /dev/null 2>&1
                sudo systemctl disable sw7 > /dev/null 2>&1
                sudo systemctl disable sw8 > /dev/null 2>&1
                sudo systemctl disable sw9 > /dev/null 2>&1
                sudo systemctl disable sx1 > /dev/null 2>&1
                sudo systemctl disable $NameServer > /dev/null 2>&1

                sudo rm -f /etc/network/openvswitch/crt_ovs_sw4.sh
                sudo rm -f /etc/network/openvswitch/crt_ovs_sw5.sh
                sudo rm -f /etc/network/openvswitch/crt_ovs_sw6.sh
                sudo rm -f /etc/network/openvswitch/crt_ovs_sw7.sh
                sudo rm -f /etc/network/openvswitch/crt_ovs_sw8.sh
                sudo rm -f /etc/network/openvswitch/crt_ovs_sw9.sh
                sudo rm -f /etc/network/openvswitch/crt_ovs_sx1.sh

                sudo rm -f /etc/systemd/system/ora*c*.service
                sudo rm -f /etc/systemd/system/oel*c*.service
                sudo rm -f /etc/network/openvswitch/strt_ora*c*.sh
                sudo rm -f /etc/network/if-up.d/openvswitch/*
                sudo rm -f /etc/network/if-down.d/openvswitch/*
                sudo rm -f /etc/systemd/system/sw[456789].service
                sudo rm -f /etc/systemd/system/sx1.service
                sudo rm -f /etc/systemd/system/$NameServer.service

                sudo ip link del a1 > /dev/null 2>&1
                sudo ip link del a2 > /dev/null 2>&1
                sudo ip link del a3 > /dev/null 2>&1
                sudo ip link del a4 > /dev/null 2>&1
                sudo ip link del a5 > /dev/null 2>&1
                sudo ip link del a6 > /dev/null 2>&1

		# GLS 20170925 Oracle Linux OVS and LXC are built from source.    This step deletes the source build directories.
		# GLS 20170925 Ubuntu Linux OVS and LXC are build from packages.  This step is not necessary on Ubuntu Linux.
		# GLS 20180206 begin uekulele branch only.

			cd /opt/olxc/"$DistDir"/uekulele
			sudo rm -rf facter openvswitch lxc selinux
	
			if [ $LinuxFlavor != 'Fedora' ]
			then
				sudo rm -rf epel
			fi

			sudo rm -f /etc/orabuntu-lxc-release

			echo "=============================================="
			echo "Remove dns=none parameter from NM conf...     "
			echo "=============================================="

			sudo sed -i '/dns=none/d' /etc/NetworkManager/NetworkManager.conf
			sudo systemctl daemon-reload

			echo ''
			echo "=============================================="
			echo "Done Remove dns=none parameter from NM conf.  "
			echo "=============================================="
			echo ''

		# GLS 20180206 end uekulele branch only.
		
		echo "=============================================="
		echo "Uninstall lxc packages...                     "
		echo "=============================================="
		echo ''

		sudo systemctl disable dnsmasq

                function CheckYumProcessRunning {
                        ps -ef | grep yum | grep -v grep | wc -l
                }
                AptProcessRunning=$(CheckAptProcessRunning)

                while [ $YumProcessRunning -gt 0 ]
                do
                        echo 'Waiting for running yum update process(es) to finish...sleeping for 10 seconds'
                        echo ''
                        ps -ef | grep yum | grep -v grep
                        sleep 10
                        AptProcessRunning=$(CheckAptProcessRunning)
                done

		sudo yum -y erase lxc lxc-libs dnsmasq
		sudo rm -f /etc/sysconfig/lxc-net	> /dev/null 2>&1
		sudo rm -f /etc/dnsmasq.conf		> /dev/null 2>&1

		echo ''
		echo "=============================================="
		echo "Uninstall lxc packages completed.             "
		echo "=============================================="

		echo ''	
		echo "=============================================="
		echo "Rebooting to clear bridge lxcbr0...           "
		echo "=============================================="
		echo '' 
		echo "=============================================="
		echo "Re-run anylinux-services.sh after reboot...   "
		echo "=============================================="

		sleep 5
	
		sudo reboot
		exit
	fi

	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''

	if [ -f /etc/dnsmasq.conf ]
	then
		sudo mv /etc/dnsmasq.conf /etc/dnsmasq.olxc.1
	fi
	sudo yum clean all

	sudo yum -y install wget tar gzip libtool libvirt
	
	if [ $Release -eq 6 ]
	then
		if [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'CentOS' ]
		then
                        sudo yum -y install lxc libcgroup libcap-devel
	
			echo ''
			echo "=============================================="
			echo "Done: Install LXC and prerequisite packages.  "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Verify cgconfig service running...            "
			echo "=============================================="
			echo ''

			function CheckCgconfigRunning {
				sudo service cgconfig status
			}
			CgconfigRunning=$(CheckCgconfigRunning)

			if [ $CgconfigRunning != 'Running' ]
			then
				sudo service cgconfig start
			else
				echo Service cgconfig status:  $CgconfigRunning
			fi

                        sudo chkconfig cgconfig on

			echo ''
			echo "=============================================="
			echo "Done: Verify cgconfig service running.        "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Configure memory.use.hierarchy...             "
			echo "=============================================="
			echo ''

			# GLS 20180403 Credit: Dwight Engen (dwengen) https://github.com/lxc/lxc/issues/345

                        function CheckMemoryUseHierarchy {
                                grep -c memory.use_hierarchy /etc/cgconfig.conf
                        }
                        MemoryUseHierarchy=$(CheckMemoryUseHierarchy)

                        if [ $MemoryUseHierarchy -eq 0 ]
                        then
                                sudo sh -c "echo 'group . {'                    >> /etc/cgconfig.conf"
                                sudo sh -c "echo 'memory {'                     >> /etc/cgconfig.conf"
                                sudo sh -c "echo 'memory.use_hierarchy = "1";'  >> /etc/cgconfig.conf"
                                sudo sh -c "echo '}'                            >> /etc/cgconfig.conf"
                                sudo sh -c "echo '}'                            >> /etc/cgconfig.conf"
                        fi

			cat /etc/cgconfig.conf

			echo ''
			echo "=============================================="
			echo "Done: Configure memory.use.hierarchy.         "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Build cgroupfs service...                     "
			echo "=============================================="
			echo ''

			# GLS 20180403 Credit: Tianon Gravi (tianon) https://github.com/tianon/cgroupfs-mount
			# GLS 20180403 Credit: Gilbert Standen (gstanden) forked and added support for Oracle Linux 6 and similar.

                        if [ ! -d /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6 ]
                        then
                                sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6
                                sudo chown -R $Owner:$Group /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6
                                cd /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6
				wget https://github.com/gstanden/cgroupfs-mount/archive/linux6.zip
                                unzip linux6.zip
                        fi
			
			echo ''
			echo "=============================================="
			echo "Done: Build  cgroupfs service.                "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Verify cgroupfs service running...            "
			echo "=============================================="
			echo ''

                        function CheckCgroupfsInstalled {
                                sudo chkconfig --list | grep -c cgroupfs
                        }
                        CgroupfsInstalled=$(CheckCgroupfsInstalled)

                        if [ $CgroupfsInstalled -eq 0 ]
                        then
                                cd /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6/cgroupfs-mount-linux6
                                chmod 755 install-linux-6.sh
				echo ''
                                ./install-linux-6.sh
                                sudo service cgroupfs start
				sudo service cgroupfs status
			else
                                sudo service cgroupfs restart
				sudo service cgroupfs status
                        fi
			
			echo ''
			echo "=============================================="
			echo "Done: Verify cgroupfs service running.        "
			echo "=============================================="

			sleep 5

			clear
		
			if [ $LinuxFlavor = 'CentOS' ]
			then
				echo ''
				echo "=============================================="
				echo "Activate overlayfs (modprobe) ...            "
				echo "=============================================="
				echo ''

				sudo modprobe overlay
				sudo cat /proc/filesystems | grep overlay

				echo ''
				echo "=============================================="
				echo "Done: Activate overlayfs (modprobe).          "
				echo "=============================================="
			fi
		fi
	fi

	if [ $LinuxFlavor != 'Fedora' ] && [ $Release -le 7 ]
	then
		DocBook2XInstalled=0
		m=1

		while [ $DocBook2XInstalled -eq 0 ] && [ $m -le 5 ]
		do
			echo ''
			echo "=============================================="
			echo 'Install epel repo...                          '
			echo "=============================================="
			echo ''

                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel

                        if   [ $Release -eq 7 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                                sudo rpm -ivh epel-release-latest-7.noarch.rpm

                        elif [ $Release -eq 6 ]
                        then
				sudo yum -y install openjade texinfo perl-XML-SAX
                                sudo rpm -ivh "$DistDir"/rpmstage/docbook2x-0.8.8-1.el6.rf.x86_64.rpm
                                sudo rpm -ivh "$DistDir"/rpmstage/sshpass-1.05-1.el6.rf.x86_64.rpm
			#	wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
			#	sudo rpm -ivh epel-release-latest-6.noarch.rpm
                        fi

                        sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
                        sudo yum -y install docbook2X

			function CheckDocBook2XInstalled {
				rpm -qa | grep -ic docbook2X
			}
			DocBook2XInstalled=$(CheckDocBook2XInstalled)

			if   [ $DocBook2XInstalled -gt 0 ]
			then
				echo ''
				echo "=============================================="
				echo "Done: Install epel repo.                      "
				echo "=============================================="
				echo ''

			elif [ $Release -eq 8 ]
			then
				DocBook2XInstalled=1

			elif [ $DocBook2XInstalled -eq 0 ]
				then
				echo ''
				echo "=============================================="
				echo "epel failure ... retrying epel install...     "
				echo "=============================================="
				echo ''
			fi
			m=$((m+1))
	        done
 	else
 			echo ''
 			echo "=============================================="
 			echo 'Install epel repo...                          '
 			echo "=============================================="
 			echo ''
 
                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel
 
                        if   [ $Release -eq 8 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
                                sudo rpm -ivh epel-release-latest-8.noarch.rpm
 			fi
	fi


	cd /opt/olxc/"$DistDir"

	sudo yum -y install perl bash-completion

	if [ $Release -le 7 ]
	then
		sudo yum -y install debootstrap bash-completion-extras bridge-utils docbook2X lxc
		sudo yum -y install lxc libcap-devel libcgroup wget bridge-utils 
	fi

	if   [ $Release -eq 6 ]
	then
		if [ $LinuxFlavor != 'CentOS' ]
		then
			sudo yum -y install lsb
		fi

	elif [ $Release -ge 7 ]
	then
		sudo yum -y install lsb
	fi

	if [ $LinuxFlavor = 'Fedora' ]
	then
		sudo dnf -y install lxc lxc-* debootstrap qemu-kvm libvirt virt-install bridge-utils perl gpg

	elif [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Red' ]
	then
		sudo yum -y install qemu-kvm libvirt virt-install bridge-utils
	fi

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Start LXC and libvirt...                      "
	echo "=============================================="
	echo ''

	if [ $Release -ge 7 ] 
	then
		sudo systemctl daemon-reload

		if [ $Release -eq 7 ]
		then
			sudo systemctl start lxc.service
			sudo systemctl status lxc.service
			echo ''
		fi

		sudo setenforce permissive
		sudo systemctl start libvirtd
		sleep 2
		sudo systemctl stop libvirtd
		sleep 2
		sudo systemctl start libvirtd
		sudo systemctl status libvirtd
		sleep 2
		sudo cp -p /etc/lxc/default.conf /etc/lxc/default.conf.bak

	elif [ $Release -eq 6 ]
	then
#		sudo service lxc start
		echo ''
		sudo chkconfig --list | grep lxc
		echo ''
		sudo setenforce permissive
		sudo service libvirtd start
		echo ''
		sudo service libvirtd status
	fi

	echo ''
	echo "=============================================="
	echo "Done: Start LXC and libvirt.                  "
	echo "=============================================="
	echo ''

	if [ $Release -le 7 ]
	then
		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Run LXC Checkconfig...                        "
		echo "=============================================="
		echo ''

		sleep 5

		sudo lxc-checkconfig

		echo "=============================================="
		echo "LXC Checkconfig completed.                    "
		echo "=============================================="
		echo ''
		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Display LXC Version...                        "
		echo "=============================================="
		echo ''

		sudo lxc-create --version

		echo ''
		echo "=============================================="
		echo "LXC version displayed.                        "
		echo "=============================================="
		echo ''
	
		sleep 5

		clear
	fi
fi

# GLS 20170919 Oracle Linux Specific Code Block 1 END

# GLS 20170919 Oracle Linux Specific Code Block 2 BEGIN

if [ ! -f /etc/orabuntu-lxc-release ]
then
	echo ''
	echo "=============================================="
	echo "Install LXC and prerequisite packages...      "
	echo "=============================================="
	echo ''

	if [ -f /etc/dnsmasq.conf ]
	then
		sudo mv /etc/dnsmasq.conf /etc/dnsmasq.olxc.1
	fi
	sudo yum -y install wget tar gzip libtool libvirt
	
	if [ $Release -eq 6 ]
	then
		if [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'CentOS' ]
		then
                        sudo yum -y install lxc libcgroup libcap-devel
	
			echo ''
			echo "=============================================="
			echo "Done: Install LXC and prerequisite packages.  "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Verify cgconfig service running...            "
			echo "=============================================="
			echo ''

			function CheckCgconfigRunning {
				sudo service cgconfig status
			}
			CgconfigRunning=$(CheckCgconfigRunning)

			if [ $CgconfigRunning != 'Running' ]
			then
				sudo service cgconfig start
			else
				echo Service cgconfig status:  $CgconfigRunning
			fi

			echo ''
			echo "=============================================="
			echo "Done: Verify cgconfig service running.        "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Configure memory.use.hierarchy...             "
			echo "=============================================="
			echo ''

			# GLS 20180403 Credit: Dwight Engen (dwengen) https://github.com/lxc/lxc/issues/345

                        function CheckMemoryUseHierarchy {
                                grep -c memory.use_hierarchy /etc/cgconfig.conf
                        }
                        MemoryUseHierarchy=$(CheckMemoryUseHierarchy)

                        if [ $MemoryUseHierarchy -eq 0 ]
                        then
                                sudo sh -c "echo 'group . {'                    >> /etc/cgconfig.conf"
                                sudo sh -c "echo 'memory {'                     >> /etc/cgconfig.conf"
                                sudo sh -c "echo 'memory.use_hierarchy = "1";'  >> /etc/cgconfig.conf"
                                sudo sh -c "echo '}'                            >> /etc/cgconfig.conf"
                                sudo sh -c "echo '}'                            >> /etc/cgconfig.conf"
                        fi

			cat /etc/cgconfig.conf

			echo ''
			echo "=============================================="
			echo "Done: Configure memory.use.hierarchy.         "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Build cgroupfs service...                     "
			echo "=============================================="
			echo ''

			# GLS 20180403 Credit: Gilbert Standen (gstanden) forked and added support for Oracle Linux 6 and similar.
			# GLS 20180403 Forked and added support for Oracle Linux 6 and similar.

                        if [ ! -d /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6 ]
                        then
                                sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6
                                sudo chown -R $Owner:$Group /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6
                                cd /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6
				wget https://github.com/gstanden/cgroupfs-mount/archive/linux6.zip
                                unzip linux6.zip
                        fi
			
			echo ''
			echo "=============================================="
			echo "Done: Build  cgroupfs service.                "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Verify cgroupfs service running...            "
			echo "=============================================="
			echo ''

                        function CheckCgroupfsInstalled {
                                sudo chkconfig --list | grep -c cgroupfs
                        }
                        CgroupfsInstalled=$(CheckCgroupfsInstalled)

                        if [ $CgroupfsInstalled -eq 0 ]
                        then
                                cd /opt/olxc/"$DistDir"/uekulele/cgroupfs-linux6/cgroupfs-mount-linux6
                                chmod 755 install-linux-6.sh
                                ./install-linux-6.sh
                                sudo service cgroupfs start
				sudo service cgroupfs status
                        fi
			
			echo ''
			echo "=============================================="
			echo "Done: Verify cgroupfs service running.        "
			echo "=============================================="

			sleep 5

			clear
		
			if [ $LinuxFlavor = 'CentOS' ]
			then
				echo ''
				echo "=============================================="
				echo "Activate overlayfs (modprobe) ...            "
				echo "=============================================="
				echo ''

				sudo modprobe overlay
				sudo cat /proc/filesystems | grep overlay

				echo ''
				echo "=============================================="
				echo "Done: Activate overlayfs (modprobe).          "
				echo "=============================================="
				echo ''
			fi
		fi
	fi

	if [ $LinuxFlavor != 'Fedora' ] && [ $Release -le 7 ]
	then
		DocBook2XInstalled=0
		m=1

		while [ $DocBook2XInstalled -eq 0 ] && [ $m -le 5 ]
		do
			echo ''
			echo "=============================================="
			echo 'Install epel repo...                          '
			echo "=============================================="
			echo ''

                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel

                        if   [ $Release -eq 7 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
                                sudo rpm -ivh epel-release-latest-7.noarch.rpm

                        elif [ $Release -eq 6 ]
                        then
				sudo yum -y install openjade texinfo perl-XML-SAX
                                sudo rpm -ivh "$DistDir"/rpmstage/docbook2x-0.8.8-1.el6.rf.x86_64.rpm
                                sudo rpm -ivh "$DistDir"/rpmstage/sshpass-1.05-1.el6.rf.x86_64.rpm
			#	wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
			#	sudo rpm -ivh epel-release-latest-6.noarch.rpm
                        fi

                        sudo yum provides lxc | sed '/^\s*$/d' | grep Repo | sort -u
                        sudo yum -y install docbook2X

			function CheckDocBook2XInstalled {
				rpm -qa | grep -ic docbook2X
			}
			DocBook2XInstalled=$(CheckDocBook2XInstalled)

			if   [ $DocBook2XInstalled -gt 0 ]
			then
				echo ''
				echo "=============================================="
				echo "Done: Install epel repo.                      "
				echo "=============================================="
				echo ''

			elif [ $DocBook2XInstalled -eq 0 ]
				then
				echo ''
				echo "=============================================="
				echo "epel failure ... retrying epel install...     "
				echo "=============================================="
				echo ''
			fi
			m=$((m+1))
	        done
 	else
 			echo ''
 			echo "=============================================="
 			echo 'Install epel repo...                          '
 			echo "=============================================="
 			echo ''
 
                        sudo yum -y install wget
                        sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/epel
                        sudo chown -R $Owner:$Group /opt/olxc
                        cd /opt/olxc/"$DistDir"/uekulele/epel
 
                        if   [ $Release -eq 8 ]
                        then
                                wget --timeout=5 --tries=10 https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
                                sudo rpm -ivh epel-release-latest-8.noarch.rpm
 		fi
	fi

	cd /opt/olxc/"$DistDir"

	sudo yum -y install perl bash-completion

	if [ $Release -le 7 ]
	then
		sudo yum -y install debootstrap bash-completion-extras bridge-utils docbook2X lxc
		sudo yum -y install lxc libcap-devel libcgroup wget bridge-utils 
	fi

	if [ $LinuxFlavor = 'Fedora' ] && [ $Release -ge 7 ]
	then
		sudo dnf -y install lxc lxc-* lxc-extra debootstrap libvirt perl gpg
		
		if [ $Release -eq 8 ]
		then
			sudo systemctl enable dnsmasq
			sudo systemctl start  dnsmasq
			sudo sed -i 's/#LXC/LXC/g'				/etc/sysconfig/lxc-net 
			sudo sed -i 's/LXC_DHCP_CONFILE/#LXC_DHCP_CONFILE/g'	/etc/sysconfig/lxc-net
			sudo sed -i 's/LXC_DOMAIN/#LXC_DOMAIN/g'		/etc/sysconfig/lxc-net
			sudo systemctl enable lxc-net
			sudo systemctl start  lxc-net
			sudo service lxc-net stop
			sudo service lxc-net start
		#	sudo firewall-cmd --permanent --zone=trusted --add-interface=lxcbr0
		#	sudo firewall-cmd --permanent --zone=trusted --add-masquerade
			sudo firewall-cmd --reload
		fi
	fi

	echo ''
	echo "=============================================="
	echo "LXC and prerequisite packages completed.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Start LXC and libvirt...                      "
	echo "=============================================="
	echo ''

        if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Red' ]
        then
		echo "=============================================="
		echo "Install required packages...                  "
		echo "=============================================="
		echo ''

                sudo dnf -y install lxc lxc-* libcap-devel libcgroup wget
		
		echo ''
		echo "=============================================="
		echo "Done: Install required packages.              "
		echo "=============================================="
		echo ''

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "Enable and Start LXC...                       "
		echo "=============================================="
		echo ''

		sudo systemctl enable lxc
		sudo systemctl start  lxc

		echo ''
		echo "=============================================="
		echo "Done: Enable and Start LXC.                   "
		echo "=============================================="
		echo ''
        fi

        if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Oracle' ]
        then
		echo "=============================================="
		echo "Install required packages...                  "
		echo "=============================================="
		echo ''

		sudo yum -y install libcgroup rsync wget libcap-devel
                sudo dnf -y install lxc lxc-* 
		
		echo ''
		echo "=============================================="
		echo "Done: Install required packages.              "
		echo "=============================================="
		echo ''

		sleep 5

		clear
        fi

	if [ $Release -ge 7 ] 
	then
		echo ''
		echo "=============================================="
		echo "Enable and Start LXC and Libvirt...           "
		echo "=============================================="
		echo ''

		sudo systemctl daemon-reload
		sudo systemctl enable lxc
		echo ''
		sudo systemctl start  lxc
		sudo systemctl status lxc

		
		sudo setenforce permissive
		sudo systemctl enable libvirtd
		echo ''
		sudo systemctl start  libvirtd
		sudo systemctl status libvirtd
		
		sudo cp -p /etc/lxc/default.conf /etc/lxc/default.conf.bak

		echo ''
		echo "=============================================="
		echo "Done: Enable and Start LXC and Libvirt.       "
		echo "=============================================="
		echo ''

		sleep 5

		clear

	elif [ $Release -eq 6 ]
	then
		echo ''
		echo "=============================================="
		echo "Enable and Start LXC and Libvirt...           "
		echo "=============================================="
		echo ''

 		sudo service lxc start
		echo ''
		sudo chkconfig --list | grep lxc
		echo ''
		sudo service lxc status
		echo ''
		sudo setenforce permissive
		sudo service libvirtd start
		echo ''
		sudo service libvirtd status

		echo ''
		echo "=============================================="
		echo "Done: Enable and Start LXC and Libvirt.       "
		echo "=============================================="
		echo ''

		sleep 5

		clear
	fi

	echo ''
	echo "=============================================="
	echo "Done: Start LXC and libvirt                   "
	echo "=============================================="

	sleep 5

	clear

	if [ $Release -le 7 ]
	then

	echo ''
	echo "=============================================="
	echo "Run LXC Checkconfig...                        "
	echo "=============================================="
	echo ''

	sleep 5

	sudo lxc-checkconfig

	echo ''
	echo "=============================================="
	echo "LXC Checkconfig completed.                    "
	echo "=============================================="
	echo ''
		
	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Display LXC Version...                        "
	echo "=============================================="
	echo ''

	sudo lxc-create --version

	echo ''
	echo "=============================================="
	echo "LXC version displayed.                        "
	echo "=============================================="
	echo ''

	fi
fi
	
sleep 5

clear

# GLS 20170927 credit yairchu 
function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

if [ $Release -le 7 ]
then
	function GetLXCVersion {
        	lxc-create --version
	}
	LXCVersion=$(GetLXCVersion)
else
	LXCVersion=0.1.0
fi

if [ $Release -ge 8 ]
then
	function GetLXCVersion {
        	lxc-create --version
	}
	LXCVersion=$(GetLXCVersion)
fi

if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion $LxcVersion) ]
then
	echo ''
	echo "=============================================="
	echo "Done: Install required LXC package.           "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Upgrade LXC from Source on $LF Linux $RHV     "
	echo "=============================================="

	sleep 5
	
	clear

	if [ $Release -le 7 ]
	then
		function GetLXCVersion {
        		lxc-create --version
		}
		LXCVersion=$(GetLXCVersion)
	else
		LXCVersion=0.1.0
	fi

#	echo 'LXCVersion = '$LXCVersion #debug only
#	echo 'LxcVersion = '$LxcVersion #debug only

	while [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion $LxcVersion) ]
	do
		if [ $Release -ge 7 ]
		then

			if [ $LinuxFlavor = 'Red' ] && [ $Release -eq 7 ]
			then
				echo ''
				echo "=============================================="
				echo "Enable Required Repos (give it a minute)...   "
				echo "=============================================="
				echo ''

				sudo subscription-manager repos --enable rhel-7-server-optional-rpms
				
				echo ''
				echo "=============================================="
				echo "Done: Enable Required Repos.                  "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				echo ''
				echo "=============================================="
				echo "Install packages...                           "
				echo "=============================================="
				echo ''

				sudo yum -y install unbound-devel

				echo ''
				echo "=============================================="
				echo "Done: Install packages.                       "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

			echo ''
			echo "=============================================="
			echo "Install required packages and prepare...      "
			echo "=============================================="
			echo ''

			sleep 5

			sudo touch /etc/rpm/macros

			if [ $Release -ge 8 ]
			then
				if [ $LinuxFlavor = 'Oracle' ]
				then
					echo ''
					echo "=============================================="
					echo "Enable Required Repos...                      "
					echo "=============================================="
					echo ''

					sudo yum-config-manager --enable ol8_codeready_builder
					sudo yum-config-manager --enable ol8_appstream
					sudo yum-config-manager --enable ol8_u0_baseos_base
					sudo yum-config-manager --enable ol8_baseos_latest
				 	sudo yum-config-manager --enable ol8_addons
				
					echo ''
					echo "=============================================="
					echo "Done: Enable Required Repos.                  "
					echo "=============================================="
					echo ''

				elif [ $LinuxFlavor = 'CentOS' ]
				then
					sudo yum config-manager --set-enabled powertools
				fi
			fi

			echo ''
			echo "=============================================="
			echo "Install packages...                           "
			echo "=============================================="
			echo ''

			sudo yum -y install rpm-build wget openssl-devel gcc make docbook2X xmlto automake graphviz libtool

			echo ''
			echo "=============================================="
			echo "Done: Install packages.                       "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			if [ $Release -ge 8 ]
			then
				echo ''
				echo "=============================================="
				echo "Install packages...                           "
				echo "=============================================="
				echo ''
					if [ $LinuxFlavor = 'CentOS' ]
					then
						sudo dnf -y install openjade texinfo perl-XML-SAX docbook2X libcap-devel libcgroup
						sudo rpm -ivh "$DistDir"/rpmstage/bridge-utils-1.5-9.el7.x86_64.rpm
					else
						sudo rpm -ivh "$DistDir"/rpmstage/bridge-utils-1.5-9.el7.x86_64.rpm
						sudo yum -y install libcap-devel
					fi
				echo ''
				echo "=============================================="
				echo "Done: Install packages.                       "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc
			sudo chown -R $Owner:$Group /opt/olxc
			cd /opt/olxc/"$DistDir"/uekulele/lxc
			
			echo ''
			echo "=============================================="
			echo "Done: Install required packages and prepare.  "
			echo "=============================================="

			sleep 5

			clear

			if [ $(SoftwareVersion $LxcVersion) -ge $(SoftwareVersion "3.0.0") ] && [ $(SoftwareVersion $LxcVersion) -le $(SoftwareVersion "3.0.4") ]
			then
				echo ''
				echo "=============================================="
				echo "Build and Install lxc-templates RPM ...       "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				echo ''
				echo "=============================================="
				echo "Install packages...                           "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y install automake gcc make rpmdevtools git

				echo ''
				echo "=============================================="
				echo "Done: Install packages.                       "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc-templates
				sudo chown -R $Owner:$Group /opt/olxc
				cd /opt/olxc/"$DistDir"/uekulele/lxc-templates

				echo ''
				echo "=============================================="
				echo "Get Source Code...                            "
				echo "=============================================="
				echo ''

				wget --timeout=5 --tries=10 https://linuxcontainers.org/downloads/lxc/lxc-templates-"$LxcVersion".tar.gz -4

				echo ''
				echo "=============================================="
				echo "Done: Get Source Code.                        "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc-templates/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
				sudo chown -R $Owner:$Group /opt/olxc/"$DistDir"/uekulele/lxc-templates/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
				cp -p lxc-templates-"$LxcVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/lxc-templates/rpmbuild/SOURCES/.
			
				echo ''
				echo "=============================================="
				echo "Untar lxc-templates source...                 "
				echo "=============================================="
				echo ''

				sleep 5

				tar -zxvf lxc-templates-"$LxcVersion".tar.gz
			
				echo ''
				echo "=============================================="
				echo "Done: Untar lxc-templates source.             "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				cp -p "$DistDir"/uekulele/archives/lxc-templates.spec /opt/olxc/"$DistDir"/uekulele/lxc-templates/.
				sudo sed -i "s/LxcVersion/$LxcVersion/" /opt/olxc/"$DistDir"/uekulele/lxc-templates/lxc-templates.spec
				
				echo ''
				echo "=============================================="
				echo "Build lxc-templates RPM...                      "
				echo "=============================================="
				echo ''

				sleep 5
	
				rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/lxc-templates/rpmbuild" -ba lxc-templates.spec
				
				echo ''
				echo "=============================================="
				echo "Done: Build lxc-templates RPM.                "
				echo "=============================================="
				echo ''
	
				sleep 5

				clear
			
				echo ''
				echo "=============================================="
				echo "Remove current lxc version...                 "
				echo "=============================================="
				echo ''
	
				sudo yum -y remove lxc-libs* lxc*	
			
				echo ''
				echo "=============================================="
				echo "Done: Remove current lxc version.             "
				echo "=============================================="
				echo ''

				sleep 5

				clear
	
				echo ''
				echo "=============================================="
				echo "Install lxc-templates RPM...                  "
				echo "=============================================="
				echo ''

				sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/lxc-templates/rpmbuild/RPMS/x86_64/lxc-templates*.rpm
				
				echo ''
				echo "=============================================="
				echo "Done: Install lxc-templates RPM.              "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi
			
			echo ''
			echo "=============================================="
			echo "Ping linuxcontainers.org...                   "
			echo "=============================================="
			echo ''
	
			ping -c 5 linuxcontainers.org -4
			echo ''
			
			echo ''
			echo "=============================================="
			echo "Done: Ping linuxcontainers.org.               "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Get LXC source code...                        "
			echo "=============================================="
			echo ''

			wget --timeout=5 --tries=10 https://linuxcontainers.org/downloads/lxc/lxc-"$LxcVersion".tar.gz -4

			echo ''
			echo "=============================================="
			echo "Done: Get LXC source code.                    "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Untar LXC source code...                      "
			echo "=============================================="
			echo ''

			sleep 5

			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			sudo chown -R $Owner:$Group /opt/olxc/
			cp -p lxc-"$LxcVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/SOURCES/.
			tar -zxvf lxc-"$LxcVersion".tar.gz
			cp -p lxc-"$LxcVersion"/lxc.spec /opt/olxc/"$DistDir"/uekulele/lxc/.

			echo ''
			echo "=============================================="
			echo "Done: Untar LXC source code.                  "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Edits to lxc.spec file (if needed)...         "
			echo "=============================================="
			echo ''

			echo 'Edits to the lxc.spec file go here if needed.'

			cd /opt/olxc/"$DistDir"/uekulele/lxc

			function CheckMacrosFile {
				cat /etc/rpm/macros | grep _unpackaged_files_terminate_build | sort -u | grep -c 0
			}
			MacrosFile=$(CheckMacrosFile)

			if [ $MacrosFile -eq 0 ]
			then
				sudo sh -c "echo '%_unpackaged_files_terminate_build 0' >> /etc/rpm/macros"
			fi
				
			if [ $(SoftwareVersion $LxcVersion) -lt $(SoftwareVersion "3.0.0") ]
			then
				sed -i '/find %{buildroot} -type f -name/a install -m 755 -d $RPM_BUILD_ROOT%{_sysconfdir}/sysconfig'		/opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
				sed -i '/find %{buildroot} -type f -name/a install -m 755 -d $RPM_BUILD_ROOT%{_sysconfdir}/bash_completion.d'	/opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
				sudo sed -i '/sysconfig/s/\*//'											/opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			fi
			
			if [ $(SoftwareVersion $LxcVersion) -ge $(SoftwareVersion "3.0.0") ] && [ $(SoftwareVersion $LxcVersion) -le $(SoftwareVersion "3.0.4") ]
			then
				sudo sed -i 's/_smp_mflags\}/_smp_mflags\} CFLAGS=\"-fPIC\"/' /opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
				sudo sed -i '/^\%prep/i \%define debug_package \%\{nil\}'     /opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			fi

			echo ''
			echo "=============================================="
			echo "Done: Edits to lxc.spec file (if needed).     "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			if [ $Release -eq 7 ]
			then
				if [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'Red' ]
				then
					echo ''
					echo "=============================================="
					echo "Untar LXC source code...                      "
					echo "=============================================="
					echo ''

					sleep 5

					cd /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/SOURCES
					tar -xvf lxc-"$LxcVersion".tar.gz
				
					echo ''
					echo "=============================================="
					echo "Untar LXC source code...                      "
					echo "=============================================="
					echo ''

					sleep 5

					clear

					echo ''
					echo "=============================================="
					echo "Configure LXC source build...                 "
					echo "=============================================="
					echo ''

					sleep 5

					cd lxc-"$LxcVersion"
					./configure
	
					echo ''
					echo "=============================================="
					echo "Configure LXC source build...                 "
					echo "=============================================="
					echo ''

					sleep 5

					clear

					echo ''
					echo "=============================================="
					echo "Build LXC RPM...                              "
					echo "=============================================="
					echo ''

					sleep 5

					make rpm

					echo ''
					echo "=============================================="
					echo "Build LXC RPM...                              "
					echo "=============================================="
					echo ''

					sleep 5

					clear
				fi
			else
				rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild" -ba lxc.spec
			fi

			echo ''
			echo "=============================================="
			echo "Done: Untar source code and build LXC RPM     "
			echo "=============================================="
		
			sleep 5

			clear
	
			echo ''
			echo "=============================================="
			echo "Install LXC RPM's...                          "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 7 ]
			then
				echo ''
				echo "=============================================="
				echo "Remove Previous Version LXC RPM's...          "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y remove lxc-1.0.11* lxc-libs*
				
				echo ''
				echo "=============================================="
				echo "Done: Remove Previous Version LXC RPM's.      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi
				
			if [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'Fedora' ]
			then
				echo ''
				echo "=============================================="
				echo "Remove Previous Version LXC RPM's...          "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y erase lxc* lxc-libs*
				
				echo ''
				echo "=============================================="
				echo "Done: Remove Previous Version LXC RPM's.      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

			if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 8 ]
			then
				echo ''
				echo "=============================================="
				echo "Remove Previous Version LXC RPM's...          "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y erase lxc* lxc-libs*
				
				echo ''
				echo "=============================================="
				echo "Done: Remove Previous Version LXC RPM's.      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

			if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 7 ]
			then
				echo ''
				echo "=============================================="
				echo "Remove Previous Version LXC RPM's...          "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y remove lxc-libs-1.1.5*
				
				echo ''
				echo "=============================================="
				echo "Done: Remove Previous Version LXC RPM's.      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

			if [ $LinuxFlavor = 'Red' ] && [ $Release -eq 7 ]
			then
				echo ''
				echo "=============================================="
				echo "Remove Previous Version LXC RPM's...          "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y remove lxc* lxc-debuginfo*
				
				echo ''
				echo "=============================================="
				echo "Done: Remove Previous Version LXC RPM's.      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

                        if [ $LinuxFlavor = 'Oracle' ] && [ $Release -ge 8 ]
                        then
				echo ''
				echo "=============================================="
				echo "Install packages...                           "
				echo "=============================================="
				echo ''

				sleep 5

                                sudo yum - y install libcgroup rsync
				
				echo ''
				echo "=============================================="
				echo "Install packages...                           "
				echo "=============================================="
				echo ''

				sleep 5

				clear
				
				echo ''
				echo "=============================================="
				echo "Remove Previous Version LXC RPM's...          "
				echo "=============================================="
				echo ''

				sleep 5

				sudo yum -y remove lxc-libs* lxc* lxc-*
				sudo rpm -ivh lxc* 
				
				echo ''
				echo "=============================================="
				echo "Done: Remove Previous Version LXC RPM's.      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
                        fi

			sleep 5
		
			if [ $Release -eq 7 ]
			then
				if [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'Red' ]
				then
					echo ''
					echo "=============================================="
					echo "Install LXC RPM's...                          "
					echo "=============================================="
					echo ''

					sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/lxc-*.rpm
				
					echo ''
					echo "=============================================="
					echo "Done: Install LXC RPM's.                      "
					echo "=============================================="
					echo ''

					sleep 5

					clear
				fi
			else
				echo ''
				echo "=============================================="
				echo "Install LXC RPM's...                          "
				echo "=============================================="
				echo ''

				cd /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/RPMS/x86_64
				sudo rpm -ivh *.rpm
				
				echo ''
				echo "=============================================="
				echo "Done: Install LXC RPM's.                      "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi

			cd /opt/olxc/"$DistDir"/uekulele/lxc
			
			echo ''
			echo "=============================================="
			echo "Enable and Start LXC...                       "
			echo "=============================================="
			echo ''

			sudo systemctl daemon-reload
			sudo systemctl enable lxc
			echo ''
			sudo systemctl start  lxc
			sudo systemctl status lxc

			echo ''
			echo "=============================================="
			echo "Done: Enable and Start LXC.                   "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Done: Install LXC RPM's.                      "
			echo "=============================================="

			sleep 5

			clear
		fi
		if [ $Release -eq 6 ] 
		then
			echo ''
			echo "=============================================="
			echo "Build LXC for Linux Release $Release...       "
			echo "=============================================="
			echo ''

			sleep 5

			clear
			
			echo ''
			echo "=============================================="
			echo "Remove LXC Previous Version...                "
			echo "=============================================="
			echo ''

			sleep 5
			
			sudo yum -y remove lxc-libs-1.1.5*
			sudo yum -y remove lxc-libs*
			
			echo ''
			echo "=============================================="
			echo "Done: Remove LXC Previous Version.            "
			echo "=============================================="
			echo ''

			sleep 5

			clear
			
			sudo mkdir /opt/olxc/"$DistDir"/uekulele/lxc
			sudo chown -R $Owner:$Group /opt/olxc/"$DistDir"/uekulele/lxc
			cd /opt/olxc/"$DistDir"/uekulele/lxc
	
			sudo touch /etc/rpm/macros
			
			echo ''
			echo "=============================================="
			echo "Install Required Packages...                  "
			echo "=============================================="
			echo ''

			sleep 5
			
			sudo yum -y install rpm-build wget openssl-devel gcc make docbook2X xmlto automake graphviz libtool
			
			echo ''
			echo "=============================================="
			echo "Done: Install Required Packages.              "
			echo "=============================================="
			echo ''

			sleep 5

			clear
			
			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc
			sudo chown -R $Owner:$Group /opt/olxc
			
			echo ''
			echo "=============================================="
			echo "Get LXC Source Code...                        "
			echo "=============================================="
			echo ''

			wget --timeout=5 --tries=10 https://linuxcontainers.org/downloads/lxc/lxc-"$LxcVersion".tar.gz -4
			
			echo ''
			echo "=============================================="
			echo "Done: Get LXC Source Code.                    "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			sudo chown -R $Owner:$Group /opt/olxc
			cp -p lxc-"$LxcVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/SOURCES/.
			
			echo ''
			echo "=============================================="
			echo "Untar LXC Source Code...                      "
			echo "=============================================="
			echo ''

			sleep 5

			tar -zxvf lxc-"$LxcVersion".tar.gz
			
			echo ''
			echo "=============================================="
			echo "Done: Untar LXC Source Code.                  "
			echo "=============================================="
			echo ''
			
			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Edits to lxc.spec (if needed)...              "
			echo "=============================================="
			echo ''

			cp -p lxc-"$LxcVersion"/lxc.spec /opt/olxc/"$DistDir"/uekulele/lxc/.
			sed -i '/find %{buildroot} -type f -name/a install -m 755 -d $RPM_BUILD_ROOT%{_libexecdir}/%{name}/lxc-apparmor-load'   /opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			sed -i "/%build/a CFLAGS='-include /usr/include/linux/types.h'"                                                         /opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			sed -i '/sysconfig/s/noreplace/missingok, noreplace/'									/opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			sed -i '/bash_completion.d/s/^/%config(missingok) /'									/opt/olxc/"$DistDir"/uekulele/lxc/lxc.spec
			cd /opt/olxc/"$DistDir"/uekulele/lxc

			sleep 5

			clear

			function CheckMacrosFile {
				cat /etc/rpm/macros | grep _unpackaged_files_terminate_build | sort -u | grep -c 0
			}
			MacrosFile=$(CheckMacrosFile)

			if [ $MacrosFile -eq 0 ]
			then
				sudo sh -c "echo '%_unpackaged_files_terminate_build 0' >> /etc/rpm/macros"
			fi

			DESTDIR="/opt/olxc/$DistDir/uekulele/lxc/rpmbuild"
			sudo perl -p -i -e 's#^(\s*libfile=")(\$libdir/)#$1\$DESTDIR$2#' 			/usr/bin/libtool
			sudo perl -p -i -e 's#^(\s*if test "X\$destdir" = "X)(\$libdir")#$1\$DESTDIR$2#' 	/usr/bin/libtool

			echo ''
			echo "=============================================="
			echo "Build LXC RPM's...                            "
			echo "=============================================="
			echo ''

			sleep 5

			rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild" -ba lxc.spec

			echo ''
			echo "=============================================="
			echo "Done: Build LXC RPM's.                        "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Remove Previous LXC Version...                "
			echo "=============================================="
			echo ''

			sleep 5

			sudo yum -y remove lxc-libs*
			
			echo ''
			echo "=============================================="
			echo "Done: Remove Previous LXC Version.            "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Install LXC RPM's...                          "
			echo "=============================================="
			echo ''

			cd /opt/olxc/"$DistDir"/uekulele/lxc/rpmbuild/RPMS/x86_64
			sudo rpm -ivh lxc*

			echo ''
			echo "=============================================="
			echo "Done: Install LXC RPM's.                      "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			export LD_LIBRARY_PATH=''
			cd /opt/olxc/"$DistDir"/uekulele/lxc
		fi
	
		function GetLXCVersion {
        		lxc-create --version
		}
		LXCVersion=$(GetLXCVersion)
	done
	
	if [ $Release -ge 7 ]
	then
		echo ''
		echo "=============================================="
		echo "LXC RPMs built on $LF Linux $RHV.             "
		echo "=============================================="
	fi

	sleep 5

	clear

	if [ $Release -eq 6 ]
	then
		echo ''
		echo "=============================================="
		echo "LXC RPMs built on $LF Linux $RHV.             " 
		echo "=============================================="

		sleep 5

		clear
	fi

	echo ''
	echo "=============================================="
	echo "Run LXC Checkconfig...                        "
	echo "=============================================="
	echo ''

	sleep 5

	sudo lxc-checkconfig

	echo ''
	echo "=============================================="
	echo "LXC Checkconfig completed.                    "
	echo "=============================================="

	sleep 5

	clear

 	echo ''
 	echo "=============================================="
	echo "Display AUX Bridge(s) for LXC (non-OvS)...    "
 	echo "=============================================="
 	echo ''

 	sleep 5

	sudo service libvirtd start 	> /dev/null 2>&1
	sudo ifconfig virbr0 		> /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		sudo sed -i "s/lxcbr0/virbr0/g" /etc/lxc/default.conf
		sudo ifconfig virbr0
	fi

	sudo ifconfig lxcbr0 		> /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		sudo ifconfig lxcbr0
	fi

 	echo "=============================================="
	echo "Done: Display AUX Bridge(s) for LXC (non-OvS)."
 	echo "=============================================="

 	sleep 5

 	clear

	echo ''
	echo "=============================================="
	echo "Upgrade LXC from Source complete.             "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	clear
	echo ''
	echo "=============================================="
	echo "Display LXC Version...                        "
	echo "=============================================="
	echo ''

	sudo lxc-create --version

	echo ''
	echo "=============================================="
	echo "LXC version displayed.                        "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Display AUX Bridge(s) for LXC (non-OvS)...    "
echo "=============================================="
echo ''

sleep 5

sudo service libvirtd start 	> /dev/null 2>&1
sudo ifconfig virbr0 		> /dev/null 2>&1
if [ $? -eq 0 ]
then
	sudo sed -i "s/lxcbr0/virbr0/g" /etc/lxc/default.conf
	sudo ifconfig virbr0
fi

sudo ifconfig lxcbr0 		> /dev/null 2>&1
if [ $? -eq 0 ]
then
	sudo ifconfig lxcbr0
fi

echo "=============================================="
echo "Done: Display AUX Bridge(s) for LXC (non-OvS)."
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Installation required packages...             "
echo "=============================================="
echo ''

sleep 5

cd /opt/olxc/"$DistDir"

sudo yum -y install curl ruby tar which 
sudo yum -y install wget tar gzip
sudo yum -y install libcap-devel libcgroup 
sudo yum -y install wget bridge-utils
sudo yum -y install graphviz
sudo yum -y install rpm-build wget
sudo yum -y install openssl-devel
sudo yum -y install bind-utils 

if [ $Release -eq 8 ]
then
	sudo yum -y install crda
	sudo rpm -ivh "$DistDir"/rpmstage/wireless-tools-29-13.el7.x86_64.rpm 
else
	sudo yum -y install wireless-tools
fi

sudo yum -y install net-tools
sudo yum -y install openssh-server uuid sshpass
sudo yum -y install rpm ntp iotop
sudo yum -y install iptables gawk yum-utils

if   [ $Release -eq 6 ]
then
	if [ $LinuxFlavor != 'CentOS' ]
	then
		sudo yum -y install lsb
	fi
elif [ $Release -ge 7 ]
then
	sudo yum -y install lsb
fi

echo ''
echo "=============================================="
echo "Package Installation complete                 "
echo "=============================================="

sleep 5

clear

if [ $Operation != new ]
then
	SwitchList='sw1 sx1'
	for k in $SwitchList
	do
	#	sleep 5

	#	clear

		echo ''
		echo "=============================================="
		echo "Cleaning up OpenvSwitch $k iptables rules...  "
		echo "=============================================="
		echo ''

		sudo iptables -S | grep $k
		function CheckRuleExist {
		sudo iptables -S | grep -c $k
		}
		RuleExist=$(CheckRuleExist)
		function FormatSearchString {
		sudo iptables -S | grep $k | sort -u | head -1 | sed 's/-/\\-/g'
		}
		SearchString=$(FormatSearchString)
		if [ $RuleExist -ne 0 ]
		then
			function GetSwitchRuleCount {
			sudo iptables -S | grep -c "$SearchString"
			}
			SwitchRuleCount=$(GetSwitchRuleCount)
		else
 			SwitchRuleCount=0
 		fi
		function GetSwitchRule {
		sudo iptables -S | grep $k | sort -u | head -1 | cut -f2-10 -d' '
		}
		SwitchRule=$(GetSwitchRule)
		function GetCountSwitchRules {
		echo $SwitchRule | grep -c $k
		}
		CountSwitchRules=$(GetCountSwitchRules)
		while [ $SwitchRuleCount -ne 0 ] && [ $RuleExist -ne 0 ] && [ $CountSwitchRules -ne 0 ]
		do
			SwitchRule=$(GetSwitchRule)
			sudo iptables -D $SwitchRule
			SearchString=$(FormatSearchString) 
			SwitchRuleCount=$(GetSwitchRuleCount)
			RuleExist=$(CheckRuleExist)
			echo ''
			echo "Rules remaining to be deleted for OpenvSwitch $k:"
			echo ''
			function GetIptablesRulesCount {
				sudo iptables -S | grep -c $k
			}
			IptablesRulesCount=$(GetIptablesRulesCount)
			if [ $IptablesRulesCount -gt 0 ]
			then
				sudo iptables -S | grep $k
			else
				echo "=============================================="
				echo "All iptables switch $k rules deleted.         "
				echo "=============================================="
				
				sleep 5

				clear
			fi
		done
	done

	sudo iptables -S | egrep 'sx1|sw1'

	echo ''
	echo "=============================================="
	echo "OpenvSwitch iptables rules cleanup completed. "
	echo "=============================================="
	echo ''
	
	sleep 5

	clear
else
	sleep 5

	clear
fi

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

if [ $Release -eq 8 ] && [ $LinuxFlavor = 'Fedora' ]
then
	echo ''
	echo "=============================================="
	echo "Install OpenvSwitch for $LF $RHV...           "
	echo "=============================================="
	echo ''

		if   [ $LinuxFlavor = 'Fedora' ]
		then
			sudo dnf -y install lxc lxc-* openvswitch openvswitch-devel openvswitch-ipsec openvswitch-test python3-openvswitch
		fi

	echo ''
	echo "=============================================="
	echo "Done: Install OpenvSwitch for $LF $RHV.       "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Create OpenvSwitch database...                "
	echo "=============================================="
	echo ''

	cd /usr/local/etc
	sudo mkdir openvswitch
	sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db
	sudo ls -l /usr/local/etc/openvswitch/conf.db

	echo ''
	echo "=============================================="
	echo "Done: Create OpenvSwitch database.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Start and Enable OpenvSwitch database...      "
	echo "=============================================="
	echo ''

	sudo systemctl start openvswitch
	sudo systemctl enable openvswitch
	sudo service openvswitch status

	echo ''
	echo "=============================================="
	echo "Done: Start and Enable OpenvSwitch database.  "
	echo "=============================================="
	echo ''
	
	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Display OpenvSwitch Version...                "
	echo "=============================================="
	echo ''

	sudo ovs-vsctl show

	echo ''
	echo "=============================================="
	echo "Done: Display OpenvSwitch Version.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

which ovs-vsctl > /dev/null 2>&1
if [ $? -ne 0 ]
then
	echo ''
	echo "=============================================="
	echo "Build OpenvSwitch from Source...              "
	echo "=============================================="

	sleep 5

	clear

	mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	touch marker-2.rpm

	function GetOVSPackageCount {
		rpm -qa | grep -c openvswitch
	}
	OVSPackageCount=$(GetOVSPackageCount)

	while [ $OVSPackageCount -lt 2 ]
	do
		echo ''
		echo "=============================================="
		echo "Install required packages and prepare...      "
		echo "=============================================="
		echo ''

		sleep 5

		clear
		
		if    [ $Release -eq 6 ]
		then
			echo ''
			echo "=============================================="
			echo "Install Required Packages...                  "
			echo "=============================================="
			echo ''

#			sudo yum -y install logrotate python-six openssl-devel checkpolicy selinux-policy-devel autoconf automake libtool python-sphinx
#			sudo yum -y install @'Development Tools' rpm-build yum-utils
			sudo yum -y install autoconf automake gcc libtool rpm-build
			sudo yum -y install openssl-devel python-devel kernel-devel kernel-devel-`uname -r`
			sudo yum -y install redhat-rpm-config kabi-whitelists

			echo ''
			echo "=============================================="
			echo "Done: Install Required Packages.              "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			if [ $LinuxFlavor = 'Oracle' ]
			then
				echo ''
				echo "=============================================="
				echo "Install Kernel Headers...                     "
				echo "=============================================="
				echo ''

				sudo yum -y install kernel-uek-debug-devel kernel-uek-devel-`uname -r`
				
				echo ''
				echo "=============================================="
				echo "Done: Install Kernel Headers.                 "
				echo "=============================================="
				echo ''

				sleep 5

				clear

			fi

			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			
			echo ''
			echo "=============================================="
			echo "Install Python27 for $LinuxFlavor $Release ..."
			echo "=============================================="
			echo ''

			if   [ $LinuxFlavor = 'CentOS' ]
			then
				echo ''
				echo "=============================================="
				echo "Install Required Packages...                  "
				echo "=============================================="
				echo ''

				sudo yum -y install yum-utils
				sudo yum -y install scl-utils
				sudo yum -y install centos-release-scl
				
				echo ''
				echo "=============================================="
				echo "Done: Install Required Packages.              "
				echo "=============================================="
				echo ''

				sleep 5

				clear

				echo ''
				echo "=============================================="
				echo "Configure Required Repo...                    "
				echo "=============================================="
				echo ''
				
				sudo yum-config-manager --enable rhel-server-rhscl-7-rpms

				echo ''
				echo "=============================================="
				echo "Done: Configure Required Repo.                "
				echo "=============================================="
				echo ''

				sleep 5

				clear
				
				echo ''
				echo "=============================================="
				echo "Configure Python...                           "
				echo "=============================================="
				echo ''
				
				sudo yum -y install python27
				source /opt/rh/python27/enable

				echo ''
				echo "=============================================="
				echo "Done: Configure Python.                       "
				echo "=============================================="
				echo ''

				sleep 5

				clear
				
			elif [ $LinuxFlavor = 'Oracle' ]
			then
				function CheckUEKVersion {
					sudo /opt/olxc/"$DistDir"/anylinux/vercomp | cut -f2 -d"'" | cut -f1 -d' ' | cut -f1 -d'.'
				}
				UEKVersion=$(CheckUEKVersion)

				if [ $UEKVersion -eq 3 ]
				then
					echo ''
					echo "=============================================="
					echo "Install Required Packages...                  "
					echo "=============================================="
					echo ''

					sudo sh -c "echo '[PUIAS_6_computational]'   >> /etc/yum.repos.d/puias-computational.repo"
					sudo sh -c "echo 'name=PUIAS computational Base $releasever - $basearch'   >> /etc/yum.repos.d/puias-computational.repo"
					sudo sh -c "echo 'mirrorlist=http://puias.math.ias.edu/data/puias/computational/\$releasever/\$basearch/mirrorlist'   >> /etc/yum.repos.d/puias-computational.repo"
					sudo sh -c "echo 'gpgcheck=1'   >> /etc/yum.repos.d/puias-computational.repo"
					sudo sh -c "echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puias'   >> /etc/yum.repos.d/puias-computational.repo"
					cd /etc/pki/rpm-gpg/
					sudo wget -q http://springdale.math.ias.edu/data/puias/6/x86_64/os/RPM-GPG-KEY-puias
					sudo rpm --import RPM-GPG-KEY-puias
					sudo yum -y install python27 python27-devel python27-libs python27-setuptools
				
					echo ''
					echo "=============================================="
					echo "Done: Install Required Packages.              "
					echo "=============================================="
					echo ''

					sleep 5

					clear

				elif [ $UEKVersion -eq 4 ]
				then
					echo ''
					echo "=============================================="
					echo "Install Required Packages...                  "
					echo "=============================================="
					echo ''

					sudo yum -y install yum-utils
					sudo yum -y install scl-utils
				
					echo ''
					echo "=============================================="
					echo "Done: Install Required Packages.              "
					echo "=============================================="
					echo ''

					sleep 5

					clear

					echo ''
					echo "=============================================="
					echo "Configure Required Repo...                    "
					echo "=============================================="
					echo ''
				
					sudo yum-config-manager --enable public_ol6_software_collections

					echo ''
					echo "=============================================="
					echo "Done: Configure Required Repo.                "
					echo "=============================================="
					echo ''

					sleep 5

					clear
				
					echo ''
					echo "=============================================="
					echo "Configure Python...                           "
					echo "=============================================="
					echo ''

					sudo yum -y install python27
					source /opt/rh/python27/enable

					echo ''
					echo "=============================================="
					echo "Done: Configure Python.                       "
					echo "=============================================="
					echo ''

					sleep 5

					clear
				fi
			fi

			
			echo ''
			echo "=============================================="
			echo "Done: Install Python27 SCL.                   "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Get OpenvSwitch Source...                     "
			echo "=============================================="
			echo ''

			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			wget --timeout=5 --tries=10 http://openvswitch.org/releases/openvswitch-"$OvsVersion".tar.gz -4

			echo ''
			echo "=============================================="
			echo "Done: Get OpenvSwitch Source.                 "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p openvswitch-"$OvsVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES/.

			echo ''
			echo "=============================================="
			echo "Untar OpenvSwitch Source...                   "
			echo "=============================================="
			echo ''

 			tar -xzf openvswitch-"$OvsVersion".tar.gz

			echo ''
			echo "=============================================="
			echo "Done: Untar OpenvSwitch Source.               "
			echo "=============================================="
			echo ''

			sleep 5

			clear

		elif [ $Release -ge 7 ]
		then
			echo ''
			echo "=============================================="
			echo "Install packages...                           "
			echo "=============================================="
			echo ''

			sudo yum -y install rpm-build wget openssl-devel gcc make
			
			echo ''
			echo "=============================================="
			echo "Done: Install packages.                       "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Prepare OpenvSwitch Source ...                "
			echo "=============================================="
			echo ''

			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			wget --timeout=5 --tries=10 http://openvswitch.org/releases/openvswitch-"$OvsVersion".tar.gz -4
			mkdir -p /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
			cp -p openvswitch-"$OvsVersion".tar.gz /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES/.

			echo ''
			echo "=============================================="
			echo "Done: Prepare OpenvSwitch Source.             "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		fi

		echo ''
		echo "=============================================="
		echo "Packages and preparations complete.           "
		echo "=============================================="

		sleep 5

		clear

#		echo ''
#		echo "=============================================="
#		echo "Untar source code and build openvswitch RPM..."
#		echo "=============================================="
#		echo ''

#		sleep 5

		if    [ $Release -eq 6 ]
		then
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES
		#	tar -xzvf openvswitch-"$OvsVersion".tar.gz
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"
#			sed -e 's/@VERSION@/0.0.1/' rhel/openvswitch.spec.in > /tmp/ovs.spec
#			sudo yum-builddep /tmp/ovs.spec
	
			echo ''
			echo "=============================================="
			echo "Edits to openvswitch.spec (if needed)...      "
			echo "=============================================="
			echo ''

			sed -i 's/python >= 2.7/python27/g'	  				                           rhel/openvswitch.spec
			
			echo ''
			echo "=============================================="
			echo "Edits to openvswitch.spec (if needed)...      "
			echo "=============================================="
			echo ''

			sleep 5

			clear
			
			echo ''
			echo "=============================================="
			echo "Build OpenvSwitch RPM's...                    "
			echo "=============================================="
			echo ''

			rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild" -bb --without check rhel/openvswitch.spec
		
			echo ''
			echo "=============================================="
			echo "Done: Build OpenvSwitch RPM's.                "
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

			echo ''
			echo "=============================================="
			echo "Install OpenvSwitch RPMs...                   "
			echo "=============================================="
			echo ''

			cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
			sudo rpm -ivh openvswitch* 
			OVSPackageCount=$(GetOVSPackageCount)
			cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			
			echo ''
			echo "=============================================="
			echo "Done: Install OpenvSwitch RPMs.               "
			echo "=============================================="

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Enable Python27 SCL Onboot...                 "
			echo "=============================================="
			echo ''

			sudo sh -c "echo '/bin/bash' > /etc/profile.d/enablepython27.sh"
			sudo sed -i 's/^/\#\!/g' /etc/profile.d/enablepython27.sh
			sudo sh -c "echo 'source scl_source enable python27' >> /etc/profile.d/enablepython27.sh"
			cat /etc/profile.d/enablepython27.sh 
			
			echo ''
			echo "=============================================="
			echo "Done: Enable Python27 SCL Onboot.             "
			echo "=============================================="
			echo ''

			sleep 5

			clear

		elif [ $Release -ge 7 ]
		then
			echo ''
			echo "=============================================="
			echo "Build & Install OpenvSwitch RPMs...           "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			if [ $Release -eq 7 ] && [ $(SoftwareVersion $OvsVersion) -eq $(SoftwareVersion "2.5.4") ]
			then
				cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES
				tar -zxvf openvswitch-"$OvsVersion".tar.gz
				cp -p openvswitch-"$OvsVersion"/rhel/*.spec /opt/olxc/"$DistDir"/uekulele/openvswitch/.
				cd /opt/olxc/"$DistDir"/uekulele/openvswitch
				sleep 5
			fi

			if [ $Release -eq 7 ] && [ $(SoftwareVersion $OvsVersion) -eq $(SoftwareVersion "2.12.1") ]
			then
				echo ''
				echo "==============================================" 
				echo "Prepare Source Code...                        "
				echo "==============================================" 
				echo ''

				sleep 5

				cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES
				tar -zxvf openvswitch-"$OvsVersion".tar.gz

				echo ''
				echo "==============================================" 
				echo "Done: Prepare Source Code.                    "
				echo "==============================================" 
				echo ''

				sleep 5

				clear

				echo ''
				echo "==============================================" 
				echo "Apply Code Patch(es) if needed...             "
				echo "==============================================" 
				echo ''

				echo "No patches currently required for Release $Release and OpenvSwitch $OvsVersion."

				# if [ $RHMV -ge 8 ] && [ $RHMV -le 9 ]
				# then
				# 	cp -p /home/ubuntu/0001-compat-add-SCTP-netfilter-states-for-older-kernels.patch /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES/openvswitch-"$OvsVersion"/.
				# 	cd ./openvswitch-"$OvsVersion"
				# 	patch -p1 < 0001-compat-add-SCTP-netfilter-states-for-older-kernels.patch
				# 	cd ../.
				#	git format-patch -1 8c7130da98c5
				#	git apply --stat 0001-compat-add-SCTP-netfilter-states-for-older-kernels.patch
				# 	sleep 10
				# fi

				echo ''
				echo "==============================================" 
				echo "Done: Apply Code Patch(es) if needed.         "
				echo "==============================================" 
				echo ''

				sleep 5

				clear

				echo ''
				echo "==============================================" 
				echo "Copy OpenvSwitch spec files...                "
				echo "==============================================" 
				echo ''

				cp -p openvswitch-"$OvsVersion"/rhel/*.spec /opt/olxc/"$DistDir"/uekulele/openvswitch/.
				cd /opt/olxc/"$DistDir"/uekulele/openvswitch
				sudo ls -l /opt/olxc/"$DistDir"/uekulele/openvswitch/*.spec

				echo ''
				echo "==============================================" 
				echo "Done: Copy OpenvSwitch spec files.            "
				echo "==============================================" 
				echo ''

				sleep 5

				clear
		
				if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 7 ]
				then	
					echo ''
					echo "==============================================" 
					echo "Configure repos...                            "
					echo "==============================================" 
					echo ''

					sudo yum-config-manager --enable ol7_latest
					sudo yum-config-manager --enable ol7_optional_archive
			
					echo ''
					echo "==============================================" 
					echo "Done: Configure repos.                        "
					echo "==============================================" 
					echo ''

					sleep 5

					clear
				fi

				echo ''
				echo "==============================================" 
				echo "Install Python Packages...                    "
				echo "==============================================" 
				echo ''

				sleep 5

				sudo yum -y install python3
				sudo yum -y install python3-sphinx
				sudo yum -y install python-six

				echo ''
				echo "==============================================" 
				echo "Done: Install Python Packages.                "
				echo "==============================================" 
				echo ''
				
				sleep 5

				clear

			        if [ $LinuxFlavor = 'Oracle' ] && [ $Release -eq 7 ]
				then
					echo ''
					echo "==============================================" 
					echo "Re-version unbound-libs...                    "
					echo "==============================================" 
					echo ''

					sleep 5

			                sudo yum -y remove   unbound-libs-1.6.6-5* > /dev/null 2>&1
			                sudo yum -y install  unbound-libs-1.6.6-1* > /dev/null 2>&1
			                sudo yum -y install unbound-devel-1.6.6-1* > /dev/null 2>&1
					rpm -qa | egrep 'unbound-libs|unbound-devel'
					
					echo ''
					echo "==============================================" 
					echo "Done: Re-version unbound-libs.                "
					echo "==============================================" 
					echo ''

					sleep 5

					clear
			        fi

				if [ $LinuxFlavor = 'Red' ] && [ $Release -eq 7 ]
				then
					echo ''
					echo "==============================================" 
					echo "Configure repos...                            "
					echo "==============================================" 
					echo ''

					sleep 5

					sudo subscription-manager repos --enable rhel-7-server-optional-rpms
					
					echo ''
					echo "==============================================" 
					echo "Configure repos...                            "
					echo "==============================================" 
					echo ''

					sleep 5

					clear
				fi

				echo ''
				echo "==============================================" 
				echo "Install Packages...                           "
				echo "==============================================" 
				echo ''

				sleep 5

				sudo yum -y install selinux-policy-devel unbound-devel
				
				echo ''
				echo "==============================================" 
				echo "Done: Install Packages.                       "
				echo "==============================================" 
				echo ''

				sleep 5

				clear

				echo ''
				echo "==============================================" 
				echo "Set Python Build Environment...               "
				echo "==============================================" 
				echo ''

				sleep 5

 				sudo alternatives --set python /usr/bin/python3 > /dev/null 2>&1
 				python3 -m venv py36env
 				source py36env/bin/activate
				python --version

				echo ''
				echo "==============================================" 
				echo "Done: Set Python Build Environment.           "
				echo "==============================================" 
				echo ''

				sleep 5

				clear

				echo ''
				echo "==============================================" 
				echo "Python3 pip ops (if needed)...                "
				echo "==============================================" 
				echo ''

				echo "No pip ops currently required for Release $Release and OpenvSwitch $OvsVersion."

 			#	python3 -m pip install --upgrade pip
 			#	python3 -m pip install six
 			#	python3 -m pip install sphinx

				echo ''
				echo "==============================================" 
				echo "Done: Python3 pip ops.                        "
				echo "==============================================" 
				echo ''

				sleep 5

				clear

				echo ''
				echo "==============================================" 
				echo "Install python-sphinx...                      "
				echo "==============================================" 
				echo ''

				sleep 5

				sudo yum -y install python-sphinx

				echo ''
				echo "==============================================" 
				echo "Done: Install python-sphinx.                  "
				echo "==============================================" 
				echo ''

				sleep 5

				clear

				echo ''
				echo "==============================================" 
				echo "Edits to openvswitch.spec (if needed)...      "
				echo "==============================================" 
				echo ''

				echo "No edits to openvswitch.spec currently required for Release $Release and OpenvSwitch $OvsVersion."

			#	sed -i 's/BuildRequires: python-sphinx/BuildRequires: python3-sphinx/g' openvswitch.spec

				echo ''
				echo "==============================================" 
				echo "Done: Edits to openvswitch.spec.              "
				echo "==============================================" 
				echo ''

				sleep 5

				clear
			fi
			
 			if [ $Release -eq 8 ]
 			then
				if [ $(SoftwareVersion $OvsVersion) -eq $(SoftwareVersion "2.14.0") ]
				then
					cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			
					echo ''
					echo "==============================================" 
					echo "Install Packages...                           "
					echo "==============================================" 
					echo ''

					sudo yum -y install checkpolicy selinux-policy-devel unbound-devel
					sudo yum -y install python3-sphinx
					sudo yum -y install gcc-c++ groff libcap-ng-devel python3-devel unbound
			
					echo ''
					echo "==============================================" 
					echo "Done: Install Packages.                       "
					echo "==============================================" 
					echo ''
					
					sleep 5

					clear

					echo ''
					echo "=============================================="
					echo "Untar source code...                          "
					echo "=============================================="
					echo ''

					wget https://www.openvswitch.org/releases/openvswitch-2.14.0.tar.gz
					tar -xzvf openvswitch-2.14.0.tar.gz 

					echo ''
					echo "=============================================="
					echo "Done: Untar source code.                      "
					echo "=============================================="
					echo ''

					sleep 5

					clear

					echo ''
					echo "==============================================" 
					echo "Build OpenvSwitch RPM's...                    "
					echo "==============================================" 
					echo ''

					sleep 5

					cd openvswitch-2.14.0
					./configure
					make rpm-fedora

					echo ''
					echo "==============================================" 
					echo "Done: Build OpenvSwitch RPM's.                "
					echo "==============================================" 
					echo ''

					sleep 5
					
					clear

					echo ''
					echo "==============================================" 
					echo "Install OpenvSwitch RPM's.                    "
					echo "==============================================" 
					echo ''

					sudo yum -y remove openvswitch-devel-*
					sudo yum -y remove openvswitch-*
					sudo yum -y install network-scripts libreswan
					cd /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/noarch
					sudo rpm -ivh python3-openvswitch-"$OvsVersion"*.el8.noarch.rpm
					sudo rpm -ivh openvswitch-selinux-policy-"$OvsVersion"*.el8.noarch.rpm
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/noarch/python3-openvswitch-"$OvsVersion".el8.noarch.rpm
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/noarch/openvswitch-selinux-policy-"$OvsVersion".el8.noarch.rpm
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/x86_64/openvswitch-* 
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/x86_64/openvswitch-debuginfo*
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/x86_64/openvswitch-debugsource*
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/x86_64/openvswitch-devel*
					sudo rpm -ivh /opt/olxc/"$DistDir"/uekulele/openvswitch/openvswitch-"$OvsVersion"/rpm/rpmbuild/RPMS/x86_64/openvswitch-ipsec*
					cd /opt/olxc/"$DistDir"/uekulele/openvswitch
					
					echo ''
					echo "==============================================" 
					echo "Done: Build & Install OpenvSwitch RPM's.      "
					echo "==============================================" 
					echo ''

				elif [ $(SoftwareVersion $OvsVersion) -eq $(SoftwareVersion "2.12.1") ]
				then
					echo ''
					echo "=============================================="
					echo "Untar source code...                          "
					echo "=============================================="
					echo ''

					sleep 5

					cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/SOURCES
					tar -zxvf openvswitch-"$OvsVersion".tar.gz
					cp -p openvswitch-"$OvsVersion"/rhel/*.spec /opt/olxc/"$DistDir"/uekulele/openvswitch/.
					cd /opt/olxc/"$DistDir"/uekulele/openvswitch

					echo ''
					echo "=============================================="
					echo "Done: Untar source code.                      "
					echo "=============================================="
					echo ''

					sleep 5

					clear
			
					echo ''
					echo "==============================================" 
					echo "Install Packages...                           "
					echo "==============================================" 
					echo ''

					sudo yum -y install selinux-policy-devel unbound-devel
					sudo yum -y install rpm-build yum-utils tar wget
			
					echo ''
					echo "==============================================" 
					echo "Done: Install Packages.                       "
					echo "==============================================" 
					echo ''

					sleep 5

					clear
 
					echo ''
					echo "==============================================" 
					echo "Configure python environment...               "
					echo "==============================================" 
					echo ''

					sudo alternatives --set python /usr/bin/python3
					python3 -m venv py36env
					source py36env/bin/activate
					python --version

					echo ''
					echo "==============================================" 
					echo "Configure python environment...               "
					echo "==============================================" 
					echo ''

					sleep 5

					clear

					echo ''
					echo "==============================================" 
					echo "Python3 pip ops (if needed)...                "
					echo "==============================================" 
					echo ''

					echo "No pip ops currently required for Release $Release and OpenvSwitch $OvsVersion."

 				#	python3 -m pip install --upgrade pip
 				#	python3 -m pip install six
 				#	python3 -m pip install sphinx
				#	sleep 5
				
					echo ''
					echo "==============================================" 
					echo "Done: Python3 pip ops (if needed).            "
					echo "==============================================" 
					echo ''

					sleep 5

					clear
	
				#	echo ''
				#	echo "==============================================" 
				#	echo "Build RPM python-six from Source...           "
				#	echo "==============================================" 
				#	echo ''
	
				#	wget https://kojipkgs.fedoraproject.org//packages/python-six/1.15.0/1.fc33/src/python-six-1.15.0-1.fc33.src.rpm
				#	rpm -ivh python-six-1.15.0-1.fc33.src.rpm
				#	cd ~/rpmbuild/SOURCES/
				#	tar -xzvf six-1.15.0.tar.gz
				#	cd ~/rpmbuild/SOURCES/six-1.15.0
				#	sed -i '/setup/s/six/python-six/g' setup.py
				#	python setup.py bdist_rpm
			
				#	echo ''
				#	echo "==============================================" 
				#	echo "Done: Build RPM python-six from Source...     "
				#	echo "==============================================" 
				#	echo ''

				#	sleep 5

				#	clear

					echo ''
					echo "==============================================" 
					echo "Install RPM python-six...                     "
					echo "==============================================" 
					echo ''

					sudo dnf -y install "$DistDir"/rpmstage/python-six-1.9.0-2.el7.noarch.rpm
				#	sudo rpm -ivh ~/rpmbuild/SOURCES/six-1.15.0/dist/python-six-1.15.0-1.noarch.rpm

					echo ''
					echo "==============================================" 
					echo "Install RPM python-six...                     "
					echo "==============================================" 
					echo ''

					sleep 5 
	
					clear

                                        echo ''
                                        echo "==============================================" 
                                        echo "Install from codeready_builder repo...    "
                                        echo "==============================================" 
                                        echo ''

					sleep 5

                                        if [ $LinuxFlavor = 'Oracle' ]
                                        then
                                                sudo yum-config-manager --enable ol8_codeready_builder

                                        elif [ $LinuxFlavor = 'Red' ]
                                        then
                                                sudo yum-config-manager --enable codeready-builder-for-rhel-8-x86_64-rpms
                                        fi

                                        sudo yum -y install python3-sphinx
                                        sudo rpm -qa | egrep 'python-six|python3-sphinx'

                                        echo ''
                                        echo "==============================================" 
                                        echo "Done: Install from codeready_builder repo."
                                        echo "==============================================" 
                                        echo ''

                                        sleep 5

                                        clear

					echo ''
					echo "==============================================" 
					echo "Edit openvswitch.spec for python3-sphinx...   "
					echo "==============================================" 
					echo ''

					cd /opt/olxc/"$DistDir"/uekulele/openvswitch
				 	sed -i 's/BuildRequires: python-six/BuildRequires: python3-six/g'       openvswitch.spec
					sed -i 's/BuildRequires: python-sphinx/BuildRequires: python3-sphinx/g' openvswitch.spec
				 	sed -i 's/python >= 2.7/python27/g'	  				openvswitch.spec

					cat openvswitch.spec | grep BuildRequires | egrep 'python3-six|python3-sphinx'

					echo ''
					echo "==============================================" 
					echo "Done: Edit openvswitch.spec for python3-sphinx"
					echo "==============================================" 
					echo ''

					sleep 5

					clear

					echo ''
					echo "==============================================" 
					echo "Build OpenvSwitch RPM's...                    "
					echo "==============================================" 
					echo ''

					sleep 5

					rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild" -ba --without check openvswitch.spec
					
					echo ''
					echo "=============================================="
					echo "Done: Build OpenvSwitch RPMs                  "
					echo "=============================================="
					echo ''

					sleep 5
					
					clear
					
					echo ''
					echo "==============================================" 
					echo "Install OpenvSwitch RPM's...                  "
					echo "==============================================" 
					echo ''

					cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64/
					sudo rpm -ivh *.rpm
					sudo rpm -ivh openvswitch-"$OvsVersion"-1.x86_64.rpm
					sudo rpm -ivh openvswitch-*
					sudo rpm -ivh openvswitch-debug*
	
					echo ''
					echo "==============================================" 
					echo "Done: Install OpenvSwitch RPM's.              "
					echo "==============================================" 
					echo ''

					sleep 5

					clear

					echo ''
					echo "=============================================="
					echo "Done: Build & Install OpenvSwitch RPMs.       "
					echo "=============================================="
				fi
			fi

			if [ $Release -eq 6 ] || [ $Release -eq 7 ]
			then
				echo ''
				echo "==============================================" 
				echo "Build OpenvSwitch RPM's...                    "
				echo "==============================================" 
				echo ''

				sleep 5

				rpmbuild --define "_topdir /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild" -ba --without check openvswitch.spec
	
				echo ''
				echo "=============================================="
				echo "Done: Build OpenvSwitch RPMs                  "
				echo "=============================================="

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

				echo ''
				echo "=============================================="
				echo "Install OpenvSwitch RPMs...                   "
				echo "=============================================="
				echo ''

				cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
			#	sudo yum -y localinstall openvswitch* 
				sudo rpm -ivh openvswitch-*
				OVSPackageCount=$(GetOVSPackageCount)
				cd /opt/olxc/"$DistDir"/uekulele/openvswitch
			
				echo ''
				echo "=============================================="
				echo "Done: Install OpenvSwitch RPMs.               "
				echo "=============================================="
				echo ''

				sleep 5

				clear
			fi
		fi
	
	OVSPackageCount=$(GetOVSPackageCount)
	done

	if [ $OVSPackageCount -ge 2 ]
	then
		echo ''
		echo "=============================================="
		echo "OpenvSwitch RPMs built on $LF Linux $RHV      " 
		echo "=============================================="
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install OpenvSwitch RPMs...                   "
	echo "=============================================="
	echo ''

	sleep 5

	cd /opt/olxc/"$DistDir"/uekulele/openvswitch/rpmbuild/RPMS/x86_64
	sudo rpm -ivh openvswitch*

	echo ''
	echo "=============================================="
	echo "Install OpenvSwitch RPM completed.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Create OpenvSwitch database...                "
	echo "=============================================="
	echo ''

	cd /usr/local/etc
	sudo mkdir openvswitch
	sudo ovsdb-tool create /usr/local/etc/openvswitch/conf.db
	if   [ $Release -ge 7 ]
	then
		sudo systemctl start openvswitch.service
 		sudo ls -l /usr/local/etc/openvswitch/conf.db

	elif [ $Release -eq 6 ]
	then
		sudo service openvswitch start
		sudo chkconfig openvswitch on
	fi

	echo ''
	echo "=============================================="
	echo "Done: Create OpenvSwitch database...          "
	echo "=============================================="
	
	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Test OpenvSwitch...                           "
	echo "=============================================="
	echo ''

	sudo ovs-vsctl show

	echo ''
	echo "=============================================="
	echo "Test OpenvSwitch complete.                    "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Build OpenvSwitch from Source complete.       "
	echo "=============================================="

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Verify required packages status...            "
echo "=============================================="
echo ''

if [ $Release -ge 7 ] || [ $Release -eq 6 ]
then
	if [ $LinuxFlavor != 'Fedora' ]
	then
		function CheckPackageInstalled {
			echo 'automake bind-utils bridge-utils curl debootstrap docbook docbook2X facter gawk gcc graphviz gzip iotop iptables libcap-devel libcgroup lsb-core lxc lxc-2 lxc-debug lxc-devel lxc-libs make net-tools ntp openssh-server openssl-devel openvswitch-2 openvswitch-debug perl rpm rpm-build ruby sshpass tar uuid wget which xmlto yum-utils'
		}
	else
		function CheckPackageInstalled {
			echo 'automake bind-utils bridge-utils curl debootstrap docbook docbook2X facter gawk gcc graphviz gzip iotop iptables libcap-devel libcgroup lsb-core lxc lxc-2 lxc-debug lxc-devel lxc-libs make net-tools ntp openssh-server openssl-devel openvswitch-2 openvswitch-debug perl rpm rpm-build ruby sshpass tar uuid wget which xmlto yum-utils'
		}
	fi
fi

PackageInstalled=$(CheckPackageInstalled)

for i in $PackageInstalled
do
sudo rpm -qa | grep -i $i | tail -1 | sed 's/^/Installed: /' 
done

echo ''
echo "=============================================="
echo "Verify required packages status completed.    "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Pre-install backup of key files...            "
echo "==============================================" 
echo ''
echo "=============================================="
echo "Extracting backup scripts...                  "
echo "==============================================" 
echo ''

sudo tar -v --extract --file=/opt/olxc/"$DistDir"/uekulele/archives/ubuntu-host.tar -C / etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh --touch
sudo /etc/orabuntu-lxc-scripts/ubuntu-host-backup.sh

echo ''
echo "=============================================="
echo "Key files backups check complete.             "
echo "==============================================" 

sleep 5

clear

# sudo lxc-info -n nsa > /dev/null 2>&1
# if [ $? -ne 0 ] && [ $Release -eq 6 ]
# then
# 	sudo reboot
# fi

function CheckNameServerExists {
	sudo lxc-ls -f | egrep -c "$NameServer|nsa"
}
NameServerExists=$(CheckNameServerExists)

function CheckLxcDefaultEmpty {
	cat /etc/lxc/default.conf | grep -c empty
}
LxcDefaultEmpty=$(CheckLxcDefaultEmpty)

if [ $LxcDefaultEmpty -gt 0 ]
then
	sudo cp -p /etc/lxc/default.conf.bak /etc/lxc/default.conf
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Establish sudo privileges ...                 "
echo "=============================================="
echo ''

sudo date

echo ''
echo "=============================================="
echo "Establish sudo privileges successful.         "
echo "=============================================="
echo ''

sleep 5

clear

function CheckNameServerExists {
	sudo lxc-ls -f | egrep -c "$NameServer|nsa"
}
NameServerExists=$(CheckNameServerExists)

function GetLXCVersion {
        lxc-create --version
}
LXCVersion=$(GetLXCVersion)

function ConfirmContainerCreated {
        sudo lxc-ls -f | grep nsa | wc -l
}
ContainerCreated=$(ConfirmContainerCreated)

if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Create LXC DNS DHCP container...              "
	echo "=============================================="
	echo ''

	m=1; n=1; p=1
	while [ $ContainerCreated -eq 0 ] && [ $m -le 3 ] && [ $Release -ge 7 ]
	do
	        echo "=============================================="
                echo "Trying Method 1 ...                           "
                echo "=============================================="
                echo ''

                dig +short us.images.linuxcontainers.org

                if [ ! -d /opt/olxc/"$DistDir"/lxcimage/nsa ]
                then
                        sudo mkdir -p /opt/olxc/"$DistDir"/lxcimage/nsa
                else
                        echo "Directory already exists: /opt/olxc/"$DistDir"/lxcimage/nsa"
                        echo ''
                fi

                sudo rm -f                /opt/olxc/"$DistDir"/lxcimage/nsa/*
                cd                        /opt/olxc/"$DistDir"/lxcimage/nsa
                sudo chown $Owner:$Group  /opt/olxc/"$DistDir"/lxcimage/nsa

                wget -4 -q https://us.images.linuxcontainers.org/images/ubuntu/focal/amd64/default/ -P /opt/olxc/"$DistDir"/lxcimage/nsa

                function GetBuildDate {
                        grep folder.gif index.html | tail -1 | awk -F "\"" '{print $8}' | sed 's/\///g' | sed 's/\.//g'
                }
                BuildDate=$(GetBuildDate)

                wget -4 -q https://us.images.linuxcontainers.org/images/ubuntu/focal/amd64/default/"$BuildDate"/SHA256SUMS -P /opt/olxc/"$DistDir"/lxcimage/nsa

                for i in rootfs.tar.xz meta.tar.xz
                do
                        if [ -f /opt/olxc/"$DistDir"/lxcimage/nsa/$i ]
                        then
                                rm -f /opt/olxc/"$DistDir"/lxcimage/nsa/$i
                        fi

                        echo ''
                        echo "Downloading $i ..."
                        echo ''

                        wget -4 --no-verbose --progress=bar https://us.images.linuxcontainers.org/images/ubuntu/focal/amd64/default/"$BuildDate"/$i -P /opt/olxc/"$DistDir"/lxcimage/nsa
			diff <(shasum -a 256 /opt/olxc/"$DistDir"/lxcimage/nsa/$i | cut -f1,11 -d'/' | sed 's/  */ /g' | sed 's/\///' | sed 's/  */ /g') <(grep $i /opt/olxc/"$DistDir"/lxcimage/nsa/SHA256SUMS)
                done
                if [ $? -eq 0 ]
                then
                        echo ''
                        sudo lxc-create -t local -n nsa -- -m /opt/olxc/"$DistDir"/lxcimage/nsa/meta.tar.xz -f /opt/olxc/"$DistDir"/lxcimage/nsa/rootfs.tar.xz
                else
                        m=$((m+1))
                fi

        	ContainerCreated=$(ConfirmContainerCreated)
	done
	
	while [ $ContainerCreated -eq 0 ] && [ $n -le 3 ]
	do
		echo "=============================================="
		echo "Trying Method 2...                            "
		echo "=============================================="
		echo ''
	
		sudo lxc-create -t download -n nsa -- --dist ubuntu --release focal --arch amd64 --keyserver hkp://keyserver.ubuntu.com:80
		if [ $? -ne 0 ]
		then
			sudo lxc-stop -n nsa -k
			sudo lxc-destroy -n nsa
			sudo rm -rf /var/lib/lxc/nsa
			sudo lxc-create -t download -n nsa -- --dist ubuntu --release focal --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80
			if [ $? -ne 0 ]
			then
				sudo lxc-stop -n nsa -k
				sudo lxc-destroy -n nsa
				sudo rm -rf /var/lib/lxc/nsa
                                sudo lxc-create -t download -n nsa -- --dist ubuntu --release focal --arch amd64 --no-validate
			fi
		fi

		n=$((n+1))
		ContainerCreated=$(ConfirmContainerCreated)
	done
	
	while [ $ContainerCreated -eq 0 ] && [ $p -le 3 ]
	do
		echo "=============================================="
		echo "Trying Method 3...                            "
		echo "=============================================="
		echo ''

		sudo lxc-create -n nsa -t ubuntu -- --release focal --arch amd64
		sleep 5
		p=$((p+1))
		ContainerCreated=$(ConfirmContainerCreated)
	done

	if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
	then
		sudo lxc-update-config -c /var/lib/lxc/nsa/config
	else
                sudo sed -i 's/lxc.net.0/lxc.network/g'         	/var/lib/lxc/$NameServer/config > /dev/null 2>&1
                sudo sed -i 's/lxc.net.1/lxc.network/g'         	/var/lib/lxc/$NameServer/config > /dev/null 2>&1
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'      	/var/lib/lxc/$NameServer/config > /dev/null 2>&1
		sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'	/var/lib/lxc/$NameServer/config > /dev/null 2>&1
	fi

	echo ''
	echo "=============================================="
	echo "Create LXC DNS DHCP container complete.       "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install & configure DNS DHCP LXC container... "
	echo "=============================================="

	echo ''
	sudo touch /var/lib/lxc/nsa/rootfs/etc/resolv.conf > /dev/null 2>&1
	sudo sed -i '0,/.*nameserver.*/s/.*nameserver.*/nameserver 8.8.8.8\n&/' /var/lib/lxc/nsa/rootfs/etc/resolv.conf > /dev/null 2>&1
	sudo lxc-start -n nsa
	echo ''

	sleep 5 

	clear

	echo ''
	echo "=============================================="
	echo "Testing lxc-attach for ubuntu user...         "
	echo "=============================================="
	echo ''


	sudo lxc-attach -n nsa -- uname -a
	if [ $? -ne 0 ]
	then
		echo ''
		echo "=============================================="
		echo "lxc-attach has issue(s).                      "
		echo "=============================================="
	else
		echo ''
		echo "=============================================="
		echo "lxc-attach successful.                        "
		echo "=============================================="

		sleep 5 
	fi

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Install bind9 & isc-dhcp-server in container. "
	echo "Install openssh-server in container.          "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n nsa -- sudo apt-get -y update
	sudo lxc-attach -n nsa -- sudo apt-get -y install bind9 isc-dhcp-server bind9utils dnsutils openssh-server man awscli sshpass tcpdump nmap net-tools

	sleep 2

	sudo lxc-attach -n nsa -- sudo service isc-dhcp-server start
	sudo lxc-attach -n nsa -- sudo service bind9 start

	echo ''
	echo "=============================================="
	echo "Install bind9 & isc-dhcp-server complete.     "
	echo "Install openssh-server complete.              "
	echo "=============================================="

	sleep 5

	clear

#	echo ''
#	echo "=============================================="
#	echo "Create DNS Replication Landing Zone ...       "
#	echo "=============================================="
#	echo ''

#	sudo lxc-attach -n nsa -- sudo mkdir -p /root/backup-lxc-container/$NameServerBase/updates

#	echo ''
#	echo "=============================================="
#	echo "Done: Create DNS Replication Landing Zone.    "
#	echo "=============================================="
#	echo ''

#	sleep 5

#	clear

	echo ''
	echo "=============================================="
	echo "DNS DHCP installed in LXC container.          "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Stopping DNS DHCP LXC container...            "
	echo "=============================================="
	echo ''

	sudo lxc-stop -n nsa
	sudo lxc-info -n nsa

	echo ''
	echo "=============================================="
	echo "DNS DHCP LXC container stopped.               "
	echo "=============================================="
	echo ''

	sleep 5 

	clear
fi

# Unpack customized OS host files for Oracle on LXC host server

function CheckNsaExists {
	sudo lxc-ls -f | grep -c nsa
}
NsaExists=$(CheckNsaExists)
FirstRunNsa=$NsaExists

echo ''
echo "=============================================="
echo "Unpack G1 files $LF Linux $RHV                "
echo "=============================================="
echo ''

if [ -f /etc/dnsmasq.conf ]
then
	sudo cp -p /etc/dnsmasq.conf /etc/dnsmasq.conf.olxc.2
	sudo rm -f /etc/dnsmasq.conf
fi
sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/ubuntu-host.tar -C / --touch

echo ''
echo "=============================================="
echo "Done: Unpack G1 files $LF Linux $RHV          "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Unpack G2 files for $LF Linux $RHV...         "
echo "=============================================="
echo ''

sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-host.tar -C / --touch
sudo chmod +x /etc/network/openvswitch/crt_ovs_s*.sh

if [ $MultiHostVar2 = 'Y' ] && [ -f /var/lib/lxc/nsa/config ]
then
	sudo rm /var/lib/lxc/nsa/config
fi

echo ''
echo "=============================================="
echo "Done: Unpack G2 files for $LF Linux $RHV.     "
echo "=============================================="

sleep 5

clear

echo "=============================================="
echo "Install OvsVethCleanup.service                "
echo "=============================================="
echo ''

sudo sh -c "echo '[Unit]'                                                               >  /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'Description=OvsVethCleanup job'                                       >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo '[Service]'                                                            >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'Type=oneshot'                                                         >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'User=root'                                                            >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'ExecStart=/usr/bin/bash /etc/network/openvswitch/OvsVethCleanup.sh'   >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo '[Install]'								>> /etc/systemd/system/OvsVethCleanup.service"
sudo sh -c "echo 'WantedBy=multi-user.target'						>> /etc/systemd/system/OvsVethCleanup.service"

sudo cat /etc/systemd/system/OvsVethCleanup.service

echo ''
echo "=============================================="
echo "Done: Install OvsVethCleanup.service          "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Install OvsVethCleanup.timer                  "
echo "=============================================="
echo ''

sudo sh -c "echo '[Unit]'                                                               >  /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'Description=OvsVethCleanup'                                           >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo '[Timer]'                                                              >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'OnUnitActiveSec=60s'                                                  >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'OnBootSec=60s'                                                        >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo ''                                                                     >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo '[Install]'                                                            >> /etc/systemd/system/OvsVethCleanup.timer"
sudo sh -c "echo 'WantedBy=timers.target'                                               >> /etc/systemd/system/OvsVethCleanup.timer"

sudo cat /etc/systemd/system/OvsVethCleanup.timer

echo ''

sudo systemctl daemon-reload
sudo systemctl enable OvsVethCleanup.timer
sudo systemctl start  OvsVethCleanup.timer

echo ''

sudo systemctl list-timers --all

sleep 5

echo ''
echo "=============================================="
echo "Done: Install OvsVethCleanup.timer            "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Creating /etc/sysctl.d/60-olxc.conf file ..."
echo "=============================================="
echo ''
echo "=============================================="
echo "These values are set automatically based on   "
echo "best practice guidelines.                     "
echo "You can adjust them after installation.       "
echo "=============================================="
echo ''

if [ -r /etc/sysctl.d/60-olxc.conf ]
then
	sudo cp -p /etc/sysctl.d/60-olxc.conf /etc/sysctl.d/60-olxc.conf.pre.orabuntu-lxc.bak
	sudo rm /etc/sysctl.d/60-olxc.conf
fi

sudo touch /etc/sysctl.d/60-olxc.conf
sudo cat /etc/sysctl.d/60-olxc.conf 
sudo chmod +x /etc/sysctl.d/60-olxc.conf

echo 'Linux OS Memory Reservation (in Kb) ... '$OSMemRes 
function GetMemTotal {
	sudo cat /proc/meminfo | grep MemTotal | cut -f2 -d':' |  sed 's/  *//g' | cut -f1 -d'k'
}
MemTotal=$(GetMemTotal)
echo 'Memory (in Kb) ........................ '$MemTotal

((MemOracleKb = MemTotal - OSMemRes))
echo 'Memory for Oracle (in Kb) ............. '$MemOracleKb

((MemOracleBytes = MemOracleKb * 1024))
echo 'Memory for Oracle (in bytes) .......... '$MemOracleBytes

function GetPageSize {
	sudo getconf PAGE_SIZE
}
PageSize=$(GetPageSize)
echo 'Page Size (in bytes) .................. '$PageSize

((shmall = MemOracleBytes / 4096))
echo 'shmall (in 4Kb pages) ................. '$shmall
sudo sysctl -w kernel.shmall=$shmall

((shmmax = MemOracleBytes / 2))
echo 'shmmax (in bytes) ..................... '$shmmax
sudo sysctl -w kernel.shmmax=$shmmax

sudo sh -c "echo '# New Stack Settings'                       > /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.conf.default.rp_filter=0'         >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.conf.all.rp_filter=0'             >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.ip_forward=1'                     >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo '# Oracle Settings'                         >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo ''                                          >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.shmall = $shmall'                   >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.shmmax = $shmmax'                   >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.shmmni = 4096'                      >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.sem = 250 32000 100 128'            >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'fs.file-max = 6815744'                     >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'fs.aio-max-nr = 1048576'                   >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.ipv4.ip_local_port_range = 9000 65500' >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.rmem_default = 262144'            >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.rmem_max = 4194304'               >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.wmem_default = 262144'            >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'net.core.wmem_max = 1048576'               >> /etc/sysctl.d/60-olxc.conf"
sudo sh -c "echo 'kernel.panic_on_oops = 1'                  >> /etc/sysctl.d/60-olxc.conf"

echo ''
echo "=============================================="
echo "Created /etc/sysctl.d/60-olxc.conf file ... "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Display /etc/sysctl.d/60-olxc.conf          "
echo "=============================================="
echo ''

sudo sysctl -p /etc/sysctl.d/60-olxc.conf

echo ''
echo "=============================================="
echo "Displayed /etc/sysctl.d/60-olxc.conf file.  "
echo "=============================================="

sleep 5

clear

if [ ! -f /etc/systemd/system/60-olxc.service ] && [ $Release -ge 7 ]
then
	echo ''
	echo "=============================================="
	echo "Create 60-olxc.service in systemd...        "
	echo "=============================================="
	echo ''

	sudo sh -c "echo '[Unit]'                                    			 > /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'Description=60-olxc Service'            			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'After=network.target'                     			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo ''                                         			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo '[Service]'                                			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'Type=oneshot'                             			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'User=root'                                			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'RemainAfterExit=yes'                      			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'ExecStart=/usr/sbin/sysctl -p /etc/sysctl.d/60-olxc.conf'	>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo ''                                         			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo '[Install]'                                			>> /etc/systemd/system/60-olxc.service"
	sudo sh -c "echo 'WantedBy=multi-user.target'               			>> /etc/systemd/system/60-olxc.service"
	sudo chmod 644 /etc/systemd/system/60-olxc.service

	sudo systemctl enable 60-olxc

	sudo cat /etc/systemd/system/60-olxc.service

	echo ''
	echo "=============================================="
	echo "Created 60-olxc.service in systemd.         "
	echo "=============================================="

	sleep 5

	clear
fi

# echo ''
# echo "=============================================="
# echo "Creating /etc/security/limits.d/70-oracle.conf"
# echo "=============================================="
# echo ''
# echo "=============================================="
# echo "These values are set automatically based on   "
# echo "Oracle best practice guidelines.              "
# echo "You can adjust them after installation.       "
# echo "=============================================="
# echo ''

# sudo touch /etc/security/limits.d/70-oracle.conf
# sudo chmod +x /etc/security/limits.d/70-oracle.conf

# Oracle Kernel Parameters

# sudo sh -c "echo '#                                        	'  > /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '# Oracle DB Parameters                   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '#                                        	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	soft	nproc       2047   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	hard	nproc      16384   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	soft	nofile      1024   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	hard	nofile     65536   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	soft	stack      10240   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'oracle	hard	stack      10240   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '* 	soft 	memlock  9873408           	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '* 	hard 	memlock  9873408           	' >> /etc/security/limits.d/70-oracle.conf"

# Oracle Grid Infrastructure Kernel Parameters
	
# sudo sh -c "echo '#                                        	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '# Oracle GI Parameters                   	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo '#                                        	' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	soft	nproc       2047        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	hard	nproc      16384        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	soft	nofile      1024        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	hard	nofile     65536        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	soft	stack      10240        ' >> /etc/security/limits.d/70-oracle.conf"
# sudo sh -c "echo 'grid	hard	stack      10240        ' >> /etc/security/limits.d/70-oracle.conf"

# echo "=============================================="
# echo "Display /etc/security/limits.d/70-oracle.conf "
# echo "=============================================="
# echo ''
# sudo cat /etc/security/limits.d/70-oracle.conf
# echo ''
# echo "=============================================="
# echo "Created /etc/security/limits.d/70-oracle.conf "
# echo "Sleeping 10 seconds for settings review ...   "
# echo "=============================================="
# echo ''

# sleep 10

# clear

if [ $NameServerExists -eq 0  ]
then
	if [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Unpacking LXC nameserver custom files...      "
		echo "=============================================="
		echo ''
	
		sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-cont.tar -C / --touch
		sudo sed -i 's/ubuntu\.common\.conf/common\.conf/' 	/var/lib/lxc/nsa/config

		function GetNameServerShortName {
			echo $NameServer | cut -f1 -d'-'
		}
		NameServerShortName=$(GetNameServerShortName)

		sudo sed -i "s/NAMESERVER/$NameServerShortName/"	/var/lib/lxc/nsa/rootfs/etc/dhcp/dhcpd.conf
	#	sudo sed -i '/nameserver/d' /etc/resolv.conf

		echo ''
		echo "=============================================="
		echo "Custom files unpack complete                  "
		echo "=============================================="
	fi

	sleep 10

	clear

	echo ''
	echo "=============================================="
	echo "Customize nameserver & domains ...            "
	echo "=============================================="
	echo ''

	function GetHostName {
		echo $HOSTNAME | cut -f1 -d'.'
	}
	HostName=$(GetHostName)

	if [ -n $Domain1 ] && [ $MultiHostVar2 = 'Y' ]
	then
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/network/openvswitch/crt_ovs_sw1.sh
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/dhcp/dhclient.conf
	fi
		
	if [ -n $Domain2 ] && [ $MultiHostVar2 = 'Y' ]
	then
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/network/openvswitch/crt_ovs_sw1.sh
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/dhcp/dhclient.conf
	fi

	if [ $MultiHostVar2 = 'N' ]
	then
		# Remove the extra nameserver line used for DNS DHCP setup and add the required nameservers.
	
		sudo sed -i '/8.8.8.8/d' /var/lib/lxc/nsa/rootfs/etc/resolv.conf > /dev/null 2>&1
		sudo sed -i '/nameserver/c\nameserver 10.207.39.2' /var/lib/lxc/nsa/rootfs/etc/resolv.conf > /dev/null 2>&1
		sudo sh -c "echo 'nameserver 10.207.29.2' >> /var/lib/lxc/nsa/rootfs/etc/resolv.conf" > /dev/null 2>&1
		sudo sh -c "echo 'search orabuntu-lxc.com consultingcommandos.us' >> /var/lib/lxc/nsa/rootfs/etc/resolv.conf" > /dev/null 2>&1

		if [ ! -z $HostName ]
		then
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/baremetal/s/baremetal/$HostName/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.consultingcommandos.us
		fi

		if [ -n $NameServer ]
		then
			# GLS 20151223 Settable Nameserver feature added
			# GLS 20161022 Settable Nameserver feature moved into DNS DHCP LXC container.
			# GLS 20162011 Settable Nameserver feature expanded to include nameserver and both domains.
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/nsa/s/nsa/$NameServerBase/g" /var/lib/lxc/nsa/rootfs/var/lib/bind/rev.consultingcommandos.us
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/config
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/etc/hostname
			sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/etc/hosts
                        sudo sed -i "/nsa/s/nsa/$NameServer/g" /var/lib/lxc/nsa/rootfs/root/crontab.txt

                       # function GetNameServerShortName {
                       #         echo $NameServer | cut -f1 -d'-'
                       # }
                       # NameServerShortName=$(GetNameServerShortName)

                        sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/ns_backup_update.lst
                        sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/ns_backup_update.sh
                        sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/ns_backup.start.sh
                        sudo sed -i "/nsa/s/nsa/$NameServerShortName/g" /var/lib/lxc/nsa/rootfs/root/dns-sync.sh

			sudo sed -i "/nsa/s/nsa/$NameServer/g" /etc/network/openvswitch/strt_nsa.sh
			sudo mv /var/lib/lxc/nsa /var/lib/lxc/$NameServer

                        sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1            /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1
                        sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1        /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1
                        sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1            /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1
                        sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1        /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1
                        sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1            /etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sw1
                        sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1        /etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sw1
                        sudo cp -p /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1            /etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sx1
                        sudo cp -p /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1        /etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sx1
                        sudo cp -p /etc/network/openvswitch/strt_nsa.sh                         /etc/network/openvswitch/strt_$NameServerBase.sh
                        sudo cp -p /etc/network/openvswitch/strt_nsa.sh                         /etc/network/openvswitch/strt_$NameServer.sh

                        echo "/etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sw1"             > /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sw1"        >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-up.d/openvswitch/$NameServerBase-pub-ifup-sx1"            >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-down.d/openvswitch/$NameServerBase-pub-ifdown-sx1"        >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1"                >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1"            >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1"                >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                        echo "/etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1"            >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
		fi

		if [ -n $Domain1 ]
		then
			# GLS 20151221 Settable Domain feature added
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/systemd/resolved.conf
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf > /dev/null 2>&1
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/NetworkManager/dnsmasq.d/local
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local
			sudo sed -i "/##R/s/##R//g"                             	/var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
		#	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.lst
			sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/$NameServer/rootfs/root/dns-thaw.sh
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain1
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain1
			
			if [ $Release -eq 6 ]
			then
				sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /etc/dhcp/dhclient.conf
			fi
		fi

		if [ -n $Domain2 ]
		then
			# GLS 20151221 Settable Domain feature added
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/systemd/resolved.conf
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf > /dev/null 2>&1
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/NetworkManager/dnsmasq.d/local
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
		#	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/root/ns_backup_update.lst
			sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/$NameServer/rootfs/root/dns-thaw.sh
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain2
			sudo mv /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain2
			if [ $Release -eq 6 ]
			then
				sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /etc/dhcp/dhclient.conf
			fi
		fi
	fi

	# Cleanup duplicate search lines in /etc/resolv.conf if Orabuntu-LXC has been re-run
	sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/resolv.conf
	sudo cat /etc/resolv.conf

	sleep 5

	echo ''
	echo "=============================================="
	echo "Customize nameserver & domains complete.      "
	echo "=============================================="
fi

sleep 5

clear

sudo chmod 755 /etc/network/openvswitch/*.sh

if   [ $MultiHostVar3 = 'X' ] && [ $GRE = 'Y' ] && [ $MultiHostVar2 = 'Y' ]
then
 	echo ''
 	echo "=============================================="
 	echo "Get sx1 IP address...                         "
 	echo "=============================================="
 	echo ''

	ssh-keygen -R $MultiHostVar5 > /dev/null 2>&1
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service dnsmasq restart > /dev/null 2>&1"

	Sx1Index=201
	function CheckHighestSx1IndexHit {
		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" nslookup -timeout=1 $Sx1Net.$Sx1Index" | grep -c 'name ='
	}
	HighestSx1IndexHit=$(CheckHighestSx1IndexHit)

	while [ $HighestSx1IndexHit = 1 ]
	do
       	 	Sx1Index=$((Sx1Index+1))
       	 	HighestSx1IndexHit=$(CheckHighestSx1IndexHit)
	done

 	echo ''
 	echo "=============================================="
 	echo "Get sw1 IP address.                           "
 	echo "=============================================="
 	echo ''

	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
	sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service dnsmasq restart > /dev/null 2>&1"

	Sw1Index=201
	function CheckHighestSw1IndexHit {
		sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" nslookup -timeout=1 $Sw1Net.$Sw1Index" | grep -c 'name ='
	}
	HighestSw1IndexHit=$(CheckHighestSw1IndexHit)

	while [ $HighestSw1IndexHit = 1 ]
	do
       	 	Sw1Index=$((Sw1Index+1))
       	 	HighestSw1IndexHit=$(CheckHighestSw1IndexHit)
	done

elif [ $MultiHostVar3 = 'X' ]  && [ $GRE = 'N' ] && [ $MultiHostVar2 = 'Y' ] && [ -f /etc/network/openvswitch/sx1.info ] && [ -f /etc/network/openvswitch/sw1.info ]
then
	if   [ $Release -eq 7 ] || [ $Release -eq 8 ]
	then
		function GetSx1Index {
			sudo cat /etc/network/openvswitch/sx1.info | cut -f2 -d':' | cut -f4 -d'.'
		}

	elif [ $Release -eq 6 ]
	then
		function GetSx1Index {
			sudo cat /etc/network/openvswitch/sx1.info | cut -f3 -d':' | cut -f4 -d'.'
		}
	fi
	Sx1Index=$(GetSx1Index)

	if   [ $Release -eq 7 ] || [ $Release -eq 8 ]
	then
		function GetSw1Index {
			sudo cat /etc/network/openvswitch/sw1.info | cut -f2 -d':' | cut -f4 -d'.'
		}

	elif [ $Release -eq 6 ]
	then
		function GetSw1Index {
			sudo cat /etc/network/openvswitch/sw1.info | cut -f3 -d':' | cut -f4 -d'.'
		}
	fi
	Sw1Index=$(GetSw1Index)
else
	Sw1Index=$MultiHostVar3
	Sx1Index=$MultiHostVar3
fi

sudo sed -i "s/SWITCH_IP/$Sx1Index/g" /etc/network/openvswitch/crt_ovs_sx1.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw1.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw2.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw3.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw4.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw5.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw6.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw7.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw8.sh
sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw9.sh

if [ $GRE = 'Y' ]
then
	sudo sed -i "s/mtu_request=1500/mtu_request=$MultiHostVar7/g" /etc/network/openvswitch/crt_ovs_sw1.sh
	sudo sed -i "s/mtu_request=1500/mtu_request=$MultiHostVar7/g" /etc/network/openvswitch/crt_ovs_sx1.sh
fi

if [ $LXDCluster = 'Y' ] && [ $LXDStorageDriver = 'btrfs' ]
then
        echo ''
        echo "=============================================="
        echo "Install packages...                           "
        echo "=============================================="
        echo ''

        sudo yum -y install dos2unix

	echo ''
        echo "=============================================="
        echo "Done: Install packages.                       "
        echo "=============================================="
        echo ''

	sleep 5

	clear

#	sudo sed -i "s/HOSTNAME/$HOSTNAME/g"    /etc/network/openvswitch/lxd-init-node1.sh

        if   [ $PreSeed = 'Y' ]
        then
                function GetShortHostName {
                        hostname -s
                }
                ShortHostName=$(GetShortHostName)

                if   [ $GRE = 'N' ]
                then
                        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"                                                   /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster
                        sudo sed -i "s/HOSTNAME/$ShortHostName/g"                                               /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster
                        sudo sed -i "s/BTRFSLUN/$BtrfsLun/g"                                               	/etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster
		#	sudo sed -i "s/STORAGE-DRIVER/$LXDStorageDriver/g"                                      /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster
		#	sudo sed -i "s/POOL/$StoragePoolName/g"                                                 /etc/network/openvswitch/preseed.sw1a.oracle8.linux.001.lxd.cluster

                elif [ $GRE = 'Y' ]
                then
                        sshpass -p $MultiHostVar8 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S --prompt='' <<< "$MultiHostVar8" /var/lib/snapd/snap/bin/lxc info | sed -n '/BEGIN.*-/,/END.*-/p'" > /tmp/cert.txt
			rm /tmp/cert.txt
                        sshpass -p $MultiHostVar8 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S --prompt='' <<< "$MultiHostVar8" /var/lib/snapd/snap/bin/lxc info | sed -n '/BEGIN.*-/,/END.*-/p'" > /tmp/cert.txt

			echo ''
			echo "=============================================="
			echo "Display /tmp/cert.txt ...                     "
			echo "=============================================="
			echo ''

			cat /tmp/cert.txt

			echo ''
			echo "=============================================="
			echo "Done: Display /tmp/cert.txt.                  "
			echo "=============================================="
			echo ''

			sleep 5

			clear

                        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"                                                   /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster
                        sudo sed -i "s/HOSTNAME/$ShortHostName/g"                                               /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster
                        sudo sed -i "s/BTRFSLUN/$BtrfsLun/g"                                               	/etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster
		#	sudo sed -i "s/STORAGE-DRIVER/$LXDStorageDriver/g"                                      /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster
		#	sudo sed -i "s/POOL/$StoragePoolName/g"                                                 /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster
                        sudo sed -i -e '/-----BEGIN/,/-----END/!b' -e '/-----END/!d;r /tmp/cert.txt' -e 'd'     /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster
			sudo dos2unix										/etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster

			echo ''
			echo "=============================================="
			echo "Display LXD Preseed...                        "
			echo "=============================================="
			echo ''

			sudo cat /etc/network/openvswitch/preseed.sw1a.oracle8.linux.002.lxd.cluster

			echo ''
			echo "=============================================="
			echo "Done: Display LXD Preseed.                    "
			echo "=============================================="
			echo ''

			sleep 5

			clear
                fi
        fi
fi

if [ $LXDCluster = 'Y' ] && [ $LXDStorageDriver = 'zfs' ]
then
        echo ''
        echo "=============================================="
        echo "Install packages...                           "
        echo "=============================================="
        echo ''

        sudo yum -y install expect dos2unix

        echo ''
        echo "=============================================="
        echo "Done: Install packages.                       "
        echo "=============================================="
        echo ''

        sleep 5

        clear

        sudo sed -i "s/HOSTNAME/$HOSTNAME/g"    /etc/network/openvswitch/lxd-init-node1.sh

        if   [ $PreSeed = 'Y' ]
        then
                function GetShortHostName {
                        hostname -s
                }
                ShortHostName=$(GetShortHostName)

                if   [ $GRE = 'N' ]
                then
                        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"                                                   /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster
                        sudo sed -i "s/HOSTNAME/$ShortHostName/g"                                               /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster
                        sudo sed -i "s/STORAGE-DRIVER/$LXDStorageDriver/g"                                      /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster
                        sudo sed -i "s/POOL/$StoragePoolName/g"                                                 /etc/network/openvswitch/preseed.sw1a.olxc.001.lxd.cluster

                elif [ $GRE = 'Y' ]
                then
                        sshpass -p $MultiHostVar8 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S --prompt='' <<< "$MultiHostVar8" /var/lib/snapd/snap/bin/lxc info | sed -n '/BEGIN.*-/,/END.*-/p'" > /tmp/cert.txt
                        rm /tmp/cert.txt
                        sshpass -p $MultiHostVar8 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S --prompt='' <<< "$MultiHostVar8" /var/lib/snapd/snap/bin/lxc info | sed -n '/BEGIN.*-/,/END.*-/p'" > /tmp/cert.txt

                        echo ''
                        echo "=============================================="
                        echo "Display /tmp/cert.txt ...                     "
                        echo "=============================================="
                        echo ''

                        cat /tmp/cert.txt

                        echo ''
                        echo "=============================================="
                        echo "Done: Display /tmp/cert.txt.                  "
                        echo "=============================================="
                        echo ''

                        sleep 5

                        clear

                        sudo sed -i "s/SWITCH_IP/$Sw1Index/g"                                                   /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i "s/HOSTNAME/$ShortHostName/g"                                               /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i "s/STORAGE-DRIVER/$StorageDriver/g"                                         /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i "s/POOL/$StoragePoolName/g"                                                 /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo sed -i -e '/-----BEGIN/,/-----END/!b' -e '/-----END/!d;r /tmp/cert.txt' -e 'd'     /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster
                        sudo dos2unix                                                                           /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster

                        echo ''
                        echo "=============================================="
                        echo "Display LXD Preseed...                        "
                        echo "=============================================="
                        echo ''

                        sudo cat /etc/network/openvswitch/preseed.sw1a.olxc.002.lxd.cluster

                        echo ''
                        echo "=============================================="
                        echo "Done: Display LXD Preseed.                    "
                        echo "=============================================="
                        echo ''

                        sleep 5

                        clear
                fi
        fi
fi

sleep 5

clear

SwitchList='sw1 sx1'
for k in $SwitchList
do
	if   [ $Release -ge 7 ]
	then
		echo ''
		echo "=============================================="
		echo "Create OpenvSwitch systemd $k service...      "
		echo "=============================================="
		echo ''

       		if [ ! -f /etc/systemd/system/$k.service ]
       		then
       	        	sudo sh -c "echo '[Unit]'						 > /etc/systemd/system/$k.service"
       	         	sudo sh -c "echo 'Description=$k Service'				>> /etc/systemd/system/$k.service"
		
			if [ $k = 'sw1' ]
			then
                		sudo sh -c "echo 'Wants=network-online.target'			>> /etc/systemd/system/$k.service"
                		sudo sh -c "echo 'After=network-online.target'			>> /etc/systemd/system/$k.service"
			fi
			if [ $k = 'sx1' ]
			then
                		sudo sh -c "echo 'Wants=network-online.target'			>> /etc/systemd/system/$k.service"
                		sudo sh -c "echo 'After=network-online.target sw1.service'	>> /etc/systemd/system/$k.service"
			fi

               	 	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
               	 	sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'Type=oneshot'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/crt_ovs_$k.sh' 	>> /etc/systemd/system/$k.service"
			sudo sh -c "echo 'ExecStop=/usr/bin/ovs-vsctl del-br $k'                >> /etc/systemd/system/$k.service"
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'WantedBy=multi-user.target'				>> /etc/systemd/system/$k.service"
		
			echo ''
			echo "=============================================="
			echo "Done: Create OpenvSwitch systemd $k service.  "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "Start OpenvSwitch $k ...                      "
			echo "=============================================="
			echo ''
		
       			sudo chmod 644 /etc/systemd/system/$k.service
			sudo systemctl daemon-reload
       			sudo systemctl enable $k.service
			sudo service $k start
			sudo service $k status
	
			echo ''
			echo "=============================================="
			echo "Done: Start OpenvSwitch $k.                   "
			echo "=============================================="

			sleep 5

			clear
		else
			echo ''
			echo "=============================================="
			echo "OpenvSwitch $k previously installed.          "
			echo "=============================================="
			echo ''
		
			sleep 5

			clear
        	fi

		echo ''
		echo "=============================================="
		echo "Installed OpenvSwitch $k.                     "
		echo "=============================================="

		sleep 5

		clear

	elif [ $Release -eq 6 ]
	then
		echo ''
		echo "=============================================="
		echo "Create OpenvSwitch init.d $k service...       "
		echo "=============================================="
		echo ''

                if [ ! -f /etc/init.d/ovs_$k ]
       		then
			sudo cp -p /etc/network/openvswitch/switch-service-linux6.sh /etc/init.d/ovs_$k
			sudo sed -i "s/SWK/$k/g" /etc/init.d/ovs_$k
			sudo chmod 755 /etc/init.d/ovs_$k
			sudo chown $Owner:$Group /etc/init.d/ovs_$k
			sudo chkconfig --add ovs_$k
			sudo chkconfig ovs_$k on --level 345
			sudo chkconfig --list ovs_$k
		
			echo ''
			echo "=============================================="
			echo "Done: Create OpenvSwitch systemd $k service.  "
			echo "=============================================="
			echo ''
			echo "=============================================="
			echo "Start OpenvSwitch $k ...                      "
			echo "=============================================="
			echo ''
		
			sudo /etc/network/openvswitch/crt_ovs_$k.sh >/dev/null 2>&1
			sleep 2
			sudo ifconfig $k

                        echo "=============================================="
                        echo "Done: Start OpenvSwitch $k                    "
                        echo "=============================================="
                        echo ''

			sleep 5

			clear
		else
			echo ''
			echo "=============================================="
			echo "OpenvSwitch $k previously installed.          "
			echo "=============================================="
			echo ''
		
			sleep 5

			clear
		fi
	fi

	sleep 5

	clear
done

echo ''
echo "=============================================="
echo "Ensure Networks up...                         "
echo "=============================================="
echo ''

sudo ifconfig sw1
sudo ifconfig sx1

echo ''
echo "=============================================="
echo "Networks are up.                              "
echo "=============================================="
echo ''

sleep 5

clear

if [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Setting secret in dhcpd.conf file...          "
	echo "=============================================="
	echo ''

	function GetKeySecret {
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/bind/rndc.key | grep secret | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	KeySecret=$(GetKeySecret)
	echo $KeySecret
	sudo sed -i "/secret/c\key rndc-key { algorithm hmac-sha256; $KeySecret }" /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf
	echo 'The following keys should match (for dynamic DNS updates by DHCP):'
	echo ''
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf | grep secret | cut -f7 -d' ' | cut -f1 -d';'
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/bind/rndc.key   | grep secret | cut -f2 -d' ' | cut -f1 -d';'
	echo ''
	sudo cat /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf | grep secret

	echo ''
	echo "=============================================="
	echo "Secret successfuly set in dhcpd.conf file.    "
	echo "=============================================="

	sleep 5

	clear
fi

sleep 5

clear

if [ $Release -ge 7 ]
then
	echo ''
	echo "=============================================="
	echo "Checking OpenvSwitch sw1 service...           "
	echo "=============================================="
	echo ''

	sudo service sw1 stop
	sleep 2
	sudo systemctl start sw1
	sleep 2
	echo ''
	sudo ifconfig sw1
	echo ''
	sudo service sw1 status

	echo ''
	echo "=============================================="
	echo "OpenvSwitch sw1 service is up.                "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Checking OpenvSwitch service sx1...           "
	echo "=============================================="
	echo ''

	sudo service sx1 stop
	sleep 2
	sudo systemctl start sx1
	sleep 2
	echo ''
	sudo ifconfig sx1
	echo ''
	sudo service sx1 status

	echo ''
	echo "=============================================="
	echo "OpenvSwitch service sx1 is up.                "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Both required networks are up.                "
echo "=============================================="
echo ''

sleep 5

clear

if [ $GRE = 'Y' ] || [ $MultiHostVar3 != 'X' ]
then
	echo ''
	echo "=============================================="
	echo "Verify iptables rules are set correctly...    "
	echo "=============================================="
	echo ''

	sudo iptables -S | egrep 'sw1|sx1'

	echo ''
	echo "=============================================="
	echo "Verification of iptables rules complete.      "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ] && [ $MultiHostVar2 = 'N' ]
then
        sudo lxc-update-config -c /var/lib/lxc/$NameServer/config
fi

echo ''
echo "=============================================="
echo "Install Packages for Filesystem Check...      "
echo "=============================================="
echo ''

sudo yum -y install xfsprogs xfsdump xfsprogs-devel xfsprogs-qa-devel

echo ''
echo "=============================================="
echo "Done: Install Packages for Filesystem Check.  "
echo "=============================================="
echo ''

sleep 5

clear

if [ $MultiHostVar2 = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Start LXC DNS DHCP container...               "
	echo "=============================================="
	echo ''

	if [ -n $NameServer ]
	then
		if [ $Release -ge 7 ]
		then
			echo ''
			echo "=============================================="
			echo "Restart OpenvSwitches...                      "
			echo "=============================================="
			echo ''

 			sudo service sw1 restart 
 			sudo service sx1 restart
			
			echo ''
			echo "=============================================="
			echo "Done: Restart OpenvSwitches...                "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		fi

	        function CheckFileSystemTypeXfs {
			stat --file-system --format=%T /var/lib/lxc | grep -c xfs
       		}
        	FileSystemTypeXfs=$(CheckFileSystemTypeXfs)

	        function CheckFileSystemTypeExt {
			stat --file-system --format=%T /var/lib/lxc | grep -c ext
       		}
        	FileSystemTypeExt=$(CheckFileSystemTypeExt)

	        function CheckFileSystemTypeBtrfs {
			stat --file-system --format=%T /var/lib/lxc | grep -c btrfs
       		}
        	FileSystemTypeBtrfs=$(CheckFileSystemTypeBtrfs)

		function GetNameServerBase {
			echo $NameServer | cut -f1 -d'-'
		}
		NameServerBase=$(GetNameServerBase)

		if [ $FileSystemTypeXfs -eq 1 ]
		then
        		function GetFtype {
                		xfs_info / | grep -c ftype=1
        		}
        		Ftype=$(GetFtype)

			if   [ $Ftype -eq 0 ]
			then
				sudo lxc-stop -n $NameServer > /dev/null 2>&1
 				sudo lxc-copy -n $NameServer -N $NameServerBase
				NameServer=$NameServerBase
				sudo lxc-start -n $NameServer

			elif [ $Ftype -eq 1 ]
			then
				if [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 8 ]
				then				
	                		sudo lxc-stop -n $NameServer > /dev/null 2>&1
					sudo lxc-copy -n $NameServer -N $NameServerBase -B overlayfs -s
					NameServer=$NameServerBase
					sudo lxc-start -n $NameServer
				else
	                		sudo lxc-stop -n $NameServer > /dev/null 2>&1
					sudo lxc-copy -n $NameServer -N $NameServerBase -B overlayfs -s
					NameServer=$NameServerBase
					sudo lxc-start -n $NameServer
				fi	
			fi
		fi

		if [ $FileSystemTypeExt -eq 1 ]
		then
			if   [ $LinuxFlavor = 'CentOS' ]
			then
				if   [ $Release -ge 7 ]
				then
					sudo lxc-stop -n $NameServer > /dev/null 2>&1
					sudo lxc-copy -n $NameServer -N $NameServerBase -B overlayfs -s
					NameServer=$NameServerBase
					sudo lxc-start -n $NameServer

				elif [ $Release -eq 6 ]
				then
					sudo lxc-stop -n $NameServer > /dev/null 2>&1
					sudo lxc-copy -n $NameServer -N $NameServerBase -B overlayfs -s
				#	sudo lxc-copy -n $NameServer -n afns1
					NameServer=$NameServerBase
					sudo lxc-start -n $NameServer
				fi
			elif [ $LinuxFlavor = 'Oracle' ] 
			then
				if   [ $Release -eq 6 ] && [ $RHMV -eq 10 ]
				then
					function CheckUEKVersion {
						sudo /opt/olxc/"$DistDir"/anylinux/vercomp | cut -f2 -d"'" | cut -f1 -d' ' | cut -f1 -d'.'
					}
					UEKVersion=$(CheckUEKVersion)

					if   [ $UEKVersion -eq 3 ]
					then
						sudo lxc-stop -n $NameServer > /dev/null 2>&1
						sudo lxc-copy -n $NameServer -N $NameServerBase
						NameServer=$NameServerBase
						sudo lxc-start -n $NameServer

					elif [ $UEKVersion -eq 4 ]
					then
						sudo lxc-stop -n $NameServer > /dev/null 2>&1
						sudo lxc-copy -n $NameServer -N $NameServerBase -B overlayfs -s
						NameServer=$NameServerBase
						sudo lxc-start -n $NameServer
					fi
				fi
			else
				sudo lxc-stop -n $NameServer > /dev/null 2>&1
				sudo lxc-copy -n $NameServer -N $NameServerBase -B overlayfs -s
				NameServer=$NameServerBase
				sudo lxc-start -n $NameServer
			fi
		fi
	
		if [ $FileSystemTypeBtrfs -eq 1 ]
		then
			sudo lxc-copy  -n $NameServer -N $NameServerBase -B overlayfs -s
 		#	sudo lxc-copy  -n $NameServer -N $NameServerBase
		#	sudo lxc-copy  -n $NameServer -n afns1
			sleep 5
			NameServer=$NameServerBase
			sudo lxc-start -n $NameServer
		fi
	fi

	echo ''
	echo "=============================================="
	echo "Display $NameServer Info...                   "
	echo "=============================================="
	echo ''

	sudo lxc-info $NameServer | head -3

	echo ''
	echo "=============================================="
	echo "Done: Display $NameServer Info.               "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	if [ $Release -ge 7 ]
	then
		if [ ! -f /etc/systemd/system/$NameServer.service ]
		then
			echo ''
			echo "=============================================="
			echo "Create $NameServer Onboot Service...          "
			echo "=============================================="
			echo ''

			sudo sh -c "echo '[Unit]'             	         				 > /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'Description=$NameServer Service'  				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'Wants=network-online.target sw1.service sx1.service'		>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'After=network-online.target sw1.service sx1.service'		>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo ''                                 				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo '[Service]'                        				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'Type=oneshot'                     				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'User=root'                        				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'RemainAfterExit=yes'              				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/strt_$NameServer.sh start'	>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'ExecStop=/etc/network/openvswitch/strt_$NameServer.sh stop'	>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo ''                                 				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo '[Install]'                        				>> /etc/systemd/system/$NameServer.service"
			sudo sh -c "echo 'WantedBy=multi-user.target'       				>> /etc/systemd/system/$NameServer.service"
			sudo chmod 644 /etc/systemd/system/$NameServer.service

			echo "/etc/systemd/system/$NameServer.service" >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
			sudo cp -p /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst ~/nameserver.lst
			sudo sed -i "s/-base//g" /etc/network/openvswitch/strt_$NameServer.sh

			sudo systemctl enable $NameServer

			echo ''
			echo "=============================================="
			echo "Created $NameServer Onboot Service.           "
			echo "=============================================="
		fi

	elif [ $Release -eq 6 ]
	then
		if [ ! -f /etc/init.d/lxc_$NameServer ]
		then
			echo ''
			echo "=============================================="
			echo "Create $NameServer Onboot Service...          "
			echo "=============================================="
			echo ''

			sudo cp -p /etc/network/openvswitch/container-service-linux6.sh /etc/init.d/lxc_$NameServer
			sudo sed -i "s/LXCON/$NameServer/g" /etc/init.d/lxc_$NameServer
			sudo chmod 755 /etc/init.d/lxc_$NameServer
			sudo chown $Owner:$Group /etc/init.d/lxc_$NameServer
			sudo chkconfig --add lxc_$NameServer
			sudo chkconfig lxc_$NameServer on --level 345
			sudo chkconfig --list lxc_$NameServer

			echo ''
			echo "=============================================="
			echo "Done: Create $NameServer Onboot Service.      "
			echo "=============================================="
		fi
	fi
	
	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Done: Start LXC DNS DHCP container.           "
	echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Block eth0 DHCP in $NameServer...             "
echo "=============================================="
echo ''

function GetNameServerEth0MacAddress {
        sudo lxc-attach -n $NameServer -- ifconfig eth0 | grep ether | sed 's/^[ \t]*//' | cut -f2 -d' '
}
NameServerEth0MacAddress=$(GetNameServerEth0MacAddress)
echo "NSEMA = "$NameServerEth0MacAddress

sudo lxc-attach -n $NameServer -- cat /etc/dhcp/dhcpd.conf | grep 'hardware ethernet' | sed 's/^[ \t]*//' | cut -f3 -d' '
sudo lxc-attach -n $NameServer -- sed -i "/hardware ethernet 00:16:3e:ce:de:25/s/00:16:3e:ce:de:25/$NameServerEth0MacAddress/" /etc/dhcp/dhcpd.conf
sudo lxc-attach -n $NameServer -- service isc-dhcp-server stop
sudo lxc-attach -n $NameServer -- service isc-dhcp-server start
sleep 5
sudo lxc-attach -n $NameServer -- cat /etc/dhcp/dhcpd.conf | grep 'hardware ethernet' | sed 's/^[ \t]*//' | cut -f3 -d' '
sudo lxc-attach -n $NameServer -- service isc-dhcp-server status

echo ''
echo "=============================================="
echo "Done: Block eth0 DHCP in $NameServer.         "
echo "=============================================="
echo ''

sleep 5

clear

# if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'Y' ] && [ $GRE = 'Y' ]
# GLS 20180202 Allow VMs to get a copy of the NameServer container(s).

if [ $NameServerExists -eq 0 ] && [ $MultiHostVar2 = 'Y' ]
then
        echo ''
        echo "=============================================="
        echo "Replicate nameserver $NameServer...           "
        echo "=============================================="
        echo ''

	NameServer=$NameServerBase
	sudo mkdir -p /home/$Owner/Manage-Orabuntu
        sudo chown $Owner:$Group /home/$Owner/Manage-Orabuntu
        sudo chmod 775 /opt/olxc/"$DistDir"/uekulele/archives/nameserver_copy.sh
        /opt/olxc/"$DistDir"/uekulele/archives/nameserver_copy.sh $MultiHostVar5 $MultiHostVar6 $MultiHostVar8 $MultiHostVar9 $NameServerBase $Release $LinuxFlavor

        echo ''
        echo "=============================================="
        echo "Done: Replicate nameserver $NameServer.       "
        echo "=============================================="
        echo ''

        # Case 1 importing nameserver from an 2.1+ LXC enviro into a 2.0- LXC enviro.

        function CheckNameServerConfigFormat {
                sudo grep -c lxc.net.0 /var/lib/lxc/$NameServer/config
        }
        NameServerConfigFormat=$(CheckNameServerConfigFormat)

        function CheckNameServerBaseConfigFormat {
                sudo grep -c lxc.net.0 /var/lib/lxc/"$NameServer"-base/config
        }
        NameServerBaseConfigFormat=$(CheckNameServerBaseConfigFormat)

        if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion 2.1.0) ] && [ $NameServerConfigFormat -gt 0 ]
        then
                sudo sed -i 's/lxc.net.0/lxc.network/g'         /var/lib/lxc/$NameServer/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'         /var/lib/lxc/$NameServer/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'      /var/lib/lxc/$NameServer/config

                sudo sed -i 's/lxc.net.0/lxc.network/g'         /var/lib/lxc/"$NameServer"-base/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'         /var/lib/lxc/"$NameServer"-base/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'      /var/lib/lxc/"$NameServer"-base/config
        fi

        # Case 2 importing nameserver from an 2.0- LXC enviro into a 2.1+ LXC enviro.

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion 2.1.0) ] && [ $NameServerConfigFormat -eq 0 ]
        then
                sudo lxc-update-config -c /var/lib/lxc/"$NameServer"/config
                sudo lxc-update-config -c /var/lib/lxc/"$NameServerBase"/config
		sudo lxc-update-config -c /var/lib/lxc/"$NameServer"-base/config
        fi

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion 2.1.0) ] && [ $NameServerBaseConfigFormat -eq 0 ]
        then
                sudo lxc-update-config -c /var/lib/lxc/"$NameServer"/config
                sudo lxc-update-config -c /var/lib/lxc/"$NameServerBase"/config
		sudo lxc-update-config -c /var/lib/lxc/"$NameServer"-base/config
        fi

        sudo lxc-ls -f
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Checking and Configuring MultiHost Settings..."
echo "=============================================="
echo ''

if [ $MultiHostVar2 = 'N' ]
then
#	GLS 20170904 Switches sx1 and sw1 are set earlier so they are not set here.

	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw2.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw3.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw4.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw5.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw6.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw7.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw8.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw9.sh

	echo ''
	echo "=============================================="
	echo "Unpack SCST Linux SAN Files...                "
	echo "=============================================="
	echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/scst-files.tar -C / --touch

	sudo chown -R $Owner:$Group		        /opt/olxc/home/scst-files/.
        sudo sed -i "s/\"SWITCH_IP\"/$Sw1Index/g"	/opt/olxc/home/scst-files/create-scst-target.sh

	echo ''
	echo "=============================================="
	echo "Done: Unpack SCST Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Unpack TGT Linux SAN Files...                "
	echo "=============================================="
	echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/tgt-files.tar  -C / --touch
	
	echo ''
	echo "=============================================="
	echo "Done: Unpack TGT Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Setting ubuntu user password in $NameServer..."
	echo "=============================================="
	echo ''

	sudo lxc-attach -n $NameServer -- usermod --password `perl -e "print crypt('ubuntu','ubuntu');"` ubuntu
	ssh-keygen -q -R 10.207.39.2
	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "date; uname -a"
	
	echo ''
	echo "=============================================="
	echo "Done: Set ubuntu password in $NameServer.     "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
        echo "Configure jobs in $NameServer...              "
	echo "=============================================="
	echo ''

	sleep 5

        genpasswd() { 
                local l=$1 
                [ "$l" == "" ] && l=8
                tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs 
        }
        password=$(genpasswd)

        USERNAME=amide
        PASSWORD=$password

        sudo sed -i "s/Owner=ubuntu/Owner=amide/"       /var/lib/lxc/"$NameServer"-base/rootfs/root/ns_backup_update.sh
        sudo sed -i "s/Pass=ubuntu/Pass=$password/"     /var/lib/lxc/"$NameServer"-base/rootfs/root/ns_backup_update.sh

	sudo useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash ${USERNAME}
	sudo mkdir -p  /home/${USERNAME}/Downloads 

        function CutOffBase {
                echo $NameServer | cut -f1 -d'-'
        }
        OffBase=$(CutOffBase)

	sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
	sudo mkdir -p /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$OffBase/updates

	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Downloads 
	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Manage-Orabuntu
	sudo chmod -R 777 /home/${USERNAME}/Manage-Orabuntu

	sudo sed -i "/lxc\.mount\.entry/s/#/ /" /var/lib/lxc/$NameServer/config
	sudo sed -i "/Manage\-Orabuntu/s/afns1\-base/afns1/" /var/lib/lxc/$NameServer/config

#	sudo cat /var/lib/lxc/"$OffBase"-base/rootfs/root/ns_backup_update.sh

        sudo lxc-stop -n  $NameServer
	sleep 5
        sudo lxc-start -n $NameServer

	clear

	echo ''
	echo "=============================================="
        echo "Done: Configure jobs in $NameServer.          "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
        echo "Create amide user RSA key...                  "
	echo "=============================================="
	echo ''

	sudo runuser -l amide -c "ssh-keygen -f /home/amide/.ssh/id_rsa -t rsa -N ''"

	echo ''
	echo "=============================================="
        echo "Done: Create amide user RSA key.              "
	echo "=============================================="

	sleep 5

	clear

	sudo sh -c "echo 'amide ALL=/bin/mkdir, /bin/cp' > /etc/sudoers.d/amide"
	sudo chmod 0440 /etc/sudoers.d/amide

	sudo lxc-attach -n $NameServer -- crontab /root/crontab.txt
	
	echo ''
	echo "=============================================="
        echo "Display $NameServer replica cronjob...        "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n $NameServer -- crontab -l | tail -23
	
	echo ''
	echo "=============================================="
        echo "Done: Display $NameServer replica cronjob.    "
	echo "=============================================="
	echo ''

	sleep 5

	clear

#	sudo lxc-attach -n $NameServer -- mkdir -p /root/backup-lxc-container/$NameServer/updates
#	sudo lxc-attach -n $NameServer -- tar -czPf /root/backup-lxc-container/$NameServer/updates/backup_"$NameServer"_ns_update.tar.gz /root/ns_backup_update.lst

	echo ''
	echo "=============================================="
        echo "Extract DNS sync service files ...            "
	echo "=============================================="
	echo ''

#       sudo lxc-attach -n $NameServer -- mkdir -p /root/backup-lxc-container/$NameServer/updates
        sudo lxc-attach -n $NameServer -- touch /root/gre_hosts.txt
        sudo lxc-attach -n $NameServer -- touch /home/ubuntu/gre_hosts.txt

#       sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" echo $HOSTNAME > ~/new_gre_host.txt"
#       sudo lxc-attach -n $NameServer -- cat ~/new_gre_host.txt
#       sleep 5
        
	sudo lxc-attach -n $NameServer -- tar -cvzPf /root/backup-lxc-container/$NameServer/updates/backup_"$NameServer"_ns_update.tar.gz -T /root/ns_backup_update.lst --numeric-owner
        
#	echo ''
#       echo "=============================================="
#       echo "Debug of new file transfer mechanism ...      "
#       echo "=============================================="
#       echo ''

#       sudo ls -l /home/amide/Manage-Orabuntu/backup-lxc-container/afns1/updates
#       sudo lxc-attach -n $NameServer -- ls -l /root/backup-lxc-container/afns1/updates

#       echo "sleeping for 30 seconds ..."

#       sleep 30

        sudo tar -v --extract --file=/opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-cont.tar -C / var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-sync.service
        sudo tar -v --extract --file=/opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-cont.tar -C / var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-thaw.service
        sudo mv /var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-sync.service /var/lib/lxc/"$NameServer"-base/rootfs/etc/systemd/system/dns-sync.service
        sudo mv /var/lib/lxc/nsa/rootfs/etc/systemd/system/dns-thaw.service /var/lib/lxc/"$NameServer"-base/rootfs/etc/systemd/system/dns-thaw.service

        sudo lxc-attach -n $NameServer -- systemctl enable dns-sync
        sudo lxc-attach -n $NameServer -- systemctl enable dns-thaw
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/fwd.$Domain1
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/rev.$Domain1
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/fwd.$Domain2
        sudo lxc-attach -n $NameServer -- chown bind:bind /var/lib/bind/rev.$Domain2
        sudo lxc-attach -n $NameServer -- chown root:bind /var/lib/bind
        sudo lxc-attach -n $NameServer -- chmod 775 /var/lib/bind
	
	echo ''
	echo "=============================================="
        echo "Done: Extract DNS sync service files.         "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
        echo "Create $NameServer RSA key...                 "
	echo "=============================================="
	echo ''

	sudo lxc-attach -n $NameServer -- ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
	
	echo ''
	echo "=============================================="
        echo "Done: Create $NameServer RSA key.             "
	echo "=============================================="
	echo ''
	
	sleep 5

	clear

	sudo sh -c "cat '/var/lib/lxc/$NameServerBase/delta0/root/.ssh/id_rsa.pub' >> /home/amide/.ssh/authorized_keys" > /dev/null 2>&1
	sudo sh -c "cat '/var/lib/lxc/$NameServer/delta0/root/.ssh/id_rsa.pub' >> /home/amide/.ssh/authorized_keys" > /dev/null 2>&1
	sleep 5
               
	echo ''
	echo "=============================================="
        echo "Done: Configure jobs in $NameServer.          "
	echo "=============================================="
fi

sleep 5

clear

if [ $MultiHostVar2 = 'Y' ]
then
#	GLS 20170904 Switches sx1 and sw1 are set earlier (around lines 1988,1989) so they are not set here.

	# sudo cat /etc/network/openvswitch/sx1.info | cut -f2 -d':' | cut -f4 -d'.'

	if [ -f /etc/network/openvswitch/sx1.info ]
	then
		function GetSx1Index {
			sudo sh -c "cat '/etc/network/openvswitch/sx1.info' | cut -f2 -d':' | cut -f4 -d'.'"
		}
		Sx1Index=$(GetSx1Index)
	fi

	# sudo cat /etc/network/openvswitch/sw1.info | cut -f2 -d':' | cut -f4 -d'.'

	if [ -f /etc/network/openvswitch/sw1.info ]
	then
		function GetSw1Index {
			sudo sh -c "cat '/etc/network/openvswitch/sw1.info' | cut -f2 -d':' | cut -f4 -d'.'"
		}
		Sw1Index=$(GetSx1Index)
	fi

	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw2.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw3.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw4.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw5.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw6.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw7.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw8.sh
	sudo sed -i "s/SWITCH_IP/$Sw1Index/g" /etc/network/openvswitch/crt_ovs_sw9.sh
	
	echo ''
	echo "=============================================="
	echo "Unpack SCST Linux SAN Files...                "
	echo "=============================================="
	echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/scst-files.tar -C / --touch

	sudo chown -R $Owner:$Group		        /opt/olxc/home/scst-files/.
        sudo sed -i "s/\"SWITCH_IP\"/$Sw1Index/g"	/opt/olxc/home/scst-files/create-scst-target.sh

	echo ''
	echo "=============================================="
	echo "Done: Unpack SCST Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Unpack TGT Linux SAN Files...                "
	echo "=============================================="
	echo ''

        sudo tar -xvf /opt/olxc/"$DistDir"/uekulele/archives/tgt-files.tar  -C / --touch
	
	echo ''
	echo "=============================================="
	echo "Done: Unpack TGT Linux SAN Files.            "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Configure NS Replication Account...           "
	echo "=============================================="
	echo ''

	function GetAmidePassword {
                sudo sh -c "cat /var/lib/lxc/$NameServerBase-base/rootfs/root/ns_backup_update.sh" | grep 'Pass=' | cut -f2 -d'='
        }
        AmidePassword=$(GetAmidePassword)

	USERNAME=amide
	PASSWORD=$AmidePassword

	sudo useradd -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash ${USERNAME}
	sudo mkdir -p  /home/${USERNAME}/Downloads /home/${USERNAME}/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
	sudo chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/Downloads /home/${USERNAME}/Manage-Orabuntu
	sudo runuser -l amide -c "ssh-keygen -f /home/amide/.ssh/id_rsa -t rsa -N ''"
	sudo sh -c "cat '/var/lib/lxc/$NameServerBase/delta0/root/.ssh/id_rsa.pub' >> /home/amide/.ssh/authorized_keys"
	sudo sed -i "/lxc\.mount\.entry/s/#/ /" /var/lib/lxc/$NameServer/config
	sudo sh -c "echo 'amide ALL=/bin/mkdir, /bin/cp' > /etc/sudoers.d/amide"
	sudo chmod 0440 /etc/sudoers.d/amide

	echo ''
	echo "=============================================="
	echo "Done: Configure NS Replication Account.       "
	echo "=============================================="
	echo ''
	
	sleep 5

	clear

	if [ $GRE = 'Y' ]
	then
		sudo sed -i "/route add -net/s/#/ /"				/etc/network/openvswitch/crt_ovs_sw1.sh	
		sudo sed -i "/REMOTE_GRE_ENDPOINT/s/#/ /"			/etc/network/openvswitch/crt_ovs_sw1.sh	
		sudo sed -i "s/REMOTE_GRE_ENDPOINT/$MultiHostVar5/g"		/etc/network/openvswitch/crt_ovs_sw1.sh

		if   [ $TunType = 'geneve' ]
                then
                        sudo ovs-vsctl add-port sw1 geneve$Sw1Index trunks=10,11 -- set interface geneve$Sw1Index type=geneve options:remote_ip=$MultiHostVar5 options:key=flow

                        sudo sed -i '/type=gre/d'   /etc/network/openvswitch/crt_ovs_sw1.sh
                        sudo sed -i '/type=vxlan/d' /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo firewall-cmd --permanent --zone=public --add-port=6081/udp
			sudo firewall-cmd --permanent --zone=public --add-interface=genev_sys_6081
			sudo firewall-cmd --reload

                elif [ $TunType = 'gre' ]
                then
                        sudo ovs-vsctl add-port sw1 gre$Sw1Index trunks=10,11 -- set interface gre$Sw1Index type=gre options:remote_ip=$MultiHostVar5

                        sudo sed -i '/type=geneve/d' /etc/network/openvswitch/crt_ovs_sw1.sh
                        sudo sed -i '/type=vxlan/d'  /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo firewall-cmd --permanent --zone=public --add-protocol=gre
			sudo firewall-cmd --permanent --zone=public --add-interface=gre_sys
			sudo firewall-cmd --reload

                elif [ $TunType = 'vxlan' ]
                then
                        sudo ovs-vsctl add-port sw1 vxlan$Sw1Index trunks=10,11 -- set interface vxlan$Sw1Index type=vxlan options:remote_ip=$MultiHostVar5 options:key=flow

                        sudo sed -i '/type=geneve/d' /etc/network/openvswitch/crt_ovs_sw1.sh
                        sudo sed -i '/type=gre/d'    /etc/network/openvswitch/crt_ovs_sw1.sh
			sudo firewall-cmd --permanent --zone=public --add-port=4789/udp
			sudo firewall-cmd --permanent --zone=public --add-interface=vxlan_sys_4789
			sudo firewall-cmd --reload

                fi

                echo ''
                echo "=============================================="
                echo "Show local GRE endpoint...                    "
                echo "=============================================="
                echo ''
	
		sudo ovs-vsctl show | grep -A1 -B2 'type: gre' | grep -B4 "$MultiHostVar5" | sed 's/^[ \t]*//;s/[ \t]*$//'

                echo ''
                echo "=============================================="
                echo "Done: Show local GRE endpoint.                "
                echo "=============================================="
                echo ''
	
		sudo cp -p /etc/network/openvswitch/setup_gre_and_routes.sh /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

 		sudo sed -i "s/MultiHostVar6/$MultiHostVar6/g" 	/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
 		sudo sed -i "s/MultiHostVar3/$Sw1Index/g" 	/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

                if   [ $TunType = 'geneve' ]
                then
                        sudo sed -i '/type=gre/d'               /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/add-protocol=gre/d'	/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
			sudo sed -i '/gre_sys/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
                        sudo sed -i '/type=vxlan/d'             /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/add-port=4789/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
			sudo sed -i '/vxlan_sys_4789/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	

                elif [ $TunType = 'gre' ]
                then
                        sudo sed -i '/type=vxlan/d'             /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/add-port=4789/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
			sudo sed -i '/vxlan_sys_4789/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
                        sudo sed -i '/type=geneve/d'            /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/add-port=6081/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
			sudo sed -i '/genev_sys_6081/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	

                elif [ $TunType = 'vxlan' ]
                then
                        sudo sed -i '/type=gre/d'               /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/add-protocol=gre/d'	/etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
			sudo sed -i '/gre_sys/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
                        sudo sed -i '/type=geneve/d'            /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh
			sudo sed -i '/add-port=6081/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
			sudo sed -i '/genev_sys_6081/d'	        /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh	
                fi

		sudo chmod 777 /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh

                sleep 5

                clear

                echo ''
                echo "=============================================="
                echo "Setup GRE & Routes on $MultiHostVar5...       "
                echo "=============================================="
                echo ''
	
		ssh-keygen -R $MultiHostVar5
		sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 date
		if [ $? -eq 0 ]
		then
			sshpass -p $MultiHostVar9 scp -p /etc/network/openvswitch/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh $MultiHostVar8@$MultiHostVar5:~/.
		fi

		sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" ls -l ~/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh"
		
		if [ $? -eq 0 ]
		then
			sshpass -p $MultiHostVar9 ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" ~/setup_gre_and_routes_"$HOSTNAME"_"$Sw1Index".sh"
		fi

                echo ''
                echo "=============================================="
                echo "Done: Setup GRE & Routes on $MultiHostVar5.   "
                echo "=============================================="
                echo ''
	
                sleep 5

                clear

		function GetShortHost {
			uname -n | cut -f1 -d'.'
		}
		ShortHost=$(GetShortHost)

		sudo ifconfig sw1 mtu $MultiHostVar7
		sudo ifconfig sx1 mtu $MultiHostVar7

		echo ''
		echo "=============================================="
		echo "Create ADD DNS $ShortHost.$Domain1...         "
		echo "=============================================="
		echo ''

		sleep 5

		sudo sh -c "echo 'echo \"server 10.207.39.2'								    	>  /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
		sudo sh -c "echo 'update add $ShortHost.orabuntu-lxc.com 3600 IN A 10.207.39.$Sw1Index'		    		>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
		sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
		sudo sh -c "echo 'update add $Sw1Index.39.207.10.in-addr.arpa 3600 IN PTR $ShortHost.orabuntu-lxc.com' 		>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
		sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
		sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"
		sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh"

		sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh
		sudo ls -l     						/etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh
		sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"		/etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh

		sleep 5

		echo ''
		echo "=============================================="
		echo "Create DEL DNS $ShortHost.$Domain1...         "
		echo "=============================================="
		echo ''

		sleep 5

		sudo sh -c "echo 'echo \"server 10.207.39.2'								    	>  /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
		sudo sh -c "echo 'update delete $ShortHost.orabuntu-lxc.com. A'					    		>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
		sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
		sudo sh -c "echo 'update delete $Sw1Index.39.207.10.in-addr.arpa. PTR'				 		>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
		sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
		sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"
		sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh"

		sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh
		sudo ls -l     						/etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh
		sudo sed -i "s/orabuntu-lxc\.com/$Domain1/g"		/etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh

	#	GLS 20210220 Moved to uekulele-services-5.sh
	#
	#	ssh-keygen -R 10.207.39.2
	#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
	#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
	#	sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
	#	sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain1_del_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
	#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain1_add_$ShortHost.sh"

		sleep 5
	
	        echo ''
	        echo "=============================================="
	        echo "Done: Create ADD/DEL DNS $ShortHost.$Domain1  "
	        echo "=============================================="
	        echo ''
	
	        sleep 5
	
	        clear

		echo ''
		echo "=============================================="
		echo "Create ADD DNS $ShortHost.$Domain2 ...        "
		echo "=============================================="
		echo ''

		sudo sh -c "echo 'echo \"server 10.207.29.2'								    	>  /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
		sudo sh -c "echo 'update add $ShortHost.consultingcommandos.us 3600 IN A 10.207.29.$Sx1Index'		    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
		sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
		sudo sh -c "echo 'update add $Sx1Index.29.207.10.in-addr.arpa 3600 IN PTR $ShortHost.consultingcommandos.us' 	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
		sudo sh -c "echo 'send'											    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
		sudo sh -c "echo 'quit'											    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"
		sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'							    	>> /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh"

		sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh
		sudo ls -l     						/etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh
		sudo sed -i "s/consultingcommandos\.us/$Domain2/g"	/etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh

		echo ''
		echo "=============================================="
		echo "Create DEL DNS $ShortHost.$Domain2...         "
		echo "=============================================="
		echo ''

		sudo sh -c "echo 'echo \"server 10.207.29.2'				    		>  /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
		sudo sh -c "echo 'update delete $ShortHost.consultingcommandos.us. A'  			>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
		sudo sh -c "echo 'send'							    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
		sudo sh -c "echo 'update delete $Sx1Index.29.207.10.in-addr.arpa. PTR' 			>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
		sudo sh -c "echo 'send'							    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
		sudo sh -c "echo 'quit'							    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"
		sudo sh -c "echo '\" | nsupdate -k /etc/bind/rndc.key'			    		>> /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh"

		sudo chmod 777 						/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh
		sudo ls -l     						/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh
		sudo sed -i "s/consultingcommandos\.us/$Domain2/g"	/etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh

	#	GLS 20210220 Moved to uekulele-services-5.sh
	#
	#	ssh-keygen -R 10.207.29.2
	#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
	#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
	#	sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh ubuntu@10.207.29.2:~/Downloads/.
	#	sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain2_del_$ShortHost.sh ubuntu@10.207.29.2:~/Downloads/.
	#	sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain2_add_$ShortHost.sh"
	
	        echo ''
	        echo "=============================================="
	        echo "Done: Create ADD/DEL DNS $ShortHost.$Domain2  "
	        echo "=============================================="
	        echo ''
	
	        sleep 5
	
	        clear
	fi
fi

if [ $SystemdResolvedInstalled -ge 1 ]
then
        echo ''
        echo "=============================================="
        echo "Restart systemd-resolved...                   "
        echo "=============================================="
        echo ''

	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" 		/etc/systemd/resolved.conf
	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" 	/etc/systemd/resolved.conf

        sudo service systemd-resolved restart
	
        echo ''
        echo "=============================================="
        echo "Done: Restart systemd-resolved.               "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

# GLS 20161118 This section for any tweaks to the unpacked files from archives.
if [ $Release -ge 6 ]
then
	sudo rm /etc/network/if-up.d/orabuntu-lxc-net
fi

echo ''
echo "=============================================="
echo "MultiHost Settings Completed.                 "
echo "=============================================="

sleep 5

clear

SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)
NetworkManagerRunning=$(CheckNetworkManagerRunning)

# echo 'SystemdResolvedInstalled =  '$SystemdResolvedInstalled
# echo 'Trigger Value            =  0'
# echo 'NetworkManagerRunning    =  '$NetworkManagerRunning
# echo 'Trigger Value            >= 1'
# echo 'GRE                      =  '$GRE
# echo 'Trigger Value            =  Y'
# echo 'MultiHostVar2            =  '$MultiHostVar2
# echo 'Trigger Value            =  N'

# sleep 10

if [ $SystemdResolvedInstalled -eq 0 ]
then
	if [ $GRE = 'Y' ] || [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Configure dnsmasq...                          "
		echo "=============================================="
		echo ''

		if [ $NetworkManagerRunning -ge 1 ]
		then
			sudo sed -i '/plugins=ifcfg-rh/a dns=none' /etc/NetworkManager/NetworkManager.conf
			sudo sed -i '$!N; /^\(.*\)\n\1$/!P; D' /etc/NetworkManager/NetworkManager.conf
		fi

		sudo yum -y install dnsmasq

		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" 		/etc/dnsmasq.conf
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" 	/etc/dnsmasq.conf
		sudo sed -i '/lxcbr0/d'								/etc/dnsmasq.conf
		sudo sed -i '/DHCP-RANGE-OLXC/d'						/etc/dnsmasq.conf
		sudo sed -i '/cache-size=150/s/cache-size=150/cache-size=0/g' 			/etc/dnsmasq.conf
			
		if [ $NetworkManagerRunning -ge 1 ]
		then
			sudo service NetworkManager restart
			sleep 5
		fi

		if [ $Release -ge 7 ]
		then
			sudo systemctl daemon-reload
		fi
			
		function GetOriginalNameServers {
		        cat /etc/resolv.conf  | grep nameserver | tr -d '\n' | sed 's/nameserver//g' | sed 's/^[ \t]*//;s/[ \t]*$//' | sed 's/  */ /g'
		}
		OriginalNameServers=$(GetOriginalNameServers)

		function GetOriginalSearchDomains {
		        cat /etc/resolv.conf  | grep search | sed 's/  */ /g' | sed 's/search //g'
		}
		OriginalSearchDomains=$(GetOriginalSearchDomains)

		sudo rm -f /etc/resolv.conf
		sudo sh -c "echo 'nameserver 127.0.0.1'	> 						/etc/resolv.conf"
		sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1 $OriginalSearchDomains' >> 	/etc/resolv.conf"
		sudo cp -p /etc/resolv.conf /etc/resolv.conf.olxc

		for j in $OriginalNameServers
		do
		        for i in $OriginalSearchDomains
		        do
		                function CountOriginalSearchDomainsDnsmasq {
		                        grep -c $j /etc/dnsmasq.conf
		                }
		                OriginalSearchDomainsDnsmasq=$(CountOriginalSearchDomainsDnsmasq)

		                if [ $OriginalSearchDomainsDnsmasq -eq 0 ]
		                then   
		                        sudo sh -c "echo 'server=/$i/$j' >> /etc/dnsmasq.conf"
		                fi
		        done
		done

		sudo service dnsmasq start

		if   [ $Release -ge 7 ]
		then
			sudo systemctl enable dnsmasq

		elif [ $Release -eq 6 ]
		then
			sudo chkconfig dnsmasq on
		fi

		echo ''
		sleep 2
		
		nslookup $NameServer $NameServer
		ping -c 3 $NameServer
	
		echo ''
		echo "=============================================="
		echo "Done: Configure NetworkManager with dnsmasq.  "
		echo "=============================================="
		echo ''
	fi
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Moving seed openvswitch veth files...         "
echo "=============================================="
echo ''

if [ ! -e /etc/orabuntu-lxc-release ] || [ ! -e /etc/network/if-up.d/lxcora00-pub-ifup-sw1 ] || [ ! -e /etc/network/if-down.d/lxcora00-pub-ifdown-sw1 ]
then
	cd /etc/network/if-up.d/openvswitch

	sudo cp lxcora00-asm1-ifup-sw8  oel$OracleRelease-asm1-ifup-sw8
	sudo cp lxcora00-asm2-ifup-sw9  oel$OracleRelease-asm2-ifup-sw9
	sudo cp lxcora00-priv1-ifup-sw4 oel$OracleRelease-priv1-ifup-sw4
	sudo cp lxcora00-priv2-ifup-sw5 oel$OracleRelease-priv2-ifup-sw5
	sudo cp lxcora00-priv3-ifup-sw6 oel$OracleRelease-priv3-ifup-sw6 
	sudo cp lxcora00-priv4-ifup-sw7 oel$OracleRelease-priv4-ifup-sw7
	sudo cp lxcora00-pub-ifup-sw1   oel$OracleRelease-pub-ifup-sw1

	cd /etc/network/if-down.d/openvswitch

	sudo cp lxcora00-asm1-ifdown-sw8  oel$OracleRelease-asm1-ifdown-sw8
	sudo cp lxcora00-asm2-ifdown-sw9  oel$OracleRelease-asm2-ifdown-sw9
	sudo cp lxcora00-priv1-ifdown-sw4 oel$OracleRelease-priv1-ifdown-sw4
	sudo cp lxcora00-priv2-ifdown-sw5 oel$OracleRelease-priv2-ifdown-sw5
	sudo cp lxcora00-priv3-ifdown-sw6 oel$OracleRelease-priv3-ifdown-sw6
	sudo cp lxcora00-priv4-ifdown-sw7 oel$OracleRelease-priv4-ifdown-sw7
	sudo cp lxcora00-pub-ifdown-sw1   oel$OracleRelease-pub-ifdown-sw1

	sudo ls -l /etc/network/if-up.d/openvswitch
	echo ''
	sudo ls -l /etc/network/if-down.d/openvswitch
fi

echo ''
echo "=============================================="
echo "Moving seed openvswitch veth files complete.  "
echo "=============================================="
echo ''

sleep 5

clear

# echo ''
# echo "=============================================="
# echo "Verify existence of Oracle and Grid users...  "
# echo "=============================================="
# echo ''

# sudo useradd -u 1098 grid 		>/dev/null 2>&1
# sudo useradd -u 500 oracle 		>/dev/null 2>&1
# sudo groupadd -g 1100 asmadmin		>/dev/null 2>&1
# sudo usermod -a -G asmadmin grid	>/dev/null 2>&1

# id grid
# id oracle

# echo ''
# echo "=============================================="
# echo "Existence of Oracle and Grid users verified.  "
# echo "=============================================="

# sleep 5

# clear

echo ''
echo "=============================================="
echo "Create RSA key if it does not already exist   "
echo "=============================================="
echo ''

if [ ! -e ~/.ssh/id_rsa.pub ]
then
# ssh-keygen -t rsa
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
fi

if [ -e ~/.ssh/authorized_keys ]
then
rm ~/.ssh/authorized_keys
fi

touch ~/.ssh/authorized_keys

if [ -e ~/.ssh/id_rsa.pub ]
then
function GetAuthorizedKey {
cat ~/.ssh/id_rsa.pub
}
AuthorizedKey=$(GetAuthorizedKey)

echo 'Authorized Key:'
echo ''
echo $AuthorizedKey 
echo ''
fi

function CheckAuthorizedKeys {
grep -c "$AuthorizedKey" ~/.ssh/authorized_keys
}
AuthorizedKeys=$(CheckAuthorizedKeys)

echo "Results of grep = $AuthorizedKeys"

if [ "$AuthorizedKeys" -eq 0 ]
then
cat  ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
fi

echo ''
echo 'cat of authorized_keys'
echo ''
cat ~/.ssh/authorized_keys

echo ''
echo "=============================================="
echo "Create RSA key completed                      "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Create the crt_links.sh script...             "
echo "=============================================="
echo ''

sudo mkdir -p /etc/orabuntu-lxc-scripts

sudo sh -c "echo ' ln -sf /var/lib/lxc .' 								    > /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/resolv.conf .' 								   >> /etc/orabuntu-lxc-scripts/crt_links.sh"

if [ -n $NameServer ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sw1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/$NameServer-pub-ifup-sx1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sw1 .'	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/$NameServer-pub-ifdown-sx1 .'	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/resolv.conf .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/network/interfaces .'		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/rndc.key .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/default/bind9 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/dhcp/dhcpd.leases .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/dhcp .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/dhcp/dhcpd.conf .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/default/isc-dhcp-server .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/default/bind9 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.local .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/etc/bind/named.conf.options .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi
if [ ! -n $NameServer ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sw1 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-up.d/openvswitch/nsa-pub-ifup-sx1 .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sw1 .'		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /etc/network/if-down.d/openvswitch/nsa-pub-ifdown-sx1 .'		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/resolv.conf .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/rndc.key .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/default/bind9 .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/var/lib/dhcp/dhcpd.leases .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/dhcp .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/dhcp/dhcpd.conf .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/default/isc-dhcp-server .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/default/bind9 .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/named.conf .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/named.conf.local .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/nsa/rootfs/etc/bind/named.conf.options .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ -n $Domain1 ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain1 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ -n $Domain2 ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.$Domain2 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.$Domain2 .' 		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ ! -n $Domain1 ] && [ $MultiHostVar2 = 'N' ]
then
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.orabuntu-lxc.com .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
	sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.orabuntu-lxc.com .' 	   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

if [ -n $NameServer ] && [ ! -n $Domain2 ] && [ $MultiHostVar2 = 'N' ]
then
        sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/fwd.consultingcommandos.us .' >> /etc/orabuntu-lxc-scripts/crt_links.sh"
        sudo sh -c "echo ' ln -sf /var/lib/lxc/$NameServer/rootfs/var/lib/bind/rev.consultingcommandos.us .' >> /etc/orabuntu-lxc-scripts/crt_links.sh"
fi

sudo sh -c "echo ' ln -sf /etc/sysctl.d/60-olxc.conf .' 			         		   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/security/limits.d/70-oracle.conf .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/interfaces .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/NetworkManager/dnsmasq.d/local .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/orabuntu-lxc-scripts/stop_containers.sh .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/orabuntu-lxc-scripts/start_containers.sh .' 				   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw1.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw2.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw3.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw4.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw5.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw6.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw7.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw8.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sw9.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/crt_ovs_sx1.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/del-bridges.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/veth_cleanups.sh .' 					   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/openvswitch/create-ovs-sw-files-v2.sh .' 			   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/init/openvswitch-switch.conf .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/default/openvswitch-switch .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/multipath.conf .' 							   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/multipath.conf.example .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"
sudo sh -c "echo ' ln -sf /etc/network/if-down.d/scst-net .' 						   >> /etc/orabuntu-lxc-scripts/crt_links.sh"

ls -l /etc/orabuntu-lxc-scripts/crt_links.sh

echo ''
echo "=============================================="
echo "Created the crt_links.sh script.              "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Set SELINUX to permissive...                  "
echo "=============================================="
echo ''

sudo setenforce permissive
sudo sed -i '/SELINUX=enforcing/s/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

sleep 5

clear

echo ''
echo "=============================================="
echo "Allow NTP to run in LXC Containers...         "
echo "=============================================="
echo ''

if [ ! -f /usr/share/lxc/config/common.conf.d/01-sys-time.conf ]
then
        sudo touch /usr/share/lxc/config/common.conf.d/01-sys-time.conf
        sudo sh -c "echo 'lxc.cap.drop ='                                              > /usr/share/lxc/config/common.conf.d/01-sys-time.conf"
        sudo sh -c "echo 'lxc.cap.drop = mac_admin mac_override sys_module sys_rawio' >> /usr/share/lxc/config/common.conf.d/01-sys-time.conf"
        sudo ls -l /usr/share/lxc/config/common.conf.d/01-sys-time.conf
        echo ''
        cat /usr/share/lxc/config/common.conf.d/01-sys-time.conf
fi

echo ''
echo "=============================================="
echo "Done: Allow NTP to run in LXC Containers.     "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: uekulele-services-2.sh    "
echo "=============================================="

