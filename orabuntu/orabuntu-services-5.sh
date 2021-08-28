#!/bin/bash

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
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
MultiHost=$6
DistDir=$7

if [ -e /sys/hypervisor/uuid ]
then
	function CheckAWS {
        	cat /sys/hypervisor/uuid | cut -c1-3 | grep -c ec2
	}
	AWS=$(CheckAWS)
else
	AWS=0
fi

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

function GetUbuntuVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
}
UbuntuVersion=$(GetUbuntuVersion)

function CheckSearchDomain1 {
        grep -c $Domain1 /etc/resolv.conf
}
SearchDomain1=$(CheckSearchDomain1)

if [ $SearchDomain1 -eq 0 ] && [ $AWS -eq 0 ]
then
        sudo sed -i '/search/d' /etc/resolv.conf
        sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1' >> /etc/resolv.conf"
fi

OR=$OracleRelease

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

function GetMultiHostVar11 {
        echo $MultiHost | cut -f11 -d':'
}
MultiHostVar11=$(GetMultiHostVar11)

function GetMultiHostVar12 {
        echo $MultiHost | cut -f12 -d':'
}
MultiHostVar12=$(GetMultiHostVar12)
LXDValue=$MultiHostVar12
LXD=$MultiHostVar12

function GetMultiHostVar13 {
        echo $MultiHost | cut -f13 -d':'
}
MultiHostVar13=$(GetMultiHostVar13)

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

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetLXCVersion {
       lxc-create --version
}
LXCVersion=$(GetLXCVersion)

if   [ $LXD = 'N' ]
then
	function GetSeedContainerName {
        	sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '
	}
	SeedContainerName=$(GetSeedContainerName)
	Config=/var/lib/lxc/$SeedContainerName/config
elif [ $LXD = 'Y' ]
then
	function GetSeedContainerName {
        	lxc list | grep oel$OracleRelease | sort -d | cut -f2 -d' ' | sed 's/^[ \t]*//;s/[ \t]*$//' | tail -1
	}
	SeedContainerName=$(GetSeedContainerName)
fi

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

function CheckLxcNetRunning {
        sudo systemctl | grep lxc-net | grep 'loaded active exited' | wc -l
}
LxcNetRunning=$(CheckLxcNetRunning)

function GetUbuntuMajorVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
}
UbuntuMajorVersion=$(GetUbuntuMajorVersion)

function CheckNameServerExists {
	sudo lxc-info -n $NameServer 2>&1 | grep -i name | wc -l
}
NameServerExists=$(CheckNameServerExists)

echo ''
echo "=============================================="
echo "Script: orabuntu-services-5.sh                "
echo "=============================================="
echo ''

sleep 5

clear

if [ $MultiHostVar1 = 'new' ] && [ $Docker = 'Y' ]
then	
	echo ''
	echo "=============================================="
	echo "Install Docker...                             "
	echo "=============================================="
	echo ''

	sleep 5

	if [ $UbuntuMajorVersion -ge 16 ]
	then
		sudo chmod 775 /opt/olxc/"$DistDir"/orabuntu/archives/docker_install_orabuntu.sh
		/opt/olxc/"$DistDir"/orabuntu/archives/docker_install_orabuntu.sh
	fi

	echo ''
	echo "=============================================="
	echo "Done: Install Docker.                         "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

sleep 5

clear

