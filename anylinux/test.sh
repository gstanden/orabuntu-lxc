LinuxFlavor=Red

function GetFwd1 {
        sudo find / -name firewalld.conf 2>/dev/null | wc -l
}
Fwd1=$(GetFwd1)

# Get FirewallBackend [ iptables | nftables ]

if [ $Fwd1 -gt 0 ]
then
        function GetFwdConfFilename {
                sudo find / -name firewalld.conf 2>/dev/null
        }
        FwdConfFilename=$(GetFwdConfFilename)

        function GetFwdBackend {
                sudo grep FirewallBackend $FwdConfFilename | grep FirewallBackend | grep -v '#' | cut -f2 -d'='
        }
        FwdBackend=$(GetFwdBackend)
fi

# Check if firewalld package is installed.

if [ $LinuxFlavor = 'Red' ] || [ $LinuxFlavor = 'CentOS' ] || [ $LinuxFlavor = 'Oracle' ] || [ $LinuxFlavor = 'Fedora' ]
then
        function GetFwd2 {
                sudo rpm -qa | grep -c firewalld
        }
elif [ $LinuxFlavor = 'Ubuntu' ]
then
        function GetFwd2 {
                sudo dpkg -l | grep -c firewalld
        }
fi
Fwd2=$(GetFwd2)

# Check if firewalld service is running.

function GetFwd3 {
        sudo firewall-cmd --state 2>/dev/null | grep -i 'running'
}
Fwd3=$(GetFwd3)

if [ $? -eq 0 ]
then
        function GetFirewalldBackend {
                sudo grep 'nftables' /etc/firewalld/firewalld.conf | grep FirewallBackend | grep -vc '#'
        }
        FirewalldBackend=$(GetFirewalldBackend)
else
        FirewalldBackend=0
fi

echo 'Fwd1 = '$Fwd1
echo 'Fwd2 = '$Fwd2
echo 'Fwd3 = '$Fwd3
