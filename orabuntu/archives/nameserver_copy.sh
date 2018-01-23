#!/bin/bash

clear

MultiHostVar5=$1
MultiHostVar6=$2
MultiHostVar8=$3
MultiHostVar9=$4
NameServer=$5

function CheckSystemdResolvedInstalled {
	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
}
SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

function CheckLxcNetInstalled {
	systemctl | grep -c lxc-net
}
LxcNetInstalled=$(CheckLxcNetInstalled)

echo ''
echo "=============================================="
echo "Copy nameserver $NameServer...                "
echo "=============================================="
echo ''

sshpass -p $MultiHostVar9 ssh -tt -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" echo '(Do NOT type a password...backup will start in a moment)'; sudo -S <<< "$MultiHostVar9" tar -P -czf ~/Manage-Orabuntu/$NameServer.tar.gz -T nameserver.lst --checkpoint=10000 --totals"
sleep 5
rsync -hP --rsh="sshpass -p $MultiHostVar9 ssh -l $MultiHostVar8" $MultiHostVar5:~/Manage-Orabuntu/$NameServer.tar.gz ~/Manage-Orabuntu/.

echo ''
echo "=============================================="
echo "Destroy nameserver $NameServer...             "
echo "=============================================="
echo ''
sudo lxc-stop    -n $NameServer
sudo lxc-destroy -n $NameServer
echo ''
echo "=============================================="
echo "Unpack tar file...                            "
echo "=============================================="
echo ''
sudo tar -P -xzf ~/Manage-Orabuntu/$NameServer.tar.gz --checkpoint=10000 --totals
echo ''
echo "=============================================="
echo "Done: Copy nameserver container $NameServer.  "
echo "=============================================="
echo ''
echo "=============================================="
echo "LXC containers for Oracle Status...           "
echo "=============================================="
echo ''

sudo lxc-ls -f

echo ''
echo "=============================================="

if [ $SystemdResolvedInstalled -ge 1 ]
then
	sudo service systemd-resolved restart
fi

if [ $LxcNetInstalled -ge 1 ]
then
	sudo service lxc-net restart > /dev/null 2>&1
fi

