#    Copyright 2015-2017 Gilbert Standen
#    This file is part of orabuntu-lxc.

#    Orabuntu-lxc is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    Orabuntu-lxc is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with orabuntu-lxc.  If not, see <http://www.gnu.org/licenses/>.

#    v2.8 GLS 20151231
#    v3.0 GLS 20160710 Updates for Ubuntu 16.04
#    v4.0 GLS 20161025 DNS DHCP services moved into an LXC container

#!/bin/bash

clear

# Controlling script for cloning MORE containers from an already-existing OEL seed container.
# Gilbert Standen 20151224 gilstanden@hotmail.com

# Usage:

# ~/Downloads/orabuntu-lxc-master/ubuntu-clone.sh MajorRelease MinorRelease NumCon

# Example explanation:

# Create containers with Oracle Enterprise Linux 6.7 OS version.
# Create four clones of the seed (oel67) container.  The clones will be named {ora67cxx} where xx is the n+1th index after the current largest container index.
# Example: The OEL 6.7 containers shown below already exist on the system:
# NAME      STATE    IPV4                                                                                                          IPV6  GROUPS  AUTOSTART  
# --------------------------------------------------------------------------------------------------------------------------------------------------------
# oel67     RUNNING  10.207.29.10                                                                                                  -     -       NO         
# ora67c10  RUNNING  10.207.39.10, 172.230.40.10, 172.231.40.10, 192.220.39.10, 192.221.39.10, 192.222.39.10, 192.223.39.10        -     -       NO         
# ora67c11  RUNNING  10.207.39.11, 172.230.40.11, 172.231.40.11, 192.220.39.11, 192.221.39.11, 192.222.39.11, 192.223.39.11        -     -       NO         
# ora67c12  RUNNING  10.207.39.12, 172.230.40.12, 172.231.40.12, 192.220.39.12, 192.221.39.12, 192.222.39.12, 192.223.39.12        -     -       NO         
# ora67c13  RUNNING  10.207.39.13, 172.230.40.13, 172.231.40.13, 192.220.39.13, 192.221.39.13, 192.222.39.13, 192.223.39.13        -     -       NO         

# Running the command:
# ~/Downloads/orabuntu-lxc-master/ubuntu-clone.sh 6 7 4
# will result in the following containers being created: {ora67c14,ora67c15,ora67c16,ora67c17}

# Oracle Enteprise Linux OS versions OEL5, OEL6, and OEL7 are currently supported.

clear
~/Downloads/orabuntu-lxc-master/anylinux-services-4.sh $1 $2 $3 ora$1$2c
clear
~/Downloads/orabuntu-lxc-master/anylinux-services-5.sh $1 $2

