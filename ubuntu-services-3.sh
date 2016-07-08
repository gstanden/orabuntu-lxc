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

#!/bin/bash

clear

# v2.4 GLS 20151224

echo ''
echo "=============================================="
echo "Script:  ubuntu-services-3.sh                 "
echo "                                              "
echo "This script extracts customzed files to       "
echo "the container required for running Oracle     "
echo "=============================================="
echo ''
echo "=============================================="
echo "This script is re-runnable                    "
echo "=============================================="
echo ''

OracleRelease=$1$2
OracleVersion=$1.$2

sleep 5

clear

echo ''
echo "=============================================="
echo "WAN google.com ping test...                   "
echo "=============================================="
echo ''

ping -c 3 google.com

function CheckNetworkUp {
ping -c 3 google.com | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
n=1
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -le 5 ]
do
NetworkUp=$(CheckNetworkUp)
n=$((n+1))
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "WAN google.com not reliably pingable.         "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "WAN google.com is reliably pingable.          "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Initialize LXC Seed Container on OpenvSwitch.."
echo "=============================================="

cd /etc/network/if-up.d/openvswitch

# GLS 20151222 I don't think this step does anything anymore.  Commenting for now, removal pending.
#sudo sed -i "s/lxcora01/oel$OracleRelease/" /var/lib/lxc/oel$OracleRelease/config

function CheckContainerUp {
sudo lxc-ls -f | grep oel$OracleRelease | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

function CheckPublicIP {
sudo lxc-ls -f | sed 's/  */ /g' | grep oel$OracleRelease | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

echo ''
echo "=============================================="
echo "Starting LXC Seed Container for Oracle        "
echo "'cannot find...' messages are normal...       "
echo "=============================================="
echo ''

if [ $ContainerUp != 'RUNNING' ] || [ $PublicIP != 1020729 ]
then
	function CheckContainersExist {
	sudo ls /var/lib/lxc | grep oel$OracleRelease | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ContainersExist=$(CheckContainersExist)
	sleep 5
        for j in $ContainersExist
        do
                # GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
                # GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10
                function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
                }
                UbuntuVersion=$(GetUbuntuVersion)
                # GLS 20160707
                if [ $UbuntuVersion = 15.04 ] || [ $UbuntuVersion = 15.10 ]
                then
                function CheckPublicIPIterative {
                sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f3 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
                }
                fi
                if [ $UbuntuVersion = 16.04 ]
                then
                function CheckPublicIPIterative {
                sudo lxc-ls -f | sed 's/  */ /g' | grep $j | grep RUNNING | cut -f5 -d' ' | sed 's/,//' | cut -f1-2 -d'.' | sed 's/\.//g'
                }
                fi
		PublicIPIterative=$(CheckPublicIPIterative)
		echo "Starting container $j ..."
		echo ''
		sudo lxc-start -n $j > /dev/null 2>&1
		i=1
		while [ "$PublicIPIterative" != 1020729 ] && [ "$i" -le 10 ]
		do
			echo "Waiting for $j Public IP to come up..."
			echo ''
			sleep 5
			PublicIPIterative=$(CheckPublicIPIterative)
			if [ $i -eq 5 ]
			then
			echo ''
			sudo lxc-stop -n $j > /dev/null 2>&1
			sudo /etc/network/openvswitch/veth_cleanups.sh oel$OracleRelease
			echo ''
			sudo lxc-start -n $j > /dev/null 2>&1
			fi
		sleep 1
		i=$((i+1))
		done
	done
	echo "=============================================="
	echo "LXC Seed Container for Oracle started.        "
	echo "=============================================="
	echo ''
	echo "=============================================="
	echo "Waiting for final container initialization.   " 
	echo "=============================================="
fi

echo ''
echo "==============================================" 
echo "Public IP is up on oel$OracleRelease          "
echo ''
sudo lxc-ls -f
echo ''
echo "=============================================="
echo "Container Up.                                 "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Container oel$OracleRelease ping test...      "
echo "=============================================="
echo ''

ping -c 3 oel$OracleRelease

function CheckNetworkUp {
ping -c 3 oel$OracleRelease | grep packet | cut -f3 -d',' | sed 's/ //g'
}
NetworkUp=$(CheckNetworkUp)
n=1
while [ "$NetworkUp" !=  "0%packetloss" ] && [ "$n" -le 5 ]
do
NetworkUp=$(CheckNetworkUp)
n=$((n+1))
done

if [ "$NetworkUp" != '0%packetloss' ]
then
echo ''
echo "=============================================="
echo "Container oel$OracleRelease not pingable.     "
echo "Script exiting.                               "
echo "=============================================="
exit
else
echo ''
echo "=============================================="
echo "Container oel$OracleRelease is pingable.      "
echo "=============================================="
echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Testing passwordless-ssh for root user        "
echo "=============================================="
echo "Output of 'uname -a' in oel$OracleRelease...  "
echo "=============================================="
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease uname -a
if [ $? -ne 0 ]
then
echo ''
echo "=============================================="
echo "No-password oel$OracleRelease ssh has issue. "
echo "No-password oel$OracleRelease must succeed.   "
echo "Fix issues retry script.                      "
echo "Script exiting.                               "
echo "=============================================="
exit
fi
echo ''
echo "=============================================="
echo "No-password oel$OracleRelease ssh successful. "
echo "=============================================="

sleep 5

clear

echo ''
echo "=============================================="
echo "Logged into LXC container oel$OracleRelease   "
echo "Setting owner and modes...                    "
echo "=============================================="
echo ''

sudo mkdir -p /home/grid/grid/rpm

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease /root/packages.sh
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease /root/create_users.sh
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease /root/lxc-services.sh
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease rpm -Uvh /home/grid/grid/rpm/cvuqdisk-1.0.9-1.rpm
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease usermod --password `perl -e "print crypt('grid','grid');"` grid
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease usermod --password `perl -e "print crypt('oracle','oracle');"` oracle
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease usermod -g oinstall oracle
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown oracle:oinstall /home/oracle/.bash_profile
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown oracle:oinstall /home/oracle/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown oracle:oinstall /home/oracle/.kshrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown oracle:oinstall /home/oracle/.bash_logout
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown oracle:oinstall /home/oracle/.
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/grid
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/grid/rpm
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/.bash_profile
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/.bashrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/.kshrc
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/.bash_logout
sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@oel$OracleRelease chown grid:oinstall /home/grid/.

echo ''  
echo "=============================================="
echo "Installing files and packages for Oracle done."
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Next script to run: ubuntu-services-4.sh     "
echo "=============================================="

sleep 5
