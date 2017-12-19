#!/bin/bash

MultiHostVar5=$1
MultiHostVar6=$2
NameServer=$3

sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" lxc-stop -n $NameServer"
sleep 5
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" tar -cvzPf $NameServer.tar.gz -T /home/ubuntu/Downloads/orabuntu-lxc-master/uekulele/archives/nameserver.lst"
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" chown ubuntu:ubuntu $NameServer.tar.gz"
sshpass -v -p ubuntu scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p ubuntu@$MultiHostVar5:~/$NameServer.tar.gz ~/.
sudo tar -xzvf ~/$NameServer.tar.gz -C /
sleep 5
sudo lxc-start -n $NameServer
sleep 5
sudo chmod 644 /etc/systemd/system/$NameServer.service
sleep 5
sudo service systemd-resolved restart
sleep 5
nslookup $NameServer
nslookup yum.oracle.com
ping -c 3 $NameServer
ping -c 3 yum.oracle.com
sudo lxc-stop -n $NameServer
sleep 5
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" lxc-start -n $NameServer"
sleep 5
sshpass -v -p ubuntu ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no ubuntu@$MultiHostVar5 "sudo -S <<< "ubuntu" sudo service systemd-resolved restart"
sleep 5
nslookup $NameServer
nslookup yum.oracle.com
ping -c 3 $NameServer
ping -c 3 yum.oracle.com

