#!/bin/bash

#    Copyright 2015-2019 Gilbert Standen
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

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#
#!/bin/bash

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
MultiHost=$6
DistDir=$7

OR=$OracleRelease

function GetGroup {
	id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
	id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

Config=/var/lib/lxc/$SeedContainerName/config

function GetMultiHostVar1 {
	echo $MultiHost | cut -f1 -d':'
}
MultiHostVar1=$(GetMultiHostVar1)

function GetMultiHostVar2 {
	echo $MultiHost | cut -f2 -d':'
}
MultiHostVar2=$(GetMultiHostVar2)

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

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetLXCVersion {
       lxc-create --version
}
LXCVersion=$(GetLXCVersion)

function GetSeedContainerName {
        sudo lxc-ls -f | grep oel$OracleRelease | cut -f1 -d' '
}
SeedContainerName=$(GetSeedContainerName)

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

function CheckNameServerExists {
        sudo lxc-info -n $NameServer 2>&1 | grep -i name | wc -l
}
NameServerExists=$(CheckNameServerExists)

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
        if   [ $OracleDistroRelease -eq 7 ]
        then
                CutIndex=7
        elif [ $OracleDistroRelease -eq 8 ]
        then
                CutIndex=6
        fi
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
	RHV=$RedHatVersion
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
                	sudo cat /etc/redhat-release | cut -f7 -d' ' | cut -f1 -d'.'
        	}
        	RedHatVersion=$(GetRedHatVersion)
        elif [ $LinuxFlavor = 'CentOS' ]
        then
                function GetRedHatVersion {
                        cat /etc/redhat-release | sed 's/ Linux//' | cut -f1 -d'.' | rev | cut -f1 -d' '
                }
        	RedHatVersion=$(GetRedHatVersion)
        fi
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
        if [ $RedHatVersion -ge 19 ]
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

echo ''
echo "=============================================="
echo "Script: uekulele-services-5.sh                "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script starts lxc clones                 "
echo "This script installs Docker                   "
echo "=============================================="

sleep 5

clear

if [ $MultiHostVar1 = 'new' ]
then
	echo ''
	echo "=============================================="
  	echo "Install Docker...                             "
  	echo "=============================================="
  	echo ''

  	sleep 5
	
  	if [ $Release -ge 6 ]
  	then
  		sudo chmod 775 /opt/olxc/"$DistDir"/uekulele/archives/docker_install_uekulele.sh
  		/opt/olxc/"$DistDir"/uekulele/archives/docker_install_uekulele.sh $LinuxFlavor $Release
  	fi
	
  	echo ''
  	echo "=============================================="
  	echo "Done: Install Docker.                         "
  	echo "=============================================="

 	sleep 5
	
 	clear
fi

