#!/bin/bash

function GetContainersRunning {
sudo lxc-ls -f | grep RUNNING | sed 's/  */ /g' | cut -f1 -d' ' | sed 's/$/ /' | tr -d '\n'
}
ContainersRunning=$(GetContainersRunning)

for i in $ContainersRunning
do
sudo lxc-stop -n $i
done
