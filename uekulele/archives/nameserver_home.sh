#!/bin/bash

MultiHostVar5=$1
MultiHostVar6=$2
NameServer=$3

sudo lxc-stop -n olive
sudo tar -cvzPf ~/Manage-Orabuntu/$NameServer.tar.gz -T /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/nameserver.lst
cd ~/Downloads/orabuntu-lxc-master/uekulele/archives
sshpass -v -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p ~/Manage-Orabuntu/$NameServer.tar.gz ubuntu@$MultiHostVar5:~/Manage-Orabuntu/.
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" lxc-stop -n $NameServer"
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" lxc-destroy -n $NameServer"
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" tar -xzvPf ~/Manage-Orabuntu/$NameServer.tar.gz"
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" lxc-start -n $NameServer"
 
