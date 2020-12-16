DistDir="/home/ubuntu/Downloads/orabuntu-lxc-master"
MajorRelease=7
OracleRelease=73
SeedPostfix=c10

        sudo tar -xzPf $DistDir/orabuntu/archives/ora"$MajorRelease"xc00.tar.gz

        sudo mv /var/lib/lxc/ora"$MajorRelease"xc00                     /var/lib/lxc/oel$OracleRelease$SeedPostfix

        TempName=ora"$MajorRelease"xc00

        sudo sed -i "s/$TempName/oel$OracleRelease$SeedPostfix/g"       /var/lib/lxc/oel$OracleRelease$SeedPostfix/config

	sudo lxc-start    -n oel$OracleRelease$SeedPostfix
        sleep 5
	sudo lxc-attach   -n oel$OracleRelease$SeedPostfix -- hostnamectl set-hostname oel$OracleRelease$SeedPostfix
        sudo lxc-attach   -n oel$OracleRelease$SeedPostfix -- sed -i       "s/ora7xc00/oel$OracleRelease$SeedPostfix/g" /etc/hosts
        sudo lxc-attach   -n oel$OracleRelease$SeedPostfix -- sed -i       "s/ora7xc00/oel$OracleRelease$SeedPostfix/g" /etc/sysconfig/network
        sudo lxc-attach   -n oel$OracleRelease$SeedPostfix -- sed -i       "s/ora7xc00/oel$OracleRelease$SeedPostfix/g" /etc/sysconfig/network-scripts/ifcfg-eth0
        
	echo ''
        echo "=============================================="
        echo "Display Oracle /etc/hosts                  "
        echo "=============================================="
        echo ''

	sudo lxc-attach   -n oel$OracleRelease$SeedPostfix -- cat /etc/hosts 
	
	echo ''
        echo "=============================================="
        echo "Display Oracle /etc/sysconfig/network      "
        echo "=============================================="
        echo ''

	sudo lxc-attach   -n oel$OracleRelease$SeedPostfix -- cat /etc/sysconfig/network
	
        echo ''
        echo "=============================================="
        echo "Display Oracle default config ...             "
        echo "=============================================="
        echo ''

        sudo cat                                                        /var/lib/lxc/oel$OracleRelease$SeedPostfix/config
        sudo lxc-stop     -n oel$OracleRelease$SeedPostfix

        echo ''
        echo "=============================================="
        echo "Display LXC containers ...                    "
        echo "=============================================="
        echo ''

        sudo lxc-ls -f

        echo "=============================================="
