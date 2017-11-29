function GetFacter {
	facter virtual
}
Facter=$(GetFacter)

function GetVirtualInterfaces {
	ifconfig | grep enp | cut -f1 -d':' | sed 's/$/ /' | tr -d '\n' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
VirtualInterfaces=$(GetVirtualInterfaces)
echo $VirtualInterfaces

MultiHost="new:Y:4:$SudoPassword:10.207.39.14:10.207.39.13:1500:ubuntu:ubuntu"

OnVm1=N
OnVm2=N

if [ $Facter != 'physical' ] # 6
then
	for i in $VirtualInterfaces
	do
		echo $i
		function CheckIpOnVirtualInterface1 {
			ifconfig $i | grep 10.207.39 | wc -l
		}
		IpOnVirtualInterface1=$(CheckIpOnVirtualInterface1)

		function CheckIpOnVirtualInterface2 {
			ifconfig $i | grep 10.207.29 | wc -l
		}
		IpOnVirtualInterface2=$(CheckIpOnVirtualInterface2)

		if [ $IpOnVirtualInterface1 -eq 1 ]
		then
			OnVm1=Y
		fi
		
		if [ $IpOnVirtualInterface2 -eq 1 ]
		then
			OnVm2=Y
		fi
	done
fi

MultiHost="$MultiHost:$OnVm1:$OnVm2"
echo $MultiHost


