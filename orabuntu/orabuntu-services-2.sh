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

echo ''
echo "=============================================="
echo "orabuntu-services-2.sh                        "
echo "                                              "
echo "Script creates the Oracle Linux container.    "
echo "=============================================="
echo ''

sleep 5

clear

MajorRelease=$1
OracleRelease=$1$2
OracleVersion=$1.$2
Domain1=$3
Domain2=$4
MultiHost=$5
NameServer=$6
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

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

function GetUbuntuVersion {
	cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
}
UbuntuVersion=$(GetUbuntuVersion)

function GetLXCVersion {
        lxc-create --version
}
LXCVersion=$(GetLXCVersion)

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
StorageDriver=$MultiHostVar16

function GetMultiHostVar17 {
        echo $MultiHost | cut -f17 -d':'
}
MultiHostVar17=$(GetMultiHostVar17)
StoragePoolName=$MultiHostVar17

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

if [ -f /etc/lsb-release ]
then
        function GetUbuntuVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'='
        }
        UbuntuVersion=$(GetUbuntuVersion)
fi
RL=$UbuntuVersion

if [ -f /etc/lsb-release ]
then
        function GetUbuntuMajorVersion {
                cat /etc/lsb-release | grep DISTRIB_RELEASE | cut -f2 -d'=' | cut -f1 -d'.'
        }
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
fi

if [ $SystemdResolvedInstalled -ge 1 ]
then
	echo ''
	echo "=============================================="
	echo "Restart Systemd-Resolved ...                  "
	echo "=============================================="
	echo ''

#	sudo service systemd-resolved-helper restart
	echo ''
	sleep 5
	sudo service systemd-resolved status | tail -100
	echo ''
	sleep 5
	sudo service systemd-resolved-helper status
	
	echo ''
	echo "=============================================="
	echo "Done: Restart Systemd-Resolved.               "
	echo "=============================================="

	sleep 5

	clear
fi

function ConfirmContainerCreated {
	sudo lxc-ls -f | grep oel$OracleRelease$SeedPostfix | wc -l
}
ContainerCreated=$(ConfirmContainerCreated)

if   [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'Y' ]
then
	SeedIndex=10
	SeedPostfix=c$SeedIndex

	function GetNameServerShortName {
		echo $NameServer | cut -f1 -d'-'
	}
	NameServerShortName=$(GetNameServerShortName)

	function CheckDNSLookup {
		sudo host -W1 oel$OracleRelease$SeedPostfix | grep '10\.207\.29' | wc -l
	}
	DNSLookup=$(CheckDNSLookup)

	if [ $UbuntuMajorVersion -ge 16 ] || [ $Release -ge 6 ]
	then
       		while [ $DNSLookup -eq 1 ]
       		do
               		SeedIndex=$((SeedIndex+1))
			SeedPostfix=c$SeedIndex
               		DNSLookup=$(CheckDNSLookup)
       		done
		SeedPostfix=c$SeedIndex
	fi

elif [ $MultiHostVar3 = '1' ] && [ $GREValue = 'N' ]
then
	SeedIndex=10
	SeedPostfix=c$SeedIndex

	if [ $ContainerCreated -gt 0 ]
	then
		function CheckHighestSeedIndexHit {
        		sudo host -W1 oel$OracleRelease$SeedPostfix | grep '10\.207\.29' | wc -l
		}
		HighestSeedIndexHit=$(CheckHighestSeedIndexHit)

		while [ $HighestSeedIndexHit = 1 ]
		do
        		SeedIndex=$((SeedIndex+1))
        		SeedPostfix=c$SeedIndex
        		HighestSeedIndexHit=$(CheckHighestSeedIndexHit)
		done
		SeedPostfix=c$SeedIndex
	else
		SeedPostfix=c$SeedIndex
	fi
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