if [ $LXD = 'N' ]
then
	echo ''
	echo "=============================================="
	echo "Starting LXC containers for Oracle...     "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	function GetSeedPostfix {
        	sudo lxc-ls -f | grep ora"$OracleRelease"c | cut -f1 -d' ' | cut -f2 -d'c' | sed 's/^/c/'
	}
	SeedPostfix=$(GetSeedPostfix)

	function CheckClonedContainersExist {
		sudo ls /var/lib/lxc | grep "ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ClonedContainersExist=$(CheckClonedContainersExist)

	# sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
	# sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
	# sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service dnsmasq restart > /dev/null 2>&1"

	sudo service systemd-resolved restart > /dev/null 2>&1

	for j in $ClonedContainersExist
	do
		# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
		# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

#		sudo /etc/network/openvswitch/veth_cleanups.sh $j > /dev/null 2>&1

#		Start commented-out section 
: '		if [ $UbuntuMajorVersion -ge 20 ]
		then
			if [ $LXD = 'Y' ]
			then
				clear

				echo ''
				echo "=============================================="
				echo "Convert $j LXC-to-LXD ...                     "
				echo "=============================================="
				echo ''

				echo "Stopping LXC container $j ..." > /dev/null 2>&1

				sudo lxc-stop -n $j > /dev/null 2>&1

				sleep 5

        			function GetShortHostName {
                			hostname -s
        			}
        			ShortHostName=$(GetShortHostName)

                        	function AlreadyConverted {
                                	lxc list $j | grep -c $j
                        	}
                        	Converted=$(AlreadyConverted)

                        	if [ $Converted -eq 0 ]
                        	then
					function GetOldMacAddress {
				        	sudo cat /var/lib/lxc/$j/config | grep hwaddr | cut -f3 -d' '
					}
					OldMacAddress=$(GetOldMacAddress)

					function GetNewMacAddress {
				        	echo -n 00:16:3e; dd bs=1 count=3 if=/dev/random 2>/dev/null | hexdump -v -e '/1 ":%02x"'
					}
					NewMacAddress=$(GetNewMacAddress)

				#	sudo sed -i 's/sw1a/lxdbr0/g' 				/var/lib/lxc/$j/config
				#	sudo sed -i "s/\(hwaddr = \).*/\1$NewMacAddress/"       /var/lib/lxc/$j/config

					sudo lxd.lxc-to-lxd --lxcpath /var/lib/lxc --containers $j --storage $ShortHostName-$StoragePoolName --debug
				#	sudo lxd.lxc-to-lxd --lxcpath /var/lib/lxc --containers $j --debug

				#	sudo sed -i 's/lxdbr0/sw1a/g' /var/lib/lxc/$j/config
				#	sudo sed -i "s/\(hwaddr = \).*/\1$OldMacAddress/"       /var/lib/lxc/$j/config
                        	fi

				echo ''
				echo "=============================================="
				echo "Done: Convert $j LXC-to-LXD                   "
				echo "=============================================="

				sleep 5

                        	function GetLXDName {
                                	echo $j | sed 's/c/d/'
                        	}
                        	LXDName=$(GetLXDName)

                        	lxc move $j $LXDName

				sleep 5
                        
				lxc file delete $LXDName/etc/machine-id 		> /dev/null 2>&1
                        	lxc file delete $LXDName/var/lib/dbus/machine-id 	> /dev/null 2>&1

                        	lxc start $LXDName
			
				sleep 15

                        	echo ''
                        	echo "=============================================="
                        	echo "Generate new LXD machine-id for container ... "
                        	echo "=============================================="
                        	echo ''

                        	echo 'These values should differ ...'
                        	echo ''
                        	echo "=============================================="

                        	lxc exec $LXDName -- systemd-machine-id-setup

                        	sleep 5

                        	lxc exec $LXDName -- cat /etc/machine-id
                        	sudo cat /var/lib/lxc/$j/rootfs/etc/machine-id
                        
				echo "=============================================="

                        	echo ''
                        	echo "=============================================="
                        	echo "Done: Generate LXD machine-id for container.  "
                        	echo "=============================================="

                        	lxc stop  $LXDName
				sleep 2
                        	lxc start $LXDName

                        	sleep 30

				if   [ $MajorRelease -ge 7 ]
                        	then
                                	lxc exec  $LXDName -- hostnamectl set-hostname $LXDName
					lxc exec  $LXDName -- uname -a
					lxc stop  $LXDName
					sleep 2
					lxc start $LXDName

					sleep 15
                                
					lxc exec $LXDName -- sed -i "s/$j/$LXDName/g" /etc/hosts
			 		lxc exec $LXDName -- sed -i "s/$j/$LXDName/g" /etc/sysconfig/network
                                	lxc exec $LXDName -- sed -i "s/$j/$LXDName/g" /etc/sysconfig/network-scripts/ifcfg-eth0

                        	elif [ $MajorRelease -eq 6 ]
                        	then
                                	lxc exec $LXDName
                                	lxc exec $LXDName -- sed -i "s/$j/$LXDName/g" /etc/hosts
			 		lxc exec $LXDName -- sed -i "s/$j/$LXDName/g" /etc/sysconfig/network
                                	lxc exec $LXDName -- sed -i "s/$j/$LXDName/g" /etc/sysconfig/network-scripts/ifcfg-eth0
                        	fi

	  		sudo lxc-destroy -n $j
	  		sudo systemctl disable $j

                	fi
        	fi
'		# End commented-out section

#		echo "Starting container $j ..."

		sudo lxc-start -n $j > /dev/null 2>&1

		function CheckPublicIPIterative {
			sudo lxc-info -n $j -iH | cut -f1-3 -d'.' | sed 's/\.//g' | head -1
		}
		PublicIPIterative=$(CheckPublicIPIterative)

#		if   [ $LXD = 'N' ]
#       	then
#               	echo $j | grep oel > /dev/null 2>&1
#
#       	elif [ $LXD = 'Y' ]
#       	then
#               	echo $LXDName | grep oel > /dev/null 2>&1
#       	fi
#       	if [ $? -eq 0 ]
#       	then
#               	sudo bash -c "cat $Config|grep ipv4|cut -f2 -d'='|sed 's/^[ \t]*//;s/[ \t]*$//'|cut -f4 -d'.'|sed 's/^/\./'|xargs -I '{}' sed -i "/ipv4/s/\{}/\.1$OR/g" $Config"
#       	fi

		echo ''
		echo "=============================================="
		echo "LXC Container $j Started                      "
		echo "=============================================="
		echo ''

		sudo lxc-ls -f | egrep "NAME|$j"

		echo '' 
		echo "=============================================="
		echo ''

		sleep 5

		clear

		i=1
		while [ "$PublicIPIterative" != 1020739 ] && [ "$i" -le 10 ] && [ $LXD = 'N' ]
		do
        	#	echo ''
        	#	echo "=============================================="
        	#	echo "Waiting for $j Public IP to come up..."
        	#	echo "=============================================="
        	#	echo ''

        	#	sleep 5

		#	clear

			PublicIPIterative=$(CheckPublicIPIterative)
			if [ $i -eq 5 ]
			then
				sudo lxc-stop -n $j
				sleep 2
				echo ''
				echo 'Attempting OpenvSwitch veth pair cleanup procedures...'
				echo 'Messages Cannot file device are normal in this procedure.'
				echo 'Orabuntu-LXC will re-attempt container startup after cleanup procedure.'
				echo ''
				sudo /etc/network/openvswitch/veth_cleanups.sh $j
				echo ''
				sudo service systemd-resolved restart > /dev/null 2>&1
				sleep 2
				sudo lxc-start -n $j
				sleep 5
				if [ $MajorRelease -eq 6 ] || [ $MajorRelease -eq 5 ]
				then
					sudo lxc-attach -n $j -- ntpd -x
				fi
			fi
			sleep 1
			i=$((i+1))
		done
	done
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Done: Starting LXC containers for Oracle.     "
echo "=============================================="
echo ''

sleep 5

clear

if   [ $SystemdResolvedInstalled -ge 1 ]
then
	echo ''
	echo "=============================================="
	echo "Restart systemd-resolved...                   "
	echo "=============================================="
	echo ''
	
	sudo service systemd-resolved restart
	sleep 2
	sudo service systemd-resolved status | cat
	
	echo ''
	echo "=============================================="
	echo "Done: Restart systemd-resolved.               "
	echo "=============================================="
	echo ''
	
	sleep 5
	
	clear
fi

if [ $LxcNetRunning -ge 1 ]
then
	echo ''
	echo "=============================================="
	echo "Restart service lxc-net...                    "
	echo "=============================================="
	echo ''

	sudo service lxc-net restart
	sleep 2
	sudo service lxc-net status | cat

	echo ''
	echo "=============================================="
	echo "Done: Restart service lxc-net.                "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

if [ $LXD = 'N' ]
then
	for j in $ClonedContainersExist
	do
       		echo ''
		echo "=============================================="
		echo "SSH to local container $j...                  "
       		echo "=============================================="
       		echo ''

		sudo lxc-start  -n $j > /dev/null 2>&1
		sleep 10
		ssh-keygen -R $j
       		sshpass -p root ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no root@$j "uname -a; cat /etc/oracle-release"

       		echo ''
		echo "=============================================="
		echo "Done: SSH to local container $j.              "
       		echo "=============================================="
       		echo ''

		sleep 5

		clear
	done
fi

if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ]
then
	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release file...      "
	echo "=============================================="
	echo ''
	
	sudo touch /etc/orabuntu-lxc-release
	sudo sh -c "echo 'Orabuntu-LXC v7.0.0-beta AMIDE' > /etc/orabuntu-lxc-release"
	sudo ls -l /etc/orabuntu-lxc-release
	echo ''
	sudo cat /etc/orabuntu-lxc-release
	
	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release complete.    "
	echo "=============================================="
	
	sleep 5
	
	clear
	
	function CheckMtuSetLocalSw1 {
	 	sudo ifconfig sw1 | grep mtu | grep $MultiHostVar7 | wc -l
	}
	MtuSetLocalSw1=$(CheckMtuSetLocalSw1)
	
	function CheckMtuSetLocalSx1 {
	 	sudo ifconfig sx1 | grep mtu | grep $MultiHostVar7 | wc -l
	}
	MtuSetLocalSx1=$(CheckMtuSetLocalSx1)
	
	if [ $GRE = 'Y' ]
	then
	       	echo ''
	        echo "=============================================="
		echo "Set MTU to $MultiHostVar7 on GRE networks...  "
	       	echo "=============================================="
	       	echo ''
	
		if [ "$MtuSetLocalSw1" -eq 0 ] && [ "$MtuSetLocalSx1" -eq 0 ]
		then
			sudo sh -c "sed -i '/1500/s/1500/$MultiHostVar7/' /var/lib/lxc/*/config"
			/etc/orabuntu-lxc-scripts/stop_ora_containers.sh
			/etc/orabuntu-lxc-scripts/start_ora_containers.sh
		fi

		sleep 5

		clear
	
	       	echo ''
	        echo "=============================================="
		echo "Done: Set MTU $MultiHostVar7 on GRE networks. "
	       	echo "=============================================="
	       	echo ''
	
		sleep 5
	
		clear
	
	       	echo ''
	        echo "=============================================="
		echo "Test SSH over GRE to $NameServer DNS...       "
	       	echo "=============================================="
	       	echo ''
	
		sshpass -p ubuntu ssh -q -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$NameServer "sudo -S <<< "ubuntu" uname -a; cat /etc/lsb-release"
	
	       	echo ''
	        echo "=============================================="
		echo "Done: Test SSH over GRE to $NameServer DNS.   "
	       	echo "=============================================="
	       	echo ''
	
		sleep 5
	
		clear
	
		function GetMtuLocal {
			sudo ifconfig | grep mtu | grep $MultiHostVar7 | cut -f1,5 -d' ' | sed 's/  *//g' | sed 's/$/ /' | tr -d '\n'
		}
		MtuLocal=$(GetMtuLocal)
	
	       	echo ''
	        echo "=============================================="
		echo "Show MTU on local network devices.            "
	       	echo "=============================================="
	       	echo ''
	
		for i in $MtuLocal
		do
			function GetNetworkDeviceName {
				echo $i | cut -f1 -d':'
			}
			NetworkDeviceName=$(GetNetworkDeviceName)
	
			function GetNetworkDeviceMtu {
				echo $i | cut -f2 -d':'
			}
			NetworkDeviceMtu=$(GetNetworkDeviceMtu)
	
			echo 'Network Device Name = '$NetworkDeviceName
			echo 'Network Device MTU  = '$NetworkDeviceMtu
			echo ''
		done
	
	        echo "=============================================="
		echo "Done: Show MTU on local network devices.      "
	       	echo "=============================================="
	       	echo ''
	
		sleep 5
	
		clear
	
		echo ''
		echo "=============================================="
		echo "Done: Set MTU $MultiHostVar7 on GRE networks. "
		echo "=============================================="
		echo ''
	
		sleep 5
	
		clear
	fi
	
	function GetShortHost {
		uname -n | cut -f1 -d'.'
	}
	ShortHost=$(GetShortHost)
	
	sudo nslookup -timeout=10 $HOSTNAME.$Domain1 > /dev/null 2>&1
	if [ $? -eq 1 ]
	then
	      	echo ''
	        echo "=============================================="
		echo "Create ADD DNS $ShortHost.$Domain1            "
	       	echo "=============================================="
		echo ''
	
		ssh-keygen -R 10.207.39.2
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
		sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain1_add_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain1_add_$ShortHost.sh"
	       	
		echo ''
	        echo "=============================================="
		echo "Done: Create ADD DNS $ShortHost.$Domain1      "
	       	echo "=============================================="
	       	echo ''
	
		sleep 5
	
		clear
	fi
	
	sudo nslookup -timeout=10 $HOSTNAME.$Domain2 > /dev/null 2>&1
	if [ $? -eq 1 ]
	then
	      	echo ''
	        echo "=============================================="
		echo "Create ADD DNS $ShortHost.$Domain2            "
	       	echo "=============================================="
		echo ''
	
		ssh-keygen -R 10.207.29.2
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
		sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh ubuntu@10.207.39.2:~/Downloads/.
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain2_add_$ShortHost.sh"
	       	
		echo ''
	        echo "=============================================="
		echo "Done: Create ADD DNS $ShortHost.$Domain2      "
	       	echo "=============================================="
	       	echo ''
	
		sleep 5
	
		clear
	fi
	
	if [ $SystemdResolvedInstalled -ge 1 ]
	then
		echo ''
		echo "=============================================="
		echo "Restart systemd-resolved...                   "
		echo "=============================================="
		echo ''
	
		sudo service systemd-resolved restart
		sleep 2
		sudo service systemd-resolved status | cat
	
		echo ''
		echo "=============================================="
		echo "Done: Restart systemd-resolved.               "
		echo "=============================================="
		echo ''
	
		sleep 5
	
		clear
	fi

        if [ $LxcNetRunning -ge 1 ]
        then
                echo ''
                echo "=============================================="
                echo "Restart service lxc-net...                    "
                echo "=============================================="
                echo ''

                sudo service lxc-net restart
                sleep 2
                sudo service lxc-net status | cat

                echo ''
                echo "=============================================="
                echo "Done: Restart service lxc-net.                "
                echo "=============================================="
                echo ''

                sleep 5

                clear
	fi
	
	echo ''
	echo "=============================================="
	echo "nslookup $ShortHost.$Domain1                  "
	echo "=============================================="
	echo ''
	
	sudo nslookup -timeout=10 $ShortHost.$Domain1
	
	echo "=============================================="
	echo "Done: nslookup $ShortHost.$Domain1            "
	echo "=============================================="
	
	sleep 5
	
	clear
	
	echo ''
	echo "=============================================="
	echo "nslookup $ShortHost.$Domain2                  "
	echo "=============================================="
	echo ''
	
	sudo nslookup -timeout=10 $ShortHost.$Domain2
	
	echo "=============================================="
	echo "Done: nslookup $ShortHost.$Domain2            "
	echo "=============================================="

        sleep 5

        clear

        sudo tar --extract --file=/opt/olxc/"$DistDir"/orabuntu/archives/dns-dhcp-host.tar -C / etc/network/openvswitch/ns_restore.sh
        sudo sed -i "s/NAMESERVER/$NameServer/g" /etc/network/openvswitch/ns_restore.sh
        sudo sed -i "s/DOMAIN1/$Domain1/g"       /etc/network/openvswitch/ns_restore.sh
        sudo sed -i "s/DOMAIN2/$Domain2/g"       /etc/network/openvswitch/ns_restore.sh


        if [ $NameServerExists -eq 1 ] && [ $GRE = 'N' ] && [ $MultiHostVar2 = 'N' ]
        then
                echo ''
                echo "=============================================="
                echo "Replicate nameserver $NameServer...           "
                echo "=============================================="
                echo ''

                function CheckFileSystemTypeXfs {
                        stat --file-system --format=%T /var/lib/lxc | grep -c xfs
                }
                FileSystemTypeXfs=$(CheckFileSystemTypeXfs)

                function CheckFileSystemTypeExt {
                        stat --file-system --format=%T /var/lib/lxc | grep -c ext
                }
                FileSystemTypeExt=$(CheckFileSystemTypeExt)

                if [ $FileSystemTypeXfs -eq 1 ]
                then
                        function GetFtype {
                                xfs_info / | grep -c ftype=1
                        }
                        Ftype=$(GetFtype)

                        if   [ $Ftype -eq 1 ]
                        then
                                sudo lxc-stop -n $NameServer > /dev/null 2>&1
                                sudo echo 'hub nameserver post-install snapshot' > /home/$Owner/snap-comment
				sudo chown -R $Owner:$Group /home/$Owner/snap-comment
                                sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                                sudo rm -f /home/$Owner/snap-comment
                                sudo lxc-snapshot -n $NameServer -L -C
                                sleep 5
                        fi
                fi

                if [ $FileSystemTypeExt -eq 1 ]
                then
                        sudo lxc-stop -n $NameServer > /dev/null 2>&1
                        sudo echo 'hub nameserver post-install snapshot' > /home/$Owner/snap-comment
			sudo chown -R $Owner:$Group /home/$Owner/snap-comment
                        sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                        sudo rm -f /home/$Owner/snap-comment
                        sudo lxc-snapshot -n $NameServer -L -C
                        sleep 5
                fi

                if [ ! -e ~/Manage-Orabuntu ]
                then
                        sudo mkdir -p ~/Manage-Orabuntu
                fi

                echo "/var/lib/lxc/$NameServer/." 	>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst
                echo "/var/lib/lxc/$NameServer-base/." 	>> /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst

		# GLS 20180411 create a copy of nameserver.lst in ~/Manage-Orabuntu so that nameserver replication job can create nameserver copy dynamically to capture any post-install changes on HUB host.
		if [ ! -d ~/Manage-Orabuntu ]
		then
			sudo mkdir -p ~/Manage-Orabuntu
		fi

		sudo cp -p /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst ~/Manage-Orabuntu/.
		sudo chown $Owner:$Group ~/Manage-Orabuntu/nameserver.lst
		# GLS 20180411

                sudo tar -P -czf ~/Manage-Orabuntu/$NameServer.tar.gz -T /opt/olxc/"$DistDir"/orabuntu/archives/nameserver.lst --checkpoint=10000 --totals

		sudo lxc-start -n $NameServer > /dev/null 2>&1
		sleep 15

		function CutOffBase {
			echo $NameServer | cut -f1 -d'-'
		}
		OffBase=$(CutOffBase)

		sudo rm -rf    /home/amide/Manage-Orabuntu/
		sudo mkdir -p  /home/amide/Manage-Orabuntu/backup-lxc-container/$OffBase/updates
		sudo mkdir -p  /home/amide/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
		sudo chown -R   amide:amide /home/amide
		sudo chmod 744 /home/amide
                ssh-keygen -R  10.207.39.2
                ssh-keygen -R  $NameServer

		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" echo $HOSTNAME > ~/new_gre_host.txt"
                
                echo ''
                echo "=============================================="
                echo "Done: Configure replica nameserver $NameServer"
                echo "=============================================="
		echo ''
                echo "=============================================="
                echo "Done: Replicate nameserver $NameServer.       "
                echo "=============================================="
                echo ''

                sleep 5

                clear
        fi

        if [ $GRE = 'Y' ]
        then
		echo ''
                echo "=============================================="
                echo "Configure replica nameserver $NameServer...   "
                echo "=============================================="
                echo ''

		sleep 5

		function CutOffBase {
			echo $NameServer | cut -f1 -d'-'
		}
		OffBase=$(CutOffBase)

		sudo rm -rf    /home/amide/Manage-Orabuntu/
		sudo mkdir -p  /home/amide/Manage-Orabuntu/backup-lxc-container/$OffBase/updates
		sudo mkdir -p  /home/amide/Manage-Orabuntu/backup-lxc-container/$NameServer/updates
		sudo chown -R   amide:amide /home/amide
		sudo chmod 744 /home/amide
                ssh-keygen -R 10.207.39.2
                ssh-keygen -R $NameServer

		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" echo $HOSTNAME > ~/new_gre_host.txt"

		echo ''
                echo "=============================================="
                echo "Done: Configure replica nameserver $NameServer"
                echo "=============================================="
                echo ''

                sleep 5

		clear
        
                if   [ $SystemdResolvedInstalled -ge 1 ]
                then
                        echo ''
                        echo "=============================================="
                        echo "Restart systemd-resolved...                   "
                        echo "=============================================="
                        echo '' 
        
                        sudo service systemd-resolved restart 
                        sleep 2 
                        sudo service systemd-resolved status | cat
                        
                        echo '' 
                        echo "=============================================="
                        echo "Done: Restart systemd-resolved.               "
                        echo "=============================================="
                        echo '' 
        
                        sleep 5 

			clear
       		fi
 
                if [ $LxcNetRunning -ge 1 ] 
                then    
                        echo '' 
                        echo "=============================================="
                        echo "Restart service lxc-net...                    "
                        echo "=============================================="
                        echo '' 

                        sudo service lxc-net restart 
                        sleep 2
                        sudo service lxc-net status | cat

                        echo ''
                        echo "=============================================="
                        echo "Done: Restart service lxc-net.                "
                        echo "=============================================="
			echo ''

			sleep 5

			clear
		fi
                
                echo ''
                echo "=============================================="
                echo "Done: Configure replica nameserver $NameServer"
                echo "=============================================="

                sleep 5

                clear
        fi

	echo ''
	echo "=============================================="
	echo "List Containers...                            "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "LXC Containers...                             "
	echo "=============================================="
	echo ''

	sudo lxc-ls -f

	if [ $LXD = 'Y' ]
	then
		function GetLXDContainerNames {
			lxc list --columns n --format csv | grep -v oel | sed 's/$/ /g' | tr -d '\n' |  sed 's/[ \t]*$//'
		}
		LXDContainerNames=$(GetLXDContainerNames)

		echo ''
		echo "=============================================="
		echo "LXD Containers...                             "
		echo "=============================================="
		echo ''

		lxc list

	#	sudo lxc-attach -n $NameServer -- service bind9 stop
	#	sudo lxc-attach -n $NameServer -- service bind9 start
		
		sleep 5

		clear

		for i in $LXDContainerNames
		do
	#		lxc exec  $i -- hostnamectl set-hostname $i
	#		lxc stop  $i
	#		lxc start $i 
	#		sleep 15

			echo ''
			echo "=============================================="
			echo "Test SSH to LXD Container $i ...              "
			echo "=============================================="
			echo ''

			ssh-keygen -R $i
			sleep 5
       			sshpass -p root ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no root@$i "uname -a; cat /etc/oracle-release"

			echo ''
			echo "=============================================="
			echo "Done: Test SSH to LXD Container $i.           "
			echo "=============================================="
			echo ''

			sleep 5

			clear

			echo ''
			echo "=============================================="
			echo "Test nslookup LXD Container $i ...            "
			echo "=============================================="
			echo ''

			nslookup $i

			echo "=============================================="
			echo "Done: Test nslookup LXD Container $i.         "
			echo "=============================================="
			echo ''

			sleep 5

			clear
		done

		sleep 5

		clear

		echo ''
		echo "=============================================="
		echo "List LXD Containers ...                       "
		echo "=============================================="
		echo ''

		lxc list

		echo ''
		echo "=============================================="
		echo "Done: List LXD Containers ...                 "
		echo "=============================================="
		echo ''
	fi

	if [ $Docker = 'Y' ]
	then
		echo ''
		echo "=============================================="
		echo "Docker Containers...                          "
		echo "=============================================="
		echo ''

		sudo docker ps -a

		echo ''
	#	echo "=============================================="
	#	echo "To ssh to Docker raesene/alpine-nettools:     "
	#	echo "                                              "
	#	echo "     ssh username@localhost -p 2200           "
	#	echo "                                              "
	#	echo "The docker container can connect to anything  "
	#	echo "on the OpenvSwitch network via any local LXC  "
	#	echo "container but normally ssh to Docker not used."
	#	echo "=============================================="
	#	echo ''
	fi

	echo "=============================================="
	echo "Done: List Containers.                        "
	echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Management links directory creation...        "
	echo "=============================================="
	
	if [ ! -d ~/Manage-Orabuntu ]
	then
		sudo mkdir -p ~/Manage-Orabuntu
	fi
	
	cd ~/Manage-Orabuntu
	sudo chmod 755 /etc/orabuntu-lxc-scripts/crt_links.sh 
	sudo /etc/orabuntu-lxc-scripts/crt_links.sh
	
	echo ''
	sudo ls -l ~/Manage-Orabuntu | tail -5
	echo '...'
	
	echo ''
	echo "=============================================="
	echo "Management links directory created.           "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Note that deployment management links are in: "
	echo "                                              "
	echo "     ~/Manage-Orabuntu                        "
	echo "                                              "
	echo "Learn and manage Orabuntu-LXC configurations  "
	echo "from that directory of pointers.              "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Build SCST Linux SAN (optional e.g. for a DB) "
	echo "                                              "
	echo "Instructions:                                 "
	echo "                                              "
	echo "     cd /opt/olxc/home/scst-files             "
	echo "     cat README                               "
	echo "     ./create-scst.sh                         "
	echo "=============================================="
	echo ''
	
	sleep 5
