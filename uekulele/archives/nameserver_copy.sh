#!/bin/bash

MultiHostVar5=$1
MultiHostVar6=$2
NameServer=$3

# function CheckSystemdResolvedInstalled {
# 	sudo netstat -ulnp | grep 53 | sed 's/  */ /g' | rev | cut -f1 -d'/' | rev | sort -u | grep systemd- | wc -l
# }
# SystemdResolvedInstalled=$(CheckSystemdResolvedInstalled)

sudo rm ~/Manage-Orabuntu/$NameServer.tar.gz

echo ''
echo "=============================================="
echo "Copy nameserver container $NameServer...      "
echo "=============================================="
echo ''

sshpass -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p ubuntu@$MultiHostVar5:~/Manage-Orabuntu/$NameServer.tar.gz ~/Manage-Orabuntu/.

sudo lxc-copy    -n ns-"$HOSTNAME" -N ns-"$HOSTNAME"-bak
sudo lxc-destroy -n ns-"$HOSTNAME"

sudo tar -xzvPf ~/Manage-Orabuntu/$NameServer.tar.gz

sudo lxc-copy    -n olive -N ns-"$HOSTNAME"

echo ''
echo "=============================================="
echo "Done: Copy nameserver container $NameServer.  "
echo "=============================================="
echo ''

sleep 5

clear

echo ''
echo "=============================================="
echo "LXC containers for Oracle Status...           "
echo "=============================================="
echo ''

sudo lxc-ls -f

echo ''
echo "=============================================="

# if [ $SystemdResolvedInstalled -ge 1 ]
# then
# 	sudo service systemd-resolved restart
# fi

# sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" lxc-stop -n $NameServer"
# sudo lxc-start -n $NameServer
# sleep 5
# nslookup $NameServer
# nslookup yum.oracle.com
# ping -c 3 $NameServer
# ping -c 3 yum.oracle.com