m=1; n=1; p=1
if [ $UbuntuMajorVersion -gt 16 ]
then
	while [ $ContainerCreated -eq 0 ] && [ $m -le 3 ]
	do
		echo ''
		echo "=============================================="
		echo "   Create the LXC Oracle Linux container      "
		echo "                                              "
		echo "      Note: Depends on download speed         "
		echo "                                              "
		echo "                 Method 1                     "
		echo "=============================================="
		echo ''

		dig +short us.images.linuxcontainers.org

		if [ -d ~/Downloads/orabuntu-lxc-master/lxcimage/oracle"$MajorRelease" ]
		then
			sudo rm -f ~/Downloads/orabuntu-lxc-master/lxcimage/oracle"$MajorRelease"/*
		fi

		mkdir -p "$DistDir"/lxcimage/oracle"$MajorRelease"
		cd       "$DistDir"/lxcimage/oracle"$MajorRelease"
		sudo rm -f index.html
		wget -4 -q https://us.images.linuxcontainers.org/images/oracle/"$MajorRelease"/amd64/default/ -P "$DistDir"/lxcimage/oracle"$MajorRelease"
		function GetBuildDate {
			grep folder.gif index.html | tail -1 | awk -F "\"" '{print $8}' | sed 's/\///g' | sed 's/\.//g'
		}
		BuildDate=$(GetBuildDate)
		wget -4 -q https://us.images.linuxcontainers.org/images/oracle/"$MajorRelease"/amd64/default/"$BuildDate"/SHA256SUMS -P "$DistDir"/lxcimage/oracle"$MajorRelease"
		for i in rootfs.tar.xz meta.tar.xz
		do
			rm -f $DistDir/lxcimage/oracle"$MajorRelease"/$i
			echo ''
			wget -4 -q --show-progress https://us.images.linuxcontainers.org/images/oracle/"$MajorRelease"/amd64/default/"$BuildDate"/$i -P "$DistDir"/lxcimage/oracle"$MajorRelease"
			diff <(shasum -a 256 "$DistDir"/lxcimage/oracle"$MajorRelease"/$i | cut -f1,8 -d'/' | sed 's/  */ /g' | sed 's/\///' | sed 's/  */ /g') <(grep $i "$DistDir"/lxcimage/oracle"$MajorRelease"/SHA256SUMS)
		done
		if [ $? -eq 0 ]
		then
			echo ''
			sudo lxc-create -t local -n oel$OracleRelease$SeedPostfix -- -m $DistDir/lxcimage/oracle"$MajorRelease"/meta.tar.xz -f $DistDir/lxcimage/oracle"$MajorRelease"/rootfs.tar.xz
	
			if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
			then
  				sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
			fi
		fi

		ContainerCreated=$(ConfirmContainerCreated)
		rm -f index.html
		m=$((m+1))
	done
fi

sleep 5

n=1
if [ $UbuntuMajorVersion -ge 20 ] # Because yum is no longer available in Ubuntu 20
then
	while [ $ContainerCreated -eq 0 ] && [ $n -le 5 ]
	do
		echo ''
		echo "=============================================="
		echo "   Create the LXC Oracle Linux container      "
		echo "                                              "
		echo "      Note: Depends on download speed         "
		echo "                                              "
		echo "                 Method 2                     "
		echo "=============================================="
		echo ''

		sleep 5

		sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80
		
		if [ $? -ne 0 ]
		then
			sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
			sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
			sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
			sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://keyserver.ubuntu.com:80
			
			if [ $? -ne 0 ]
			then
				sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
				sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
				sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
				sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --no-validate
			fi
		fi
                
		sleep 5
                n=$((n+1))
                ContainerCreated=$(ConfirmContainerCreated)
        done
else
	n=1
	while [ $ContainerCreated -eq 0 ] && [ $n -le 5 ]
	do
		echo ''
		echo "=============================================="
		echo "   Create the LXC Oracle Linux container      "
		echo "                                              "
		echo "      Note: Depends on download speed         "
		echo "                                              "
		echo "                 Method 3                     "
		echo "=============================================="
		echo ''

		sleep 5

		if   [ $MajorRelease -le 7 ]
		then
			sudo lxc-create -n oel$OracleRelease$SeedPostfix -t oracle -- --release=$OracleVersion

		elif [ $MajorRelease -eq 8 ] #Because only image download is availalbe for Oracle Linux 8
		then
			sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80
			if [ $? -ne 0 ]
			then
				sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
				sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
				sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
				sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://keyserver.ubuntu.com:80

				if [ $? -ne 0 ]
				then
					sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
					sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
					sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
					sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --no-validate
				fi
			fi
		fi

		sleep 5
		n=$((n+1))
		ContainerCreated=$(ConfirmContainerCreated)
	done
