#!/bin/bash

clear

MultiHostVar5=$1
MultiHostVar6=$2
NameServer=$3

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

function CheckScpProgress {
	ps -ef | grep sshpass | grep scp | grep -v grep | wc -l
}

sshpass -p ubuntu ssh -tt -o CheckHostIP=no -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" echo '(Do NOT type a password...backup will start in a moment)'; sudo -S <<< "ubuntu" tar -P -czf ~/Manage-Orabuntu/$NameServer.tar.gz -T ~/Downloads/orabuntu-lxc-master/uekulele/archives/nameserver.lst --checkpoint=10000 --totals"
sleep 5
rsync -hP --rsh="sshpass -p ubuntu ssh -l ubuntu" $MultiHostVar5:~/Manage-Orabuntu/$NameServer.tar.gz ~/Manage-Orabuntu/.

# echo ''
# ScpProgress=$(CheckScpProgress)
# while [ $ScpProgress -gt 0 ]
# do
# 	sleep 2
# 	ls -lh ~/Manage-Orabuntu/olive.tar.gz
# 	ScpProgress=$(CheckScpProgress)
# done

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

