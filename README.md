# Orabuntu-LXC

To install the software:

* Create an "ubuntu" linux user that has SUDO ALL privilege (root privileges)
* Connect as the "ubuntu" admin linux user and create a "/home/ubuntu/Downloads" directory if it does not already exist.
* Note that for RedHat based linuxes there is a script to create the "ubuntu" admin user.  Those scripts are:
** uekulele-services-0.sh
** xcentos-services-0.sh
(4)   
Note that if you are creating a VM to try Orabuntu-LXC the simplest thing is to create an "ubuntu" linux admin user    at the time you install the OS.
(4)   
Install unzip package on OS 
(5)   
Download our github zip archive from our github to "/home/ubuntu/Downloads" directory or user wget to download it.
(6)
Unzip the zip archive.
(7)
Navigate to /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux
(8)
Edit the "anylinux-services.sh" script to set the parameters you want for your deployment.
(9)
Run as "ubuntu" admin user the following script:  "./anylinux-services.sh"
(10) 
That's it.  There are a few prompts you answer.  The software is coded in bash so you can easily take out the prompt steps and make it fully autonomous and silent.  The Orabuntu-LXC software will build:
     (10a)  An Ubuntu Xenial DNS/DHCP LXC container providing dynamic DNS/DHCP services to your LXC container networks
     (10b)  A seed Oracle Linux (5 6 or 7) LXC container configured with the prerequisites of your choice (see script 3)
     (10c)  Will optionally add in additional networks
     (10d)  Will clone the seed container to a user-set number of identical copies.
     (10c)  Will start the clone containers and assign a DHCP address and add them to DNS dynamically
(11)
Optionally you can run the scst-files.tar archive which will fully automate the creation of an SCST enterprise-grade SAN solution to be used with your Orabuntu-LXC container deployment.  LUNs are configured on boot in directories of the form:
     (11a) /dev/containername1
     (11b) /dev/containername2
etc.  To present the LUNs edit the config files of the LXC containers and uncomment the two lines for LUN presentation.

Send feedback to gilbert@orabuntu-lxc.com
Thank You
Gilbert Standen
October 2017