fi

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
then
  	sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

echo ''
echo "=============================================="
echo "Create the LXC oracle container complete      "
echo "(Passwords are the same as the usernames)     "
echo "Sleeping 5 seconds...                         "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Extracting oracle-specific files to container."
echo "=============================================="
echo ''

cd /opt/olxc/"$DistDir"/orabuntu/archives

if [ $MajorRelease -ge 8 ]
then
	sudo tar -vP --extract --file=lxc-oracle-files.tar --directory /var/lib/lxc/oel$OracleRelease$SeedPostfix rootfs/etc/ntp.conf
	sudo tar -vP --extract --file=lxc-oracle-files.tar --directory /var/lib/lxc/oel$OracleRelease$SeedPostfix rootfs/etc/sysconfig/ntpd
fi

if [ $MajorRelease -eq 7 ] || [ $MajorRelease -eq 6 ]
then
	sudo tar -xvf /opt/olxc/"$DistDir"/orabuntu/archives/lxc-oracle-files.tar -C /var/lib/lxc/oel$OracleRelease$SeedPostfix --touch
	sudo chown root:root /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	sudo chmod 644 /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	sudo sed -i "s/HOSTNAME=ContainerName/HOSTNAME=oel$OracleRelease$SeedPostfix/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/network
	# sudo rm /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/ntp.conf

	if [ -n $Domain1 ]
	then
        	sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/orabuntu-lxc\.com/s/orabuntu-lxc\.com/$Domain1/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	fi

	if [ -n $Domain2 ]
	then
        	sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/NetworkManager/dnsmasq.d/local
		sudo sed -i "/consultingcommandos\.us/s/consultingcommandos\.us/$Domain2/g" /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/dhcp/dhclient.conf
	fi
fi

echo ''
echo "=============================================="
echo "Extraction container-specific files complete  "
echo "=============================================="

sleep 5

clear

if [ $MajorRelease -ge 6 ]
then
	echo ''
	echo "=============================================="
	echo "LXC config updates...                         "
	echo "=============================================="
	echo ''

	function GetNewMacAddress {
        	echo -n 00:16:3e; dd bs=1 count=3 if=/dev/random 2>/dev/null | hexdump -v -e '/1 ":%02x"'
        }
        NewMacAddress=$(GetNewMacAddress)

	sudo cp -p /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1 	/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
	sudo cp -p /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1 	/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

	sudo sh -c "echo 'lxc.net.0.mtu = $MultiHostVar7'											>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
	sudo sh -c "echo '# lxc.net.0.script.up = /etc/network/if-up.d/openvswitch/ContainerName-pub-ifup-sx1' 					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
	sudo sh -c "echo '# lxc.net.0.script.down = /etc/network/if-down.d/openvswitch/ContainerName-pub-ifdown-sx1' 				>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
	sudo sh -c "echo '# lxc.mount.entry = /dev/lxc_luns /var/lib/lxc/ContainerName/rootfs/dev/lxc_luns none defaults,bind,create=dir 0 0'	>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
	sudo sh -c "echo '# lxc.mount.entry = shm dev/shm tmpfs size=3500m,nosuid,nodev,noexec,create=dir 0 0'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
	sudo sed -i "s/ContainerName/oel$OracleRelease$SeedPostfix/g" 										   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
