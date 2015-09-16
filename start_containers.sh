#!/bin/bash

function GetStoppedContainers {
sudo lxc-ls -f | egrep -v 'lxcora0|lxcora00i|NAME|---' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n'
}
StoppedContainers=$(GetStoppedContainers)

for i in $StoppedContainers
do
sudo lxc-start -n $i
sleep 5
sudo  lxc-stop -n $i
sleep 5
sudo lxc-start -n $i
sleep 10
done
