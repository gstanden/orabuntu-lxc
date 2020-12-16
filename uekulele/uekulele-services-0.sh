#!/bin/bash

#    Copyright 2015-2019 Gilbert Standen
#    This file is part of Orabuntu-LXC.

#    Orabuntu-LXC is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-LXC is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with Orabuntu-LXC.  If not, see <http://www.gnu.org/licenses/>.

#    v2.4 		GLS 20151224
#    v2.8 		GLS 20151231
#    v3.0 		GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 		GLS 20161025 DNS DHCP services moved into an LXC container
#    v5.0 		GLS 20170909 Orabuntu-LXC Multi-Host
#    v6.0-AMIDE-beta	GLS 20180106 Orabuntu-LXC AmazonS3 Multi-Host Docker Enterprise Edition (AMIDE)

#    Note that this software builds a containerized DNS DHCP solution (bind9 / isc-dhcp-server).
#    The nameserver should NOT be the name of an EXISTING nameserver but an arbitrary name because this software is CREATING a new LXC-containerized nameserver.
#    The domain names can be arbitrary fictional names or they can be a domain that you actually own and operate.
#    There are two domains and two networks because the "seed" LXC containers are on a separate network from the production LXC containers.
#    If the domain is an actual domain, you will need to change the subnet using the subnets feature of Orabuntu-LXC
#
#    You can change the name of the username in this script from 'ubuntu' to whatever username is preferred.

genpasswd() {
        local l=$1
        [ "$l" == "" ] && l=8
        tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}
password=$(genpasswd)
mkdir -p ../installs/logs
echo $password > ../installs/logs/orabuntu-password.txt

USERNAME=orabuntu
PASSWORD=orabuntu
# PASSWORD=$password

sudo groupadd -g 1000 orabuntu
sudo useradd -g orabuntu -u 1000 -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash -G wheel ${USERNAME}
sudo mkdir -p  /home/${USERNAME}/Downloads /home/${USERNAME}/Manage-Orabuntu
sudo chown ${USERNAME}:${USERNAME} /home/${USERNAME}/Downloads /home/${USERNAME}/Manage-Orabuntu