#	sudo sed -i 's/lxc\.net\.0\.link/\# lxc\.net\.0\.link/' 										   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config	
#	sudo sed -i 's/lxc\.net\.0\.link/\# lxc\.net\.0\.link/' 										   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
	sudo sed -i "/lxc\.net\.0\.link/s/virbr0/sx1a/g"											   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
	sudo sed -i "/lxc\.net\.0\.link/s/lxcbr0/sx1a/g"											   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
	sudo sed -i "s/\(hwaddr = \).*/\1$NewMacAddress/"               									   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

	sudo sed -i 's/sw1/sx1/g' 						/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
	sudo sed -i 's/tag=10/tag=11/g' 					/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
	sudo sed -i 's/sw1/sx1/g' 						/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1 

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
        then
                sudo lxc-update-config -c 				/var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        else
                sudo sed -i 's/lxc.net.0/lxc.network/g'                 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'                 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
		sudo sed -i "/lxc\.network\.link/s/virbr0/sx1a/g"   	/var/lib/lxc/oel$OracleRelease$SeedPostfix/config
		sudo sed -i "/lxc\.network\.link/s/lxcbr0/sx1a/g"   	/var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'              /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        fi


	echo ''
	echo "=============================================="
	echo "Done: LXC config updates.                     "
	echo "=============================================="
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Ping test  yum.oracle.com...                  "
echo "=============================================="
echo ''

ping -c 3 yum.oracle.com

