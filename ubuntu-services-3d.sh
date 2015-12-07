#!/bin/bash

echo ''
echo "============================================"
echo "Script: ubuntu-services-3d.sh              "
echo "============================================"

echo "============================================"
echo "This script is re-runnable.                 "
echo "============================================"

echo "============================================"
echo "This script starts lxc clones "
echo "============================================"

sudo lxc-start -n lxcora0 >/dev/null 2>&1

sleep 10

clear

echo ''
echo "============================================"
echo "Verify no-password ssh...                   "
echo "============================================"
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a 

echo ''
echo "==========================================="
echo "Verification of no-password ssh completed. "
echo "==========================================="

# sleep 5

# clear

# echo ''
# echo "==========================================="
# echo "Stopping lxcora0 container...             "
# echo "==========================================="
# echo ''
# sudo lxc-stop -n lxcora0

# while [ "$ContainerUp" = 'RUNNING' ]
# do
# sleep 1
# sudo lxc-ls -f
# ContainerUp=$(CheckContainerUp)
# echo ''
# echo $ContainerUp
# done
# echo ''
# echo "==========================================="
# echo "Container stopped.                         "
# echo "==========================================="
 
sleep 5

clear

if [ ! -e ~/Networking ]
then
mkdir ~/Networking
fi
 
sudo cp -p ~/Downloads/orabuntu-lxc-master/crt_links_v2.sh  ~/Networking/crt_links.sh
sudo chown root:root ~/Networking/crt_links.sh

cd ~/Networking

sleep 5
echo ''
echo "================================================"
echo "Check directory is ~/Networking                 "
echo "Verify crt_links.sh exists and has 755 mode     "
echo "This step creates pointers to relevant files.   "
echo "Use links to quickly locate relevant files.     "
echo "================================================"
echo ''
ls -l crt_links.sh
echo ''

sleep 5
 
sudo ./crt_links.sh
echo ''
ls -l ~/Networking
echo ''
cd ~/Downloads/orabuntu-lxc-master
pwd
sleep 5

clear

echo ''
echo "================================================"
echo "Starting LXC clone containers for Oracle        "
echo "================================================"
echo ''

function CheckClonedContainersExist {
sudo ls /var/lib/lxc | sort -V | sed 's/$/ /' | tr -d '\n' | sed 's/lxcora0 //' | sed 's/lxcora00 //' | sed 's/lxcora01 //'
}
ClonedContainersExist=$(CheckClonedContainersExist)

for j in $ClonedContainersExist
do
echo "Starting container $j ..."
# echo $j
# echo "next command will be:   sudo lxc-start -n $j"
echo ''
sudo lxc-start -n $j
sleep 20
sudo lxc-ls -f | grep lxcora$j
done

sudo lxc-stop -n lxcora0

clear

echo ''
echo "================================================"
echo "Waiting for final container initialization...   " 
echo "================================================"
echo "================================================"
echo "LXC containers for Oracle started.              "
echo "================================================"

sudo lxc-ls -f

echo "================================================"
echo "Stopping the containers in 10 seconds           "
echo "Next step is to setup storage...                "
echo "tar -xvf scst-files.tar                         "
echo "cd scst-files                                   "
echo "cat README                                      "
echo "follow the instructions in the README           "
echo "Builds the SCST Linux SAN.                      "
echo "================================================"

sleep 5

~/Downloads/orabuntu-lxc-master/stop_containers.sh

