#!/bin/bash

#    Copyright 2015-2018 Gilbert Standen
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

#    v2.4 	GLS 20151224
#    v2.8 	GLS 20151231
#    v3.0 	GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 	GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 	GLS 20170909 Orabuntu-LXC MultiHost
#    v5.33-beta	GLS 20180106 Orabuntu-LXC EE MultiHost Docker AWS S3

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet though (a feature this software does not yet support - it's on the roadmap) to match your subnet manually.

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
NameServer=$5
MultiHost=$6
OR=$OracleRelease
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

function CheckLxcNetRunning {
	sudo systemctl | grep lxc-net | grep 'loaded active exited' | wc -l
}
LxcNetRunning=$(CheckLxcNetRunning)

function GetRedHatVersion {
	cat /etc/redhat-release  | cut -f7 -d' ' | cut -f1 -d'.'
}
RedHatVersion=$(GetRedHatVersion)

function CheckNameServerExists {
        sudo lxc-info -n $NameServer 2>&1 | grep -i name | wc -l
}
NameServerExists=$(CheckNameServerExists)

echo ''
echo "=============================================="
echo "Script: uekulele-services-5.sh                  "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable.                   "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script starts lxc clones                 "
echo "=============================================="

sleep 5

clear

if [ $MultiHostVar1 = 'new' ] || [ $MultiHostVar1 = 'reinstall' ]
then
	echo ''
	echo "=============================================="
	echo "Create additional OpenvSwitch networks...     "
	echo "=============================================="
	echo ''

	sleep 5

	clear

	SwitchList='sw2 sw3 sw4 sw5 sw6 sw7 sw8 sw9'
	for k in $SwitchList
	do
		echo ''
		echo "=============================================="
		echo "Create systemd OpenvSwitch $k service...      "
		echo "=============================================="

        	if [ ! -f /etc/systemd/system/$k.service ]
        	then
               		sudo sh -c "echo '[Unit]'						 > /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'Description=$k Service'				>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'After=network-online.target'				>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Service]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'Type=oneshot'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'User=root'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'RemainAfterExit=yes'					>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'ExecStart=/etc/network/openvswitch/crt_ovs_$k.sh' 	>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo ''							>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo '[Install]'						>> /etc/systemd/system/$k.service"
                	sudo sh -c "echo 'WantedBy=multi-user.target'				>> /etc/systemd/system/$k.service"
	
			echo ''
			echo "=============================================="
			echo "Start OpenvSwitch $k ...                      "
			echo "=============================================="
			echo ''

			sudo chmod 644 /etc/systemd/system/$k.service
			sudo systemctl enable $k.service
			sudo service $k stop
			sudo service $k start
			sudo service $k status

			echo ''
			echo "=============================================="
			echo "OpenvSwitch $k is up.                         "
			echo "=============================================="
		fi
	
		sleep 3

		clear
	done

	echo ''
	echo "=============================================="
	echo "Openvswitch networks installed & configured.  "
	echo "=============================================="
	echo ''

	sleep 5

	clear
fi

echo ''
echo "=============================================="
echo "Starting LXC cloned containers for Oracle...  "
echo "=============================================="

function CheckClonedContainersExist {
	sudo ls /var/lib/lxc | grep "ora$OracleRelease" | sort -V | sed 's/$/ /' | tr -d '\n' 
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

#	sudo /etc/network/openvswitch/veth_cleanups.sh $j > /dev/null 2>&1

	echo ''
	echo "Starting container $j ..."
	echo ''
	
	if [ $RedHatVersion -ge 6 ]
	then
		function CheckPublicIPIterative {
			sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f2 -d'-' | sed 's/^[ \t]*//;s/[ \t]*$//' | cut -f1 -d' ' | cut -f1-2 -d'.' | sed 's/\.//g'
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
	while [ "$PublicIPIterative" != 10207 ] && [ "$i" -le 10 ]
	do
		echo "Waiting for $j Public IP to come up..."
		sleep 20
		PublicIPIterative=$(CheckPublicIPIterative)
		if [ $i -eq 5 ]
		then
			sudo lxc-stop -n $j
			sleep 2
			echo ''
			sudo /etc/network/openvswitch/veth_cleanups.sh $j
			echo ''
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

elif [ $LxcNetRunning -ge 1 ] 
then
        echo ''
        echo "=============================================="
        echo "Restart service lxc-net...                    "
        echo "=============================================="
        echo ''

        sudo service lxc-net restart
        sleep 2
        sudo service lxc-net status

        echo ''
        echo "=============================================="
        echo "Done: Restart service lxc-net.                "
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
	
	ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $j
        sshpass -p oracle ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no oracle@$j "uname -a; cat /etc/oracle-release"

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
        sudo sh -c "echo 'Orabuntu-LXC v5.33-beta' > /etc/orabuntu-lxc-release"
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
	
	        ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 10.207.39.2
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
	
	        ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 10.207.29.2
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

	elif [ $LxcNetRunning -ge 1 ]
	then
		echo ''
		echo "=============================================="
		echo "Restart service lxc-net...                    "
		echo "=============================================="
		echo ''

		sudo service lxc-net restart
		sleep 2
		sudo service lxc-net status

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

	sudo tar -P --extract --file=/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/dns-dhcp-host.tar /etc/network/openvswitch/ns_restore.sh
	sudo sed -i "s/NAMESERVER/$NameServer/g" /etc/network/openvswitch/ns_restore.sh

	if [ $NameServerExists -eq 1 ] && [ $GRE = 'N' ] && [ $MultiHostVar2 = 'N' ]
	then
		echo ''
		echo "=============================================="
		echo "Replicate nameserver $NameServer...           "
		echo "=============================================="
		echo ''
	
		sudo lxc-stop  -n $NameServer

		sudo lxc-info -n "$NameServer"-bk0 > /dev/null 2>&1
		if [ $? -eq 1 ]
		then
			sudo lxc-copy  -n $NameServer -N "$NameServer"-bk0
		fi
		
		if [ ! -e /home/ubuntu/Manage-Orabuntu ]
		then
			mkdir /home/ubuntu/Manage-Orabuntu
		fi
		
		sudo tar -P -czf ~/Manage-Orabuntu/$NameServer.tar.gz -T ~/Downloads/orabuntu-lxc-master/uekulele/archives/nameserver.lst --checkpoint=10000 --totals
		sudo lxc-start -n $NameServer
		
		echo ''
		echo "=============================================="
		echo "Done: Replicate nameserver $NameServer.       "
		echo "=============================================="
		echo ''
	
		sleep 5

		clear
	fi

 	if [ $NameServerExists -eq 0 ] && [ $GRE = 'Y' ]
 	then
  		echo ''
  		echo "=============================================="
  		echo "Replicate nameserver $NameServer...           "
  		echo "=============================================="
  		echo ''
 
  		/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/nameserver_copy.sh $MultiHostVar5 $MultiHostVar6 $NameServer
	
  		echo ''
  		echo "=============================================="
  		echo "Done: Replicate nameserver $NameServer.       "
  		echo "=============================================="
  		echo ''
	
  		sleep 5

  		clear

                echo ''
                echo "=============================================="
                echo "Configure replica nameserver $NameServer...   "
                echo "=============================================="
                echo ''

                ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R 10.207.39.2
                ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $NameServer
		sshpass -p ubuntu scp -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2:/home/ubuntu/gre_hosts.txt /home/ubuntu/Manage-Orabuntu/gre_hosts.txt
		if [ $? -eq 0 ] && [ -s /home/ubuntu/Manage-Orabuntu/gre_hosts.txt ]
		then
			function GetGreHosts {
				cat /home/ubuntu/Manage-Orabuntu/gre_hosts.txt | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
			}
			GreHosts=$(GetGreHosts)
			for g in $GreHosts
			do
                		ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R $g
				sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$g "sudo -S <<< "ubuntu" lxc-stop -n $NameServer"
			done
		fi
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
	
		elif [ $LxcNetRunning -ge 1 ]
		then
			echo ''
			echo "=============================================="
			echo "Restart service lxc-net...                    "
			echo "=============================================="
			echo ''

			sudo service lxc-net restart
			sleep 2
			sudo service lxc-net status

			echo ''
			echo "=============================================="
			echo "Done: Restart service lxc-net.                "
			echo "=============================================="
			echo ''

			sleep 5
		fi
                
		sshpass -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@10.207.39.2 "sudo -S <<< "ubuntu" echo $HOSTNAME > /home/ubuntu/new_gre_host.txt"

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
	
		mkdir -p /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux
		touch /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		ls -l /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		sudo chmod 775 /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		cd /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux
	
		echo 'sudo ausearch -c 'lxcattach' --raw | audit2allow -M my-lxcattach'			>  /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-lxcattach.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'dhclient' --raw | audit2allow -M my-dhclient'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-dhclient.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'passwd' --raw | audit2allow -M my-passwd'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-passwd.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'sedispatch' --raw | audit2allow -M my-sedispatch'		>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-sedispatch.pp'						>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'systemd-sysctl' --raw | audit2allow -M my-systemdsysctl'	>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-systemdsysctl.pp'						>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'ovs-vsctl' --raw | audit2allow -M my-ovsvsctl'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-ovsvsctl.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'sshd' --raw | audit2allow -M my-sshd'				>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-sshd.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'gdm-session-wor' --raw | audit2allow -M my-gdmsessionwor'	>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-gdmsessionwor.pp'						>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'pickup' --raw | audit2allow -M my-pickup'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-pickup.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'sedispatch' --raw | audit2allow -M my-sedispatch'		>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-sedispatch.pp'						>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'iscsid' --raw | audit2allow -M my-iscsid'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-iscsid.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'dhclient' --raw | audit2allow -M my-dhclient'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-dhclient.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'ovs-vsctl' --raw | audit2allow -M my-ovsvsctl'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-ovsvsctl.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'chpasswd' --raw | audit2allow -M my-chpasswd'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-chpasswd.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo ausearch -c 'colord' --raw | audit2allow -M my-colord'			>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
		echo 'sudo semodule -i my-colord.pp'							>> /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/selinux/selinux-lxc.sh
	
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

	if [ $MultiHostVar1 = 'new' ]
	then
		echo ''
		echo "=============================================="
		echo "Install Docker...                             "
		echo "=============================================="
		echo ''
	
		sleep 5
	
		if [ $RedHatVersion -eq 7 ]
		then
			/home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/docker_install_oracle_7.sh
		fi
	
		echo ''
		echo "=============================================="
		echo "Done: Install Docker.                         "
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
	echo ''
	echo "=============================================="
	echo "Management links directory creation...        "
	echo "=============================================="
	
	cd /home/ubuntu/Manage-Orabuntu
	sudo chmod 755 /etc/orabuntu-lxc-scripts/crt_links.sh
	sudo /etc/orabuntu-lxc-scripts/crt_links.sh
	
	echo ''
	sudo ls -l /home/ubuntu/Manage-Orabuntu | tail -5
	echo '...'
	
	echo ''
	echo "=============================================="
	echo "Management links directory created.           "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Note that deployment management links are in: "
	echo "                                              "
	echo "     /home/ubuntu/Manage-Orabuntu             "
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
