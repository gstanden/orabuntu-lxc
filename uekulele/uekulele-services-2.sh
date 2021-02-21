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

echo ''
echo "=============================================="
echo "uekulele-services-2.sh script                 "
echo "                                              "
echo "This script creates oracle container.         "
echo "=============================================="
echo ''

function GetGroup {
        id | cut -f2 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Group=$(GetGroup)

function GetOwner {
        id | cut -f1 -d' ' | cut -f2 -d'(' | cut -f1 -d')'
}
Owner=$(GetOwner)

function GetShortHost {
        uname -n | cut -f1 -d'.'
}
ShortHost=$(GetShortHost)

function SoftwareVersion { echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; }

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
MTU=$MultiHostVar7

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
        RedHatVersion=$(GetRedHatVersion)
        function GetOracleDistroRelease {
                sudo cat /etc/oracle-release | cut -f5 -d' ' | cut -f1 -d'.'
        }
        OracleDistroRelease=$(GetOracleDistroRelease)
        Release=$OracleDistroRelease
        LF=$LinuxFlavor
        RL=$Release
	SubDirName=uekulele
	UbuntuMajorVersion=0
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
	SubDirName=uekulele
	UbuntuMajorVersion=0
elif [ $LinuxFlavor = 'Fedora' ]
then
        CutIndex=3
        function GetRedHatVersion {
                sudo cat /etc/redhat-release | cut -f"$CutIndex" -d' ' | cut -f1 -d'.'
        }
        RedHatVersion=$(GetRedHatVersion)
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
	SubDirName=uekulele
	UbuntuMajorVersion=0
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
	SubDirName=orabuntu
        UbuntuMajorVersion=$(GetUbuntuMajorVersion)
	Release=0
fi

### GLS 20210107 ###

if   [ $MultiHostVar3 = 'X' ] && [ $GREValue = 'Y' ]
then
        SeedIndex=10
        SeedPostfix=c$SeedIndex

        function GetNameServerShortName {
                echo $NameServer | cut -f1 -d'-'
        }
        NameServerShortName=$(GetNameServerShortName)

	if [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 8 ]
	then
		function CheckDNSLookup {
			timeout 5 getent hosts oel$OracleRelease$SeedPostfix
		}
		DNSLookup=$(CheckDNSLookup)
		DNSLookup=`echo $?`
	else
		function CheckDNSLookup {
			timeout 5 nslookup oel$OracleRelease$SeedPostfix $NameServer
		}
		DNSLookup=$(CheckDNSLookup)
		DNSLookup=`echo $?`
	fi

        while [ $DNSLookup -eq 0 ]
        do
                SeedIndex=$((SeedIndex+1))
                SeedPostfix=c$SeedIndex
                DNSLookup=$(CheckDNSLookup)
                DNSLookup=`echo $?`
        done
        SeedPostfix=c$SeedIndex

elif [ $MultiHostVar3 -eq 1 ] && [ $GREValue = 'N' ]
then
        SeedIndex=10
        SeedPostfix=c$SeedIndex

	if [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 8 ]
	then
		function CheckHighestSeedIndexHit {
			timeout 5 getent hosts oel$OracleRelease$SeedPostfix
		}
		HighestSeedIndexHit=$(CheckHighestSeedIndexHit)
		HighestSeedIndexHit=`echo $?`
	else
		function CheckHighestSeedIndexHit {
			timeout 5 nslookup oel$OracleRelease$SeedPostfix
		}
		HighestSeedIndexHit=$(CheckHighestSeedIndexHit)
		HighestSeedIndexHit=`echo $?`
	fi

        while [ $HighestSeedIndexHit -eq 0 ]
        do
                SeedIndex=$((SeedIndex+1))
                SeedPostfix=c$SeedIndex
                HighestSeedIndexHit=$(CheckHighestSeedIndexHit)
                HighestSeedIndexHit=`echo $?`
        done
        SeedPostfix=c$SeedIndex
fi

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

if [ $LinuxFlavor = 'Fedora' ]
then
	echo ''
	echo "=============================================="
	echo "Install lxc-templates ($LinuxFlavor)...       "
	echo "=============================================="
	echo ''

	sudo yum -y install lxc-templates

	echo ''
	echo "=============================================="
	echo "Done: Install lxc-templates ($LinuxFlavor).   "
	echo "=============================================="

	sleep 5

	clear
fi

if [ $LinuxFlavor = 'CentOS' ]
then
	echo ''
	echo "=============================================="
	echo "Install lsb on CentOS 6 ...                   "
	echo "=============================================="
	echo ''

	sudo yum -y install lsb

	echo ''
	echo "=============================================="
	echo "Done: Install lsb on CentOS 6.                "
	echo "=============================================="

	sleep 5

	clear
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

function ConfirmContainerCreated {
        sudo lxc-ls -f | grep oel$OracleRelease$SeedPostfix | wc -l
}
ContainerCreated=$(ConfirmContainerCreated)

echo ''
echo "=============================================="
echo "   Create the LXC Oracle Linux container      "
echo "                                              "
echo "      Note: Depends on download speed         "
echo "=============================================="
echo ''

m=1
while [ $ContainerCreated -eq 0 ] && [ $m -le 3 ] && [ $Release -ge 7 ]
do
	echo "=============================================="
	echo "                 Method 1                     "
	echo "=============================================="
	echo ''

	dig +short us.images.linuxcontainers.org
	echo ''

	if [ -d /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease" ]
        then
                echo "Directory already exists: /opt/olxc/"$DistDir"/lxcimage/oracle$MajorRelease"
                sudo rm -f      /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"/*
        else
                sudo mkdir -p   /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"
                echo "Directory created: /opt/olxc/"$DistDir"/lxcimage/oracle$MajorRelease"
        fi

        sudo rm -f                      /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"/*
        sudo chown -R $Owner:$Group     /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"
        cd				/opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"

	wget -4 -q https://us.images.linuxcontainers.org/images/oracle/"$MajorRelease"/amd64/default/ -P /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"
	
	function GetBuildDate {
		grep folder.gif index.html | tail -1 | awk -F "\"" '{print $8}' | sed 's/\///g' | sed 's/\.//g'
	}
	BuildDate=$(GetBuildDate)

	wget -4 --no-verbose --progress=bar https://us.images.linuxcontainers.org/images/oracle/"$MajorRelease"/amd64/default/"$BuildDate"/SHA256SUMS -P /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"

	for i in rootfs.tar.xz meta.tar.xz
	do
		if [ -f /opt/olxc/$DistDir/lxcimage/oracle"$MajorRelease"/$i ]
		then
			rm -f /opt/olxc/$DistDir/lxcimage/oracle"$MajorRelease"/$i
		fi

		echo ''
		echo "Downloading $i ..."
		echo ''

		wget -4 --no-verbose --progress=bar https://us.images.linuxcontainers.org/images/oracle/"$MajorRelease"/amd64/default/"$BuildDate"/$i -P /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"
		diff <(shasum -a 256 /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"/$i | cut -f1,11 -d'/' | sed 's/  */ /g' | sed 's/\///' | sed 's/  */ /g') <(grep $i /opt/olxc/"$DistDir"/lxcimage/oracle"$MajorRelease"/SHA256SUMS)
	done
	if [ $? -eq 0 ]
	then
		echo ''
		sudo lxc-create -t local -n oel$OracleRelease$SeedPostfix -- -m /opt/olxc/$DistDir/lxcimage/oracle"$MajorRelease"/meta.tar.xz -f /opt/olxc/$DistDir/lxcimage/oracle"$MajorRelease"/rootfs.tar.xz

		if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
		then
  			sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
		fi
	fi

	ContainerCreated=$(ConfirmContainerCreated)
	rm -f index.html
	m=$((m+1))
done

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
then
	sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

n=1
while [ $ContainerCreated -eq 0 ] && [ $n -le 5 ]
do
	echo "=============================================="
	echo "                 Method 2                     "
	echo "=============================================="
	echo ''

	if   [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 8 ]
	then
		sudo lxc-create -n oel$OracleRelease$SeedPostfix --template download -- -d oracle -r $MajorRelease -a amd64
		if [ $? -ne 0 ]
		then
                       	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
                       	sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
                       	sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
                       	sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80

                       	if [ $? -ne 0 ]
                       	then
                               	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
                               	sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
                               	sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
                               	sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --no-validate
                       	fi
                fi

	elif [ $LinuxFlavor = 'Fedora' ] && [ $Release -eq 7 ]
	then
		sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://keyserver.ubuntu.com:80
		if [ $? -ne 0 ]
		then
                       	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
                       	sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
                       	sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
                       	sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80

                       	if [ $? -ne 0 ]
                       	then
                               	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
                               	sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
                               	sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
                              	sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --no-validate
                       	fi
                fi
	else
		sudo lxc-create -n oel$OracleRelease$SeedPostfix -t oracle -- --release=$OracleVersion
		if [ $? -ne 0 ]
		then
			if [ $? -ne 0 ]
                	then
                        	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
                        	sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
                        	sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
                        	sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --keyserver hkp://p80.pool.sks-keyservers.net:80
                        	if [ $? -ne 0 ]
                        	then
                                	sudo lxc-stop -n oel$OracleRelease$SeedPostfix -k
                                	sudo lxc-destroy -n oel$OracleRelease$SeedPostfix
                                	sudo rm -rf /var/lib/lxc/oel$OracleRelease$SeedPostfix
                                	sudo lxc-create -t download -n oel$OracleRelease$SeedPostfix -- --dist oracle --release $MajorRelease --arch amd64 --no-validate
                        	fi
                	fi
		fi
	fi

	sleep 5
       	n=$((n+1))
       	ContainerCreated=$(ConfirmContainerCreated)
done

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

if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
then
  	sudo lxc-update-config -c /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
fi

echo ''
echo "=============================================="
echo "Extracting oracle-specific files to container."
echo "=============================================="
echo ''

cd /opt/olxc/"$DistDir"/uekulele/archives

if [ $MajorRelease -ge 8 ]
then
	sudo tar -vP --extract --file=lxc-oracle-files.tar --directory /var/lib/lxc/oel$OracleRelease$SeedPostfix rootfs/etc/ntp.conf
	sudo tar -vP --extract --file=lxc-oracle-files.tar --directory /var/lib/lxc/oel$OracleRelease$SeedPostfix rootfs/etc/sysconfig/ntpd
fi

if [ $MajorRelease -eq 7 ] || [ $MajorRelease -eq 6 ]
then
	sudo tar -xvf /opt/olxc/"$DistDir"/"$SubDirName"/archives/lxc-oracle-files.tar -C /var/lib/lxc/oel$OracleRelease$SeedPostfix --touch
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

### new ###

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

        sudo cp -p /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1       /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
        sudo cp -p /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1   /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

        sudo sh -c "echo 'lxc.net.0.mtu = $MultiHostVar7'                                                                                       >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
        sudo sh -c "echo '# lxc.net.0.script.up = /etc/network/if-up.d/openvswitch/ContainerName-pub-ifup-sx1'                                  >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
        sudo sh -c "echo '# lxc.net.0.script.down = /etc/network/if-down.d/openvswitch/ContainerName-pub-ifdown-sx1'                            >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
        sudo sh -c "echo '# lxc.mount.entry = /dev/lxc_luns /var/lib/lxc/ContainerName/rootfs/dev/lxc_luns none defaults,bind,create=dir 0 0'   >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
        sudo sh -c "echo '# lxc.mount.entry = shm dev/shm tmpfs size=3500m,nosuid,nodev,noexec,create=dir 0 0'                                  >> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
        sudo sed -i "s/ContainerName/oel$OracleRelease$SeedPostfix/g"                                                                              /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
#       sudo sed -i 's/lxc\.net\.0\.link/\# lxc\.net\.0\.link/'                                                                                    /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
#       sudo sed -i 's/lxc\.net\.0\.link/\# lxc\.net\.0\.link/'                                                                                    /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo sed -i "/lxc\.net\.0\.link/s/virbr0/sx1a/g"                                                                                           /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo sed -i "/lxc\.net\.0\.link/s/lxcbr0/sx1a/g"                                                                                           /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo sed -i "s/\(hwaddr = \).*/\1$NewMacAddress/"                                                                                          /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

        sudo sed -i 's/sw1/sx1/g'                                               /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
        sudo sed -i 's/tag=10/tag=11/g'                                         /etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
        sudo sed -i 's/sw1/sx1/g'                                               /etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

        if [ $(SoftwareVersion $LXCVersion) -ge $(SoftwareVersion "2.1.0") ]
        then
                sudo lxc-update-config -c                               /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        else
                sudo sed -i 's/lxc.net.0/lxc.network/g'                 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i 's/lxc.net.1/lxc.network/g'                 /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i "/lxc\.network\.link/s/virbr0/sx1a/g"       /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i "/lxc\.network\.link/s/lxcbr0/sx1a/g"       /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i 's/lxc.uts.name/lxc.utsname/g'              /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
                sudo sed -i 's/lxc.apparmor.profile/lxc.aa_profile/g'   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        fi

	sudo cat /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

        echo ''
        echo "=============================================="
        echo "Done: LXC config updates.                     "
        echo "=============================================="
fi

### new end ###

# if [ $MajorRelease -ge 6 ]
# then
# 	echo ''
# 	echo "=============================================="
# 	echo "LXC config updates...                         "
# 	echo "=============================================="
# 	echo ''

# 	function GetNewMacAddress {
#        	echo -n 00:16:3e; dd bs=1 count=3 if=/dev/random 2>/dev/null | hexdump -v -e '/1 ":%02x"'
#       }
#       NewMacAddress=$(GetNewMacAddress)

# 	sudo cp -p /etc/network/if-up.d/openvswitch/lxcora00-pub-ifup-sw1 	/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
# 	sudo cp -p /etc/network/if-down.d/openvswitch/lxcora00-pub-ifdown-sw1 	/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

# 	sudo sh -c "echo 'lxc.net.0.mtu = $MultiHostVar7'											>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
# 	sudo sh -c "echo 'lxc.net.0.script.up = /etc/network/if-up.d/openvswitch/ContainerName-pub-ifup-sx1' 					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
# 	sudo sh -c "echo 'lxc.net.0.script.down = /etc/network/if-down.d/openvswitch/ContainerName-pub-ifdown-sx1' 				>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
# 	sudo sh -c "echo '# lxc.mount.entry = /dev/lxc_luns /var/lib/lxc/ContainerName/rootfs/dev/lxc_luns none defaults,bind,create=dir 0 0'	>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
# 	sudo sh -c "echo '# lxc.mount.entry = shm dev/shm tmpfs size=3500m,nosuid,nodev,noexec,create=dir 0 0'					>> /var/lib/lxc/oel$OracleRelease$SeedPostfix/config"
# 	sudo sed -i "s/ContainerName/oel$OracleRelease$SeedPostfix/g" 										   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

# 	if   [ $Release -ge 7 ]
# 	then
# 		sudo sed -i 's/lxc\.net\.0\.link/\# lxc\.net\.0\.link/' 									   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
# 
# 	elif [ $Release -eq 6 ]
# 	then
# 		sudo sed -i 's/lxc\.network\.link/\# lxc\.network\.link/' 									   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
# 	fi

# 	sudo sed -i "s/\(hwaddr = \).*/\1$NewMacAddress/"               									   /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

# 	sudo sed -i 's/sw1/sx1/g' 						/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
# 	sudo sed -i 's/tag=10/tag=11/g' 					/etc/network/if-up.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifup-sx1
# 	sudo sed -i 's/sw1/sx1/g' 						/etc/network/if-down.d/openvswitch/oel$OracleRelease$SeedPostfix-pub-ifdown-sx1

# 	sudo cat /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

# 	sleep 5

# 	echo ''
# 	echo "=============================================="
# 	echo "Done: LXC config updates.                     "
# 	echo "=============================================="
# fi

sleep 5

clear

# echo ''
# echo "=============================================="
# echo "Set NTP '-x' option in ntpd file...           "
# echo "=============================================="
# echo ''

# sudo sed -i -e '/OPTIONS/{ s/.*/OPTIONS="-g -x"/ }' /var/lib/lxc/oel$OracleRelease$SeedPostfix/rootfs/etc/sysconfig/ntpd

# echo ''
# echo "=============================================="
# echo "Done: Set NTP '-x' option in ntpd file.       "
# echo "=============================================="

# sleep 5

# clear

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

function CheckPublicIPIterative {
	sudo lxc-info -n oel$OracleRelease$SeedPostfix -iH | cut -f1-3 -d'.' | sed 's/\.//g' | head -1
}

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
		PublicIPIterative=$(CheckPublicIPIterative)
		echo "Starting container $j ..."
		echo ''
		sudo lxc-start  -n $j
		sleep 5

		if [ $MajorRelease -ge 7 ] && [ $Release -ge 7 ]
		then 
			sudo lxc-attach -n $j -- hostnamectl set-hostname $j
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
echo "==============================================" 
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
echo "Testing connectivity ...                      "
echo "=============================================="
echo ''
echo "=============================================="
echo "Output of 'uname -a'                          "
echo "=============================================="
echo ''

sudo lxc-attach -n oel$OracleRelease$SeedPostfix -- uname -a

echo ''
echo "=============================================="
echo "Test lxc-attach successful.                   "
echo "=============================================="

sleep 5

clear

echo ''
echo "==============================================" 
echo "Next script to run: uekulele-services-3.sh    "
echo "=============================================="

sleep 5
