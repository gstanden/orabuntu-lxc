#!/bin/bash

sudo yum-config-manager --enable ol7_addons
sudo yum -y install docker-engine
sudo systemctl enable docker
sudo service docker start

sudo docker run -d -p 2200:22 raesene/alpine-nettools
# sudo docker exec -ti zealous_stallman /bin/sh

function GetDockerName {
	sudo docker ps -a | grep raesene | sed 's/  */ /g' | rev | cut -f1 -d' ' | rev
}
DockerName=$(GetDockerName)
echo $DockerName
echo ''
sudo docker ps -a