fi

# Set permissions on scst-files and cleanup staging area

function GetGroup {
	id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
	id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

sudo rm -f /opt/olxc/*.lst /opt/olxc/*.tar
if [ $Owner != 'ubuntu' ] && [ -d /opt/olxc/home/ubuntu ]
then
	sudo rm -r /opt/olxc/home/ubuntu
fi

cd "$DistDir"/orabuntu/archives
rm -f orabuntu-services.lst orabuntu-files.lst product.lst orabuntu-services.tar orabuntu-files.tar product.tar
cd "$DistDir"/installs/logs
LOGEXT=`date +"%Y-%m-%d.%R:%S"`
sudo cp -p $USER.log $USER.orabuntu-lxc.install.$LOGEXT
sudo rm -f /etc/sudoers.d/orabuntu-lxc

if [ $UbuntuMajorVersion -eq 16 ]
then
        echo ''
        echo "=============================================="
        echo "Remove /etc/apt/apt/conf.d/99olxc-ipv4        "
        echo "=============================================="
        echo ''
	echo 'This file was installed by Orabuntu-LXC to force apt-get to use ipv4 during the install.'
	echo 'This file is now being removed because Orabuntu-LXC install is complete.'
        echo ''
        
	sudo rm -f /etc/apt/apt.conf.d/99olxc-ipv4

        echo ''
        echo "=============================================="
        echo "Done: Remove /etc/apt/apt/conf.d/99olxc-ipv4  "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

cd $DistDir/anylinux
