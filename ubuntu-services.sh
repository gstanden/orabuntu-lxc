#!/bin/bash

# v2.4 GLS 20151224

# Controlling script for orabuntu-lxc
# Gilbert Standen 20151224

# Usage:

# ~/Downloads/ubuntu-services.sh MajorRelease MinorRelease NumCon corp\.yourdomain\.com nameserver

# Example
# ~/Downloads/ubuntu-services-sh $1 $2 $3 $4                $5
# ~/Downloads/ubuntu-services.sh 6  7  4  orabuntu-lxc\.com stlns01

# Example explanation:

# Create containers with Oracle Enterprise Linux 6.7 OS version.
# Create four clones of the seed (oel67) container.  The clones will be named {ora67c10, ora67c11, ora67c12, ora67c13}.
# Define the domain for cloned containers as "orabuntu-lxc.com".  Be sure to include backslash before any "." dots.
# Define the nameserver for the "orabuntu-lxc.com" domain to be "stlns01" (FQDN:  "stlns01.orabuntu-lxc.com").

# Oracle Enteprise Linux OS versions OEL5, OEL6, and OEL7 are currently supported.

# The clone container prefix "ora$1$1c" can be changed, but DO NOT USE "oel" in the clone names (bug).  The "oel" prefix is a "reserved" word so to speak.

clear
~/Downloads/orabuntu-lxc-master/ubuntu-services-1.sh $1 $2 $4 $5
clear
~/Downloads/orabuntu-lxc-master/ubuntu-services-2.sh $1 $2
clear
~/Downloads/orabuntu-lxc-master/ubuntu-services-3.sh $1 $2
clear
~/Downloads/orabuntu-lxc-master/ubuntu-services-4.sh $1 $2 $3 ora$1$2c
clear
~/Downloads/orabuntu-lxc-master/ubuntu-services-5.sh $1 $2