# if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ]
# then
# 	echo ''
# 	echo "=============================================="
# 	echo "Create additional OpenvSwitch networks...     "
# 	echo "=============================================="
# 	echo ''
# 
# 	sleep 5
# 
# 	clear
#
# 	SwitchList='sw2 sw3 sw4 sw5 sw6 sw7 sw8 sw9'
# 	for k in $SwitchList
# 	do
# 		if [ $Release -ge 7 ]
# 		then
# 			echo ''
# 			echo "=============================================="
# 			echo "Create systemd OpenvSwitch $k service...      "
# 			echo "=============================================="
# 
# 			if [ ! -f /etc/systemd/system/$k.service ]
# 			then
# 				sudo sh -c "echo '[Unit]'						 > /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'Description=$k Service'				>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'After=network-online.target'				>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'Type=oneshot'						>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/crt_ovs_$k.sh' 	>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$k.service"
# 			      	sudo sh -c "echo 'WantedBy=multi-user.target'				>> /etc/systemd/system/$k.service"
# 			fi
#	
#			echo ''
#			echo "=============================================="
#			echo "Start OpenvSwitch $k ...                      "
#			echo "=============================================="
#			echo ''
#
#			sudo chmod 644 /etc/systemd/system/$k.service
#			sudo systemctl enable $k.service
#			sudo service $k stop
#			sudo service $k start
#			sudo service $k status
#
#			echo ''
#			echo "=============================================="
#			echo "OpenvSwitch $k is up.                         "
#			echo "=============================================="
#		
#			sleep 3
#
#			clear
#
#		elif [ $Release -eq 6 ]
#		then
#			echo ''
#			echo "=============================================="
#			echo "Create OpenvSwitch $k service...              "
#			echo "=============================================="
#			echo ''
#
#			if [ ! -f /etc/init.d/ovs_$k ]
#			then
#				sudo cp -p /etc/network/openvswitch/switch-service-linux6.sh /etc/init.d/ovs_$k
#				sudo sed -i "s/SWK/$k/g" /etc/init.d/ovs_$k
#				sudo chmod 755 /etc/init.d/ovs_$k
#				sudo chown $Owner:$Group /etc/init.d/ovs_$k
#				sudo chkconfig --add ovs_$k
#				sudo chkconfig ovs_$k on --level 345
#				sudo chkconfig --list ovs_$k
#			else
#				sudo chkconfig --list ovs_$k
#			fi
#
#		        echo ''
#			echo "=============================================="
#			echo "Start OpenvSwitch $k ...                      "
#			echo "=============================================="
#			echo ''
#
#			sudo chmod 755 /etc/network/openvswitch/crt_ovs_$k.sh
#			sudo /etc/network/openvswitch/crt_ovs_$k.sh >/dev/null 2>&1
#			sudo ifconfig $k | tail -50
#
#			echo "=============================================="
#			echo "OpenvSwitch $k is up.                         "
#			echo "=============================================="
#			echo ''
#
#			sleep 3
#
#			clear
#		fi
#	done
#
#	echo ''
#	echo "=============================================="
#	echo "Openvswitch networks installed & configured.  "
#	echo "=============================================="
#	echo ''
#
#	sleep 5
#
#	clear
#fi

if [ $Release -ge 7 ]
then
	sudo systemctl daemon-reload
fi

# sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service lxc-net restart > /dev/null 2>&1"
# sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service systemd-resolved restart > /dev/null 2>&1"
# sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" service dnsmasq restart > /dev/null 2>&1"

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle...  "
echo "=============================================="
echo ''

function GetSeedPostfix {
	sudo lxc-ls -f | grep ora"$OracleRelease"c | cut -f1 -d' ' | cut -f2 -d'c' | sed 's/^/c/'
}
SeedPostfix=$(GetSeedPostfix)