function CheckNetworkUp {
	ping -c 3 yum.oracle.com | grep packet | cut -f3 -d',' | sed 's/ //g'
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
	echo "Ping yum.oracle.com not reliably pingable.    "
	echo "Script exiting.                               "
	echo "=============================================="
	exit
else
	echo ''
	echo "=============================================="
	echo "Ping yum.oracle.com reliable.                 "
	echo "=============================================="
	echo ''
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Set NTP '-x' option in ntpd file...           "
echo "=============================================="
echo ''

# sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /etc/sysconfig/ntpd
sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/ntpd

sleep 5

clear
	
echo ''
echo "=============================================="
echo "Done: Set NTP '-x' option in ntpd file.       "
echo "=============================================="

# fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Update config if LXC v2.0 or lower...          "
echo "=============================================="
echo ''

# Case 1 Creating Oracle Seed Container in 2.0- LXC enviro.

function CheckOracleSeedConfigFormat {
        sudo egrep -c 'lxc.net.0|lxc.net.1|lxc.uts.name|lxc.apparmor.profile' /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
}
OracleSeedConfigFormat=$(CheckOracleSeedConfigFormat)

if [ $(SoftwareVersion $LXCVersion) -lt $(SoftwareVersion 2.1.0) ] && [ $OracleSeedConfigFormat -gt 0 ]
then
        sudo sed -i 's/lxc.net.0/lxc.network/g'                 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo sed -i 's/lxc.net.1/lxc.network/g'                 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo sed -i 's/lxc.uts.name/lxc.utsname/g'              /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

# Case 2 Creating Oracle Seed Container in 2.1.0+ LXC enviro.

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
then
       sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

sudo lxc-ls -f

echo ''
echo "=============================================="
echo "Done: Update config if LXC v2.0 or lower.      "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "Initialize LXC Seed Container on OpenvSwitch.."
echo "=============================================="

cd /etc/network/if-up.d/openvswitch

function CheckContainerUp {
	sudo lxc-ls -f | grep oel$OracleRelease$SeedPostfix | sed 's/  */ /g' | egrep 'RUNNING|STOPPED'  | cut -f2 -d' '
}
ContainerUp=$(CheckContainerUp)

function CheckPublicIP {
	sudo lxc-ls -f | sed 's/  */ /g' | grep oel$OracleRelease$SeedPostfix | cut -f3 -d' ' | sed 's/,//' | cut -f1-3 -d'.' | sed 's/\.//g'
}
PublicIP=$(CheckPublicIP)

# GLS 20151217 Veth Pair Cleanups Scripts Create

sudo chown root:root /etc/network/openvswitch/veth_cleanups.sh
sudo chmod 755       /etc/network/openvswitch/veth_cleanups.sh

# GLS 20151217 Veth Pair Cleanups Scripts Create End

echo ''
echo "=============================================="
echo "Starting LXC Seed Container for Oracle        "
echo "=============================================="
echo ''

sleep 5

sudo sed -i 's/sw1/sx1/' 				/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i 's/sw1/sx1/' 				/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i 's/tag=10/tag=11/' 				/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix*
sudo sed -i 's/tag=10/tag=11/' 				/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix*

if [ $ContainerUp != 'RUNNING' ] || [ $PublicIP != 17229108 ]
then
	function CheckContainersExist {
	sudo ls /var/lib/lxc | grep -v $NameServer | grep oel$OracleRelease$SeedPostfix | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
	}
	ContainersExist=$(CheckContainersExist)
	sleep 5
	for j in $ContainersExist
	do
        	# GLS 20160707 updated to use lxc-copy instead of lxc-clone for Ubuntu 16.04
        	# GLS 20160707 continues to use lxc-clone for Ubuntu 15.04 and 15.10

		if [ $UbuntuMajorVersion -ge 16 ]
        	then
        		function CheckPublicIPIterative {
				sudo lxc-info -n oel$OracleRelease$SeedPostfix -iH | cut -f1-3 -d'.' | sed 's/\.//g' | head -1	
        		}
        	fi
		PublicIPIterative=$(CheckPublicIPIterative)
		echo "Starting container $j ..."
		echo ''
		sudo lxc-start  -n $j

		if [ $MajorRelease -eq 8 ]
		then 
			sudo lxc-attach -n $j -- sudo hostnamectl set-hostname oel$OracleRelease$SeedPostfix
			sudo lxc-stop   -n $j
			sudo lxc-start  -n $j
		fi

		i=1
		while [ "$PublicIPIterative" != 17229108 ] && [ "$i" -le 10 ]
		do
			echo "Waiting for $j Public IP to come up..."
			echo ''
			sleep 10
			PublicIPIterative=$(CheckPublicIPIterative)
			if [ $i -eq 5 ]
			then
			sudo lxc-stop -n $j > /dev/null 2>&1
			sudo /etc/network/openvswitch/veth_cleanups.sh oel$OracleRelease$SeedPostfix
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
echo "Public IP is up on oel$OracleRelease$SeedPostfix"
echo ''
sudo lxc-ls -f
echo ''
echo "=============================================="
echo "Container Up.                                 "
echo "=============================================="

sleep 10

clear

function CheckSearchDomain1 {
        grep -c $Domain1 /etc/resolv.conf
}
SearchDomain1=$(CheckSearchDomain1)

if [ $SearchDomain1 -eq 0 ] && [ $AWS -eq 0 ]
then
	if [ $UbuntuMajorVersion -eq 16 ]
	then
		sudo sed -i 's/\bsearch\b/& urdomain1.com urdomain2.com gns.urdomain1.com/' /run/resolvconf/resolv.conf
	else
		sudo sed -i 's/\bsearch\b/& urdomain1.com urdomain2.com gns.urdomain1.com/' /run/systemd/resolve/stub-resolv.conf
	fi

#       sudo sed -i '/search/d' /etc/resolv.conf
#       sudo sh -c "echo 'search $Domain1 $Domain2 gns1.$Domain1' >> /etc/resolv.conf"
fi

echo ''
echo "=============================================="
echo "Container oel$OracleRelease$SeedPostfix ping test..."
echo "=============================================="
echo ''

if [ $SystemdResolvedInstalled -eq 1 ]
then
	        sudo service systemd-resolved restart
fi

sleep 5

clear

echo ''
echo "=============================================="
echo "Testing connectivity ...                      "
echo "=============================================="
echo ''
echo "=============================================="
echo "Output of 'uname -a'                          "
echo "=============================================="
echo ''

sudo lxc-attach -n oel$OracleRelease$SeedPostfix -- uname -a

if [ $? -ne 0 ]
then
	echo ''
	echo "=============================================="
	echo "lxc-attach is failing...see if selinux is set."
	echo "Script exiting.                               "
	echo "=============================================="
	exit
fi

echo ''
echo "=============================================="
echo "Test lxc-attach successful.                   "
echo "=============================================="

sleep 5

clear

echo ''
echo "==============================================" 
echo "Next script to run: orabuntu-services-3.sh    "
echo "=============================================="

sleep 5
