sudo apt-get -y update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu zesty stable"

sudo apt-get -y update
sudo apt-get -y install docker-ce

sudo docker run -d -p 2200:22 raesene/alpine-nettools
# sudo docker exec -ti zealous_stallman /bin/sh

function GetDockerName {
	sudo docker ps -a | grep raesene | sed 's/  */ /g' | rev | cut -f1 -d' ' | rev
}
DockerName=$(GetDockerName)
echo $DockerName

