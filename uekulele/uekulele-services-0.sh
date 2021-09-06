#!/bin/bash

#    Copyright 2015-2021 Gilbert Standen
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
#
#    The name of the OrabuntuAccount username in this script can be changed from 'orabuntu' to whatever username is preferred.
#    Use of this script is optional.  An existing user account with 'sudo all' and 'wheel' group can also be used (but CANNOT use 'root' account). 
#    Note that the password is set same as the username.  If you want to use the genpassword utility for a secure password uncomment the line #PASSWORD=$password

OrabuntuAccount=orabuntu
OA=$OrabuntuAccount

genpasswd() {
        local l=$1
        [ "$l" == "" ] && l=8
        tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}
password=$(genpasswd)
mkdir -p ../installs/logs
echo $password > ../installs/logs/ubuntu-password.txt

USERNAME=$OA
PASSWORD=$OA
# PASSWORD=$password

sudo groupadd -g 1000 $OA
sudo useradd -g $OA -u 1000 -m -p $(openssl passwd -1 ${PASSWORD}) -s /bin/bash -G wheel ${USERNAME}
sudo mkdir -p  /home/${USERNAME}/Downloads /home/${USERNAME}/Manage-Orabuntu
sudo chown ${USERNAME}:${USERNAME} /home/${USERNAME}/Downloads /home/${USERNAME}/Manage-Orabuntu
sudo sh -c "echo '${USERNAME} ALL=(ALL) ALL' > /etc/sudoers.d/${USERNAME}"