function CheckClonedContainersExist {
	sudo ls /var/lib/lxc | grep "ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
ClonedContainersExist=$(CheckClonedContainersExist)

k=1
for j in $ClonedContainersExist
do
	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

#	sudo /etc/network/openvswitch/veth_cleanups.sh $j > /dev/null 2>&1

	echo "Starting container $j ..."
	
	if [ $Release -ge 6 ]
	then
		function CheckPublicIPIterative {
			sudo lxc-info -n $j -iH | cut -f1-3 -d'.' | sed 's/\.//g' | head -1
		}
	fi
	PublicIPIterative=$(CheckPublicIPIterative)
	echo $j | grep oel > /dev/null 2>&1
	if [ $? -eq 0 ]
	then
		sudo bash -c "cat $Config|grep ipv4|cut -f2 -d'='|sed 's/^[ \t]*//;s/[ \t]*$//'|cut -f4 -d'.'|sed 's/^/\./'|xargs -I '{}' sed -i "/ipv4/s/\{}/\.1$OR/g" $Config"
	fi
	sudo lxc-start -n $j > /dev/null 2>&1
	sleep 5
	i=1
	while [ "$PublicIPIterative" != 1020739 ] && [ "$i" -le 10 ]
	do
		echo "Waiting for $j Public IP to come up..."
		sleep 10
		PublicIPIterative=$(CheckPublicIPIterative)
		SeedPostfix=$(GetSeedPostfix)
		if [ $i -eq 5 ]
		then
                        sudo lxc-stop -n $j -k > /dev/null 2>&1
			sleep 2
                        echo ''
                        echo 'Attempting OpenvSwitch veth pair cleanup procedures...'
                        echo "Messages 'Cannot find device...' are normal in this procedure."
                        echo 'Orabuntu-LXC will re-attempt container startup after cleanup procedure.'
                        echo ''
			sudo /etc/network/openvswitch/veth_cleanups.sh $j
			echo ''
			sudo systemctl daemon-reload

			if [ $LinuxFlavor != 'Fedora' ] && [ $LinuxFlavor != 'CentOS' ] && [ $LinuxFlavor != 'Red' ]
			then
				sudo service lxc-net restart > /dev/null 2>&1
			else
				sudo sed -i '/cache-size=150/s/cache-size=150/cache-size=0/g' /etc/dnsmasq.conf
				sudo service dnsmasq restart > /dev/null 2>&1
			fi

			sleep 2
			sudo lxc-start -n $j
			sleep 2
			if [ $MajorRelease -eq 6 ] || [ $MajorRelease -eq 5 ]
			then
				sudo lxc-attach -n $j -- ntpd -x
			fi
		fi
	sleep 1
	i=$((i+1))
	done
done

sleep 5

clear

echo ''
echo "=============================================="
echo "LXC clone containers for Oracle started.      "
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
        systemd-resolve --status | head -6 | tail -5

        echo ''
        echo "=============================================="
        echo "Done: Restart systemd-resolved.               "
        echo "=============================================="
        echo ''

        sleep 5

        clear
fi

for j in $ClonedContainersExist
do
	echo ''
        echo "=============================================="
        echo "SSH to local container $j...                  "
        echo "=============================================="
        echo ''

	if [ $LinuxFlavor = 'CentOS' ] && [ $Release -eq 6 ]
	then
		sudo cp -p /etc/resolv.conf.olxc /etc/resolv.conf
	fi
	
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

if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ]
then
	echo ''
	echo "=============================================="
	echo "Create /etc/orabuntu-lxc-release file...      "
	echo "=============================================="
	echo ''

        sudo touch /etc/orabuntu-lxc-release
        sudo sh -c "echo 'Orabuntu-LXC v6.13.1-beta AMIDE' > /etc/orabuntu-lxc-release"
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
	        ifconfig sw1 | grep mtu | grep $MultiHostVar7 | wc -l
	}
	MtuSetLocalSw1=$(CheckMtuSetLocalSw1)
	
	function CheckMtuSetLocalSx1 {
	        ifconfig sx1 | grep mtu | grep $MultiHostVar7 | wc -l
	}
	MtuSetLocalSx1=$(CheckMtuSetLocalSx1)
	
	if [ $GRE = 'Y' ]
	then
	        echo ''
	        echo "=============================================="
	        echo "Set MTU $MultiHostVar7 on GRE networks...     "
	        echo "=============================================="
	        echo ''
	
	        if [ "$MtuSetLocalSw1" -eq 0 ] && [ "$MtuSetLocalSx1" -eq 0 ]
	        then
	                sudo sh -c "sed -i '/1500/s/1500/$MultiHostVar7/' /var/lib/lxc/*/config"
	                /etc/orabuntu-lxc-scripts/stop_containers.sh
	                /etc/orabuntu-lxc-scripts/start_containers.sh
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
	                ifconfig | grep mtu | grep $MultiHostVar7 | cut -f1,5 -d' ' | sed 's/  *//g' | sed 's/$/ /' | tr -d '\n'
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
	
	nslookup -timeout=1 $HOSTNAME.$Domain1 > /dev/null 2>&1
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
	
	nslookup -timeout=1 $HOSTNAME.$Domain2 > /dev/null 2>&1
	if [ $? -eq 1 ]
	then
	        echo ''
	        echo "=============================================="
	        echo "Create ADD DNS $ShortHost.$Domain2            "
	        echo "=============================================="
	        echo ''
	
	        ssh-keygen -R 10.207.29.2
	        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" mkdir -p ~/Downloads"
	        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu Downloads"
	        sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /etc/network/openvswitch/nsupdate_domain2_add_$ShortHost.sh ubuntu@10.207.29.2:~/Downloads/.
	        sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.29.2 "sudo -S <<< "ubuntu" ~/Downloads/nsupdate_domain2_add_$ShortHost.sh"
	
	        echo ''
	        echo "=============================================="
	        echo "Done: Create ADD DNS $ShortHost.$Domain2      "
	        echo "=============================================="
	        echo ''
	
	        sleep 5
	
	        clear
	fi
	
	if   [ $SystemdResolvedInstalled -ge 1 ]
	then
	        echo ''
	        echo "=============================================="
	        echo "Restart systemd-resolved...                   "
	        echo "=============================================="
	        echo ''
	
	        sudo service systemd-resolved restart
	        sleep 2
	        systemd-resolve --status | head -6 | tail -5
	
	        echo ''
	        echo "=============================================="
	        echo "Done: Restart systemd-resolved.               "
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
	
	nslookup $ShortHost.$Domain1
	
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
	
	nslookup $ShortHost.$Domain2
	
	echo "=============================================="
	echo "Done: nslookup $ShortHost.$Domain2            "
	echo "=============================================="
	
	sleep 5
	
	clear

	sudo tar --extract --file=/opt/olxc/"$DistDir"/uekulele/archives/dns-dhcp-host.tar -C / etc/network/openvswitch/ns_restore.sh
	sudo sed -i "s/NAMESERVER/$NameServer/g" /etc/network/openvswitch/ns_restore.sh
	sudo sed -i "s/DOMAIN1/$Domain1/g"	 /etc/network/openvswitch/ns_restore.sh
	sudo sed -i "s/DOMAIN2/$Domain2/g"	 /etc/network/openvswitch/ns_restore.sh

	if [ $NameServerExists -eq 1 ] && [ $GRE = 'N' ] && [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Replicate nameserver $NameServer...           "
		echo "=============================================="
		echo ''

		# new

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

                if [ $FileSystemTypeXfs -eq 1 ]
                then
                        function GetFtype {
                                xfs_info / | grep -c ftype=1
                        }
                        Ftype=$(GetFtype)

                        if [ $Ftype -eq 1 ]
                        then
                                sudo lxc-stop  -n $NameServer > /dev/null 2>&1

				if [ $Release -ge 7 ]
				then
                                	echo 'hub nameserver post-install snapshot' > /home/$Owner/snap-comment
                                	sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                                	sudo rm -f /home/$Owner/snap-comment
                                	sudo lxc-snapshot -n $NameServer -L -C
                                	sleep 5
				fi
                        fi
                fi

                if [ $FileSystemTypeExt -eq 1 ]
                then
                	sudo lxc-stop -n $NameServer    > /dev/null 2>&1

                        if [ $LinuxFlavor = 'CentOS' ]
                        then
                                if   [ $Release -ge 7 ]
                                then
					sudo lxc-stop -n $NameServer
                        		echo 'HUB nameserver post-install snapshot' > /home/$Owner/snap-comment
                        		sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                        		sudo rm -f /home/$Owner/snap-comment
                        		sudo lxc-snapshot -n $NameServer -L -C
					sudo lxc-start -n $NameServer

                                elif [ $Release -eq 6 ]
				then
					echo ''
					echo "=============================================="
					echo "LXC snapshot not supported on this fs/kernel. "
					echo "=============================================="
					echo ''
                                fi
			fi
                        
			if [ $LinuxFlavor = 'Oracle' ]
                        then
                                if   [ $Release -ge 7 ]
                                then
					sudo lxc-stop -n $NameServer
                        		echo 'HUB nameserver post-install snapshot' > /home/$Owner/snap-comment
                        		sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                        		sudo rm -f /home/$Owner/snap-comment
                        		sudo lxc-snapshot -n $NameServer -L -C
					sudo lxc-start -n $NameServer

                                elif [ $Release -eq 6 ]
				then
					echo ''
					echo "=============================================="
					echo "LXC snapshot not supported on this fs/kernel. "
					echo "=============================================="
					echo ''
                                fi
			fi
                fi

                if [ $FileSystemTypeBtrfs -eq 1 ]
                then
			if [ $LinuxFlavor = 'CentOS' ]
			then
				if [ $Release -eq 7 ]
				then
					sudo lxc-stop -n $NameServer
                       			echo 'HUB nameserver post-install snapshot' > /home/$Owner/snap-comment
                       			sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                       			sudo rm -f /home/$Owner/snap-comment
                       			sudo lxc-snapshot -n $NameServer -L -C
					sudo lxc-start -n $NameServer

				elif [ $Release -eq 6 ]
				then
					echo ''
					echo "=============================================="
					echo "LXC snapshot not supported on this fs/kernel. "
					echo "=============================================="
					echo ''
				fi
			fi
			
			if [ $LinuxFlavor = 'Oracle' ]
			then
				if [ $Release -ge 7 ]
				then
					sudo lxc-stop -n $NameServer
                       			echo 'HUB nameserver post-install snapshot' > /home/$Owner/snap-comment
                       			sudo lxc-snapshot -n $NameServer -c /home/$Owner/snap-comment
                       			sudo rm -f /home/$Owner/snap-comment
                       			sudo lxc-snapshot -n $NameServer -L -C
					sudo lxc-start -n $NameServer

				elif [ $Release -eq 6 ]
				then
					echo ''
					echo "=============================================="
					echo "LXC snapshot not supported on this fs/kernel. "
					echo "=============================================="
					echo ''
				fi
			fi
                fi
                
		if [ ! -e ~/Manage-Orabuntu ]
                then
                        sudo mkdir -p ~/Manage-Orabuntu
                fi

                echo "/var/lib/lxc/$NameServer"         >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
                echo "/var/lib/lxc/$NameServer-base"    >> /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst
		sudo tar -P -czf $HOME/Manage-Orabuntu/$NameServer.tar.gz -T /opt/olxc/"$DistDir"/uekulele/archives/nameserver.lst --checkpoint=10000 --totals
		sudo lxc-start -n $NameServer > /dev/null 2>&1

                echo ''
                echo "=============================================="
                echo "Configure replica nameserver $NameServer...   "
                echo "=============================================="
                echo ''

                ssh-keygen -R 10.207.39.2
                ssh-keygen -R $NameServer
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

#	if [ $GRE = 'Y' ]
#	GLS 20180202 Include VMs too.

 	if [ $MultiHostVar2 = 'Y' ] && [ $MultiHostVar1 = 'new' ]
 	then
                echo ''
                echo "=============================================="
                echo "Configure replica nameserver $NameServer...   "
                echo "=============================================="
                echo ''

                ssh-keygen -R 10.207.39.2
                ssh-keygen -R $NameServer
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" echo $HOSTNAME > ~/new_gre_host.txt"
		sleep 5
	
		if   [ $SystemdResolvedInstalled -ge 1 ]
		then
		        echo ''
	        	echo "=============================================="
	        	echo "Restart systemd-resolved...                   "
	        	echo "=============================================="
	        	echo ''
	
	        	sudo service systemd-resolved restart
	        	sleep 2
	        	systemd-resolve --status | head -6 | tail -5
	
	        	echo ''
	        	echo "=============================================="
	        	echo "Done: Restart systemd-resolved.               "
	        	echo "=============================================="
	        	echo ''
	
	        	sleep 5
		fi
                
                echo ''
                echo "=============================================="
                echo "Done: Configure replica nameserver $NameServer"
                echo "=============================================="

                sleep 5

                clear
 	fi
	
	if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ]
	then
		echo ''
		echo "=============================================="
		echo "Create selinux-lxc.sh file...                 "
		echo "=============================================="
		echo ''
	
		sudo mkdir -p /opt/olxc/"$DistDir"/uekulele/selinux
		sudo chmod 777 /opt/olxc/"$DistDir"/uekulele/selinux
		touch /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		ls -l /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		sudo chmod 777 /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		cd /opt/olxc/"$DistDir"/uekulele/selinux
	
		echo 'sudo ausearch -c 'lxcattach' --raw | audit2allow -M my-lxcattach'			>  /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-lxcattach.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'dhclient' --raw | audit2allow -M my-dhclient'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-dhclient.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'passwd' --raw | audit2allow -M my-passwd'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-passwd.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'sedispatch' --raw | audit2allow -M my-sedispatch'		>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-sedispatch.pp'						>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'systemd-sysctl' --raw | audit2allow -M my-systemdsysctl'	>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-systemdsysctl.pp'						>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'ovs-vsctl' --raw | audit2allow -M my-ovsvsctl'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-ovsvsctl.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'sshd' --raw | audit2allow -M my-sshd'				>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-sshd.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'gdm-session-wor' --raw | audit2allow -M my-gdmsessionwor'	>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-gdmsessionwor.pp'						>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'pickup' --raw | audit2allow -M my-pickup'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-pickup.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'sedispatch' --raw | audit2allow -M my-sedispatch'		>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-sedispatch.pp'						>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'iscsid' --raw | audit2allow -M my-iscsid'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-iscsid.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'dhclient' --raw | audit2allow -M my-dhclient'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-dhclient.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'ovs-vsctl' --raw | audit2allow -M my-ovsvsctl'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-ovsvsctl.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'chpasswd' --raw | audit2allow -M my-chpasswd'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-chpasswd.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'colord' --raw | audit2allow -M my-colord'			>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-colord.pp'							>> /opt/olxc/"$DistDir"/uekulele/selinux/selinux-lxc.sh
	
		echo ''
		echo "=============================================="
		echo "Created selinux-lxc.sh file.                  "
		echo "=============================================="
	
		sleep 5
	
		clear
	
		echo ''
		echo "=============================================="
		echo "Apply selected selinux adjustments for lxc... "
		echo "=============================================="
		echo ''
	
		function GetFacter {
			facter virtual
		}
		Facter=$(GetFacter)
		if [ $Facter = 'physical' ]
		then
			sudo setenforce 0
			sudo getenforce
			if [ -f /etc/sysconfig/selinux ]
			then
				echo ''
				echo "=============================================="
				echo "Set SELINUX to Permissive mode.               "
				echo "=============================================="
				echo ''
		
				sudo sed -i '/\([^T][^Y][^P][^E]\)\|\([^#]\)/ s/enforcing/permissive/' /etc/sysconfig/selinux
			fi
		
			echo "=============================================="
			echo "Apply semodules (patience takes a minute...)  "
			echo "=============================================="
			echo ''
	
			sudo ausearch -c 'lxcattach' --raw | audit2allow -M my-lxcattach > /dev/null 2>&1
			sudo semodule -i my-lxcattach.pp > /dev/null 2>&1
			sudo ausearch -c 'dhclient' --raw | audit2allow -M my-dhclient > /dev/null 2>&1
			sudo semodule -i my-dhclient.pp > /dev/null 2>&1
			sudo ausearch -c 'passwd' --raw | audit2allow -M my-passwd > /dev/null 2>&1
			sudo semodule -i my-passwd.pp > /dev/null 2>&1
			sudo ausearch -c 'sedispatch' --raw | audit2allow -M my-sedispatch > /dev/null 2>&1
			sudo semodule -i my-sedispatch.pp > /dev/null 2>&1
			sudo ausearch -c 'systemd-sysctl' --raw | audit2allow -M my-systemdsysctl > /dev/null 2>&1
			sudo semodule -i my-systemdsysctl.pp > /dev/null 2>&1
			sudo ausearch -c 'ovs-vsctl' --raw | audit2allow -M my-ovsvsctl > /dev/null 2>&1
			sudo semodule -i my-ovsvsctl.pp > /dev/null 2>&1
			sudo ausearch -c 'sshd' --raw | audit2allow -M my-sshd > /dev/null 2>&1
			sudo semodule -i my-sshd.pp > /dev/null 2>&1
			sudo ausearch -c 'gdm-session-wor' --raw | audit2allow -M my-gdmsessionwor > /dev/null 2>&1
			sudo semodule -i my-gdmsessionwor.pp > /dev/null 2>&1
			sudo ausearch -c 'pickup' --raw | audit2allow -M my-pickup > /dev/null 2>&1
			sudo semodule -i my-pickup.pp > /dev/null 2>&1
			sudo ausearch -c 'sedispatch' --raw | audit2allow -M my-sedispatch > /dev/null 2>&1
			sudo semodule -i my-sedispatch.pp > /dev/null 2>&1
			sudo ausearch -c 'iscsid' --raw | audit2allow -M my-iscsid > /dev/null 2>&1
			sudo semodule -i my-iscsid.pp > /dev/null 2>&1
			sudo ausearch -c 'dhclient' --raw | audit2allow -M my-dhclient > /dev/null 2>&1
			sudo semodule -i my-dhclient.pp > /dev/null 2>&1
			sudo ausearch -c 'ovs-vsctl' --raw | audit2allow -M my-ovsvsctl > /dev/null 2>&1
			sudo semodule -i my-ovsvsctl.pp > /dev/null 2>&1
			sudo ausearch -c 'chpasswd' --raw | audit2allow -M my-chpasswd > /dev/null 2>&1
			sudo semodule -i my-chpasswd.pp > /dev/null 2>&1
			sudo ausearch -c 'colord' --raw | audit2allow -M my-colord > /dev/null 2>&1
			sudo semodule -i my-colord.pp > /dev/null 2>&1
			sudo ausearch -c 'ntpd' --raw | audit2allow -M my-ntpd > /dev/null 2>&1
			sudo semodule -i my-ntpd.pp > /dev/null 2>&1
		else
			sudo setenforce 0
			sudo getenforce
			echo ''
			if [ -f /etc/sysconfig/selinux ]
			then
				echo ''
				echo "=============================================="
				echo "Set SELINUX to Permissive mode.               "
				echo "=============================================="
				echo ''
	
				sudo sed -i '/\([^T][^Y][^P][^E]\)\|\([^#]\)/ s/enforcing/permissive/' /etc/sysconfig/selinux
			fi
	
			echo "=============================================="
			echo "Apply semodules (patience takes a minute...)  "
			echo "=============================================="
			echo ''
	
			sudo ausearch -c 'passwd' --raw | audit2allow -M my-passwd > /dev/null 2>&1
			sudo semodule -i my-passwd.pp > /dev/null 2>&1
			sudo ausearch -c 'chpasswd' --raw | audit2allow -M my-chpasswd > /dev/null 2>&1
			sudo semodule -i my-chpasswd.pp > /dev/null 2>&1
		fi
	
		echo "=============================================="
		echo "Set selinux to permissive & set rules.        "
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
        echo "LXC  Containers...                            "
        echo "=============================================="
        echo ''

        sudo lxc-ls -f

        echo ''
        echo "=============================================="
        echo "Docker Containers...                          "
        echo "=============================================="
        echo ''

        sudo docker ps -a

	echo ''
        echo "=============================================="
        echo "To ssh to Docker raesene/alpine-nettools:     "
        echo "                                              "
        echo "     ssh username@localhost -p 2200           "
        echo "                                              "
        echo "=============================================="
        echo ''
        echo "=============================================="
        echo "Done: List Containers.                        "
        echo "=============================================="

	sleep 5

	clear

	echo ''
	echo "=============================================="
	echo "Management links directory creation...        "
	echo "=============================================="
	
	if [ ! -e $HOME/Manage-Orabuntu ]
	then
		sudo mkdir -p $HOME/Manage-Orabuntu
	fi
		
	cd $HOME/Manage-Orabuntu
	sudo chmod 755 /etc/orabuntu-lxc-scripts/crt_links.sh
	sudo /etc/orabuntu-lxc-scripts/crt_links.sh
	
	echo ''
	sudo ls -l $HOME/Manage-Orabuntu | tail -5
	echo '...'
	
	echo ''
	echo "=============================================="
	echo "Management links directory created.           "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Note that deployment management links are in: "
	echo "                                              "
	echo "     $HOME/Manage-Orabuntu                    "
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
	echo "     cd ../uekulele/archives/scst-files       "
	echo "     cat README                               "
	echo "     ./create-scst.sh                         "
	echo "=============================================="
	echo ''
	
	sleep 5
fi

# Set permissions on scst-files and cleanup staging area

sudo rm -f /opt/olxc/*.lst /opt/olxc/*.tar
# if [ $Owner != 'ubuntu' ]
# then
# 	sudo rm -r /opt/olxc/home/ubuntu
# fi

cd "$DistDir"/uekulele/archives
rm -f uekulele-services.lst uekulele-files.lst product.lst uekulele-services.tar uekulele-files.tar product.tar
cd "$DistDir"/installs/logs
LOGEXT=`date +"%Y-%m-%d.%R:%S"`
sudo cp -p /opt/olxc/installs/logs/$USER.log /opt/olxc/installs/logs/$USER.orabuntu-lxc.install.$LOGEXT
cd $DistDir/anylinux

# Band-aid for openvswitch update which breaks openvswitch.
# This will need a fix so that openvswitch updates are applied during dnf-updates.

if [ $LinuxFlavor = 'Fedora' ]
then
	sudo sh -c "echo 'exclude=openvswitch*' >> /etc/dnf/dnf.conf"
fi
sudo rm -f  /etc/sudoers.d/orabuntu-lxc
sudo rm -rf /opt/olxc/opt 
