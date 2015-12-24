OracleRelease=$1$2
OracleVersion=$1.$2
Domain=$3
NameServer=$4

sudo service isc-dhcp-server start

sleep 5

function GetDHCPStatus {
sudo service isc-dhcp-server status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
DHCPStatus=$(GetDHCPStatus)

if [ $DHCPStatus != 'Active:active(running)' ]
then
	echo ''
	echo "DHCP is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ...                             "
	echo "============================================"
	echo ''
	sudo service isc-dhcp-server status
	echo ''
	echo "============================================"
	echo "DHCP status incorrect.                      "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with DHCP and retry script.  "
	echo "============================================"
	echo ''
else
	echo ''
	echo "DHCP is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "DHCP status ... (ignore PID message)        "
	echo "============================================"
	echo ''
	sudo service isc-dhcp-server status
	echo ''
	echo "============================================"
	echo "DHCP status complete.                       "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
fi

echo ''
echo "============================================="
echo "Status check of DHCP completed.              "
echo "============================================="
echo ''

# GLS 20151128 New DHCP status check end.

sleep 5

clear

# GLS 20151127 New bind9 server checks.  Terminates script if bind9 status is invalid.

echo ''
echo "============================================="
echo "Starting and checking status of bind9...     "
echo "============================================="

sudo service bind9 start

sleep 5

function GetNamedStatus {
sudo service bind9 status | grep Active | cut -f1-6 -d' ' | sed 's/ *//g'
}
NamedStatus=$(GetNamedStatus)

if [ $NamedStatus != 'Active:active(running)' ]
then
	echo ''
	echo "bind9 is NOT RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "bind9 status ...                             "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "bind9 status incorrect.                      "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "!! FIX PROBLEM with bind9 and retry script.  "
	echo "============================================"
	echo ''
else
	echo ''
	echo "bind9 is RUNNING with correct status of:  Active: active (running)"
	echo ''
	echo "============================================"
	echo "bind9 status ...                             "
	echo "============================================"
	echo ''
	sudo service bind9 status
	echo ''
	echo "============================================"
	echo "bind9 status complete.                       "
	echo "============================================"
	sleep 5
	echo ''
	echo "============================================"
	echo "Continuing with script execution.           "
	echo "============================================"
	echo ''
fi

echo "============================================"
echo "Status check of bind9 completed.            "
echo "============================================"
echo ''

# GLS 20151128 New bind9 status check end.

sleep 5

clear

if [ ! -e /etc/orabuntu-release ] || [ ! -e /etc/network/if-up.d/lxcora00-pub-ifup-sw1 ] || [ ! -e /etc/network/if-down.d/lxcora00-pub-ifdown-sw1 ]
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

	sudo useradd -u 1098 grid >/dev/null 2>&1
	sudo useradd -u 500 oracle >/dev/null 2>&1
fi

echo ''
echo "============================================"
echo "Check existence of Oracle and Grid users... "
echo "============================================"
echo ''

id grid
id oracle

echo ''
echo "============================================"
echo "Oracle and Grid users displayed.            "
echo "============================================"

sudo touch /etc/orabuntu-release

sleep 5

clear

echo ''
echo "=============================================="
echo "Create the LXC oracle container...            "
echo "=============================================="
echo ''

# Examples of setting the Oracle Enterprise Linux version

sudo lxc-create -n oel$OracleRelease -t oracle -- --release=$OracleVersion

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
echo "============================================"
echo "Next script to run: ubuntu-services-2.sh    "
echo "============================================"


