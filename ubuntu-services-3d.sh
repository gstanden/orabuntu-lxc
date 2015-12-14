#!/bin/bash

echo ''
echo "============================================"
echo "Script: ubuntu-services-3d.sh              "
echo "============================================"
echo ''
echo "============================================"
echo "This script is re-runnable.                 "
echo "============================================"
echo ''
echo "============================================"
echo "This script starts lxc clones "
echo "============================================"

sudo lxc-start -n lxcora0 >/dev/null 2>&1

sleep 10

clear

echo ''
echo "============================================"
echo "Testing passwordless-ssh for root user      "
echo "============================================"
echo "Output of 'uname -a' in lxcora0..."
echo "============================================"
echo ''

sshpass -p root ssh -o CheckHostIP=no -o StrictHostKeyChecking=no root@lxcora0 uname -a
if [ $? -ne 0 ]
then
echo ''
echo "============================================"
echo "No-password ssh to lxcora0 has issue(s).    "
echo "No-password ssh to lxcora0 must succeed.    "
echo "Fix issues retry script.                    "
echo "Script exiting.                             "
echo "============================================"
exit
fi
echo ''
echo "============================================"
echo "No-password ssh test to lxcora0 successful. "
echo "============================================"

sleep 5

clear

echo ''
echo "============================================"
echo "Check directory is ~/Networking             "
echo "Verify crt_links.sh exists and has 755 mode "
echo "Step creates pointers to relevant files.    "
echo "Use links to quickly locate relevant files. "
echo "============================================"
echo ''

if [ ! -e ~/Networking ]
then
mkdir ~/Networking
fi
 
sudo cp -p ~/Downloads/orabuntu-lxc-master/crt_links_v2.sh  ~/Networking/crt_links.sh
sudo chown root:root ~/Networking/crt_links.sh

cd ~/Networking

# ls -l crt_links.sh

sudo ./crt_links.sh
echo ''
ls -l ~/Networking
echo ''
cd ~/Downloads/orabuntu-lxc-master

echo ''
echo "============================================"
echo "Management links directory created.         "
echo "============================================"

sleep 10

clear

echo ''
echo "==========================================="
echo "Starting LXC clone containers for Oracle   "
echo "==========================================="
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

echo ''
echo "==========================================="
echo "LXC clone containers for Oracle started.   "
echo "==========================================="
echo ''
echo "==========================================="
echo "Waiting for final container initialization." 
echo "==========================================="

sleep 5

clear

echo ''
echo "==========================================="
echo "LXC containers for Oracle started.         "
echo "==========================================="
echo ''

sudo lxc-ls -f

echo ''
echo "==========================================="
echo "Stopping the containers in 10 seconds      "
echo "Next step is to setup storage...           "
echo "tar -xvf scst-files.tar                    "
echo "cd scst-files                              "
echo "cat README                                 "
echo "follow the instructions in the README      "
echo "Builds the SCST Linux SAN.                 "
echo "                                           "
echo "Note that deployment management links are  "
echo "in ~/Networking to learn more about what   "
echo "files and configurations are used for the  "
echo "orabuntu-lxc project.                      "
echo "==========================================="

sudo lxc-stop -n lxcora0

~/Downloads/orabuntu-lxc-master/stop_containers.sh

