# Orabuntu-LXC

To install the software:

(1) First unzip the distribution

(2) If running on Oracle Linux 7:  Navigate to orabuntu-lxc-master/uekulele/uekulele-services-0.sh and run that script to create the "ubuntu" user on Oracle Linux 7.  Note that the "ubuntu" user is an administrative user with wheel privilege via "sudo".  The uekulele-services-0.sh script must be run as root.

If running on Ubuntu 16.04 similar procedure but the steps to grant root wheel privileges to the "ubuntu" user might be slightly different.  When I was developing I simply created my VM with the install user chosen as "ubuntu" so it got "wheel" automatically, but of course it's very straightforward to just created an ubuntu user and grant it admin sudo privs.  The software is designed to be installed under the "ubuntu" user on either distro Ubuntu or Oracle Linux.  That's just the way I designed it (for good reasons).

(3) Now move the distribution directory from wherever you unzipped it to the /home/ubuntu/Downloads and chmod -R ubuntu:ubuntu the distribution.

(4) To run the software:  /home/ubuntu/Downloads/anylinux/anylinux-services.sh The software will detect what OS you have and automatically apply the required scripts to build the system and deploy the LXC containers for you.

(5) If you want to set the installation parameters you can pass them in at the command line, or, you can edit the anylinux-services.sh script (recommended method) near the end of the script where default values are set.  You can set two domain names, the name of the DNS DHCP nameserver that is created, number of container "clones" to be created, Major Oracle Linux release version (for the containers, e.g "7") and Minor Release (for the containers, e.g. "3") which would result in Oracle Linux 7.3 containers.

That's it.  The scripts will run and when done you will have however many containers you specified in the parameters of whatever Oracle Linux release specified (supports Oracle Linux 5, 6 and 7) and you will have them running on an OpenvSwith network and will also have a container which is the dynamic DNS DHCP provider for the containers.

This software is "Oracle-centric" in that only Oracle Linux 5, 6 and 7 containers are supported.  The containers are built with all the required prerequisites for installing Oracle database 12c, Oracle EBS, etc. and you can customize the prerequisites in uekulele-services-3.sh if you are installing an Oracle software product that needs some prerequisites that are different from the usual database 12c settings.

The software creates Oracle Linux containers on either Oracle Linux 7 (UEK3, UEK4, OL RHCC kernels) or on Ubuntu 16.04. The containers include by default Oracle GNS configuration in the DNS (gns1.yourdomainname.com) at 10.207.39.3 which you can use as your GNS provider when you install a 12c RAC GNS ASM Flex cluster.  I've installed the 12c RAC GNS ASM Flex cluster into the OL containers on both the Ubuntu 16.04 baremetal LXC host and of course on the Oracle Linux 7 LXC bare metal host and they both work great.

You can easily put VM's on your OpenvSwitch network as well simply by choosing bridged mode for example in the VirtualBox GUI and choosing one of the "s1" ports from the dropdown.  

The system is actually highly configurable and I will be creating extensive documentation in the coming weeks.  If I do say so myself this software has alot of mighty engineering, I think you will like using it.  Of course, you can build things besides Oracle projects in these containers; the software is powerful in that it builds you a complete working environment for containers - DNS/DHCP dynamic services and an OpenvSwitch network - and all containers have full WAN resolution designed in - so you can download whatever packages you want and build whatever you want in these Oracle Linux containers - not just Oracle software projects.  But the system is designed to promulgate Oracle Linux containers only.  The exception is that the DNS DHCP utility container is an Ubuntu Xenial 16.04 container.  But in general this software is Oracle Linux centric as far as the containers go:  Oracle Corporation is the flagship provider of an enterprise grade RedHat family distribution and so this product is built for deploying Oracle Linux containers - but what you build in those containers is completely open and limited only by your imagination and skill.

As of now, the IP subnets are hardcoded at 10.207.39.0/24 and 10.207.39.0/24 but user-settable subnets are coming and are a high-priority on the roadmap.  Since this is just an exercise in a bunch of sed and possibly awk commands this feature should not be too far away and then that feature will be in the anylinux-services.sh file as well.  Since this is open source you can fork it and add that feature yourself of course too.

If you have any questions or want to request enhancements, reach me at "gilstanden@hotmail.com"
