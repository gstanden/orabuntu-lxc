# Orabuntu-LXC

To install the software:

* Create an "ubuntu" linux user that has SUDO ALL privilege (root privileges)
* Connect as the "ubuntu" admin linux user and create a "/home/ubuntu/Downloads" directory if it does not already exist.
* Note that for RedHat based linuxes there is a script to create the "ubuntu" admin user.  Those scripts are:
* uekulele-services-0.sh
* lxcentos-services-0.sh
* You can also just create an "ubuntu" linux admin user at the time you install the OS.
* Install unzip package on OS 
* Download our github zip archive from our github to "/home/ubuntu/Downloads" directory or user wget to download it.
* Unzip the zip archive.
* Navigate to /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux
* Edit the "anylinux-services.sh" script to set the parameters you want for your deployment.
* Run as "ubuntu" admin user the following script:  "./anylinux-services.sh"
* That's it.  There are a few prompts you answer. The software is coded in bash so you can easily take out prompts.
* The software automatically does the following:
* Creates an Ubuntu Xenial DNS/DHCP LXC container providing dynamic DNS/DHCP services to your LXC container networks
* A seed Oracle Linux (5 6 or 7) LXC container configured with the prerequisites of your choice (see script 3)
* Will optionally add in additional networks
* Will clone the seed container to a user-set number of identical copies.
* Will start the clone containers and assign a DHCP address and add them to DNS dynamically
* Orabuntu-LXC comes with an enterprise-grade SAN solution to be used with your Orabuntu-LXC container deployment.  
* Multipath LUNs are configured on boot in directories of the form:
* /dev/containername1
* /dev/containername2 etc.
* To present the LUNs edit the config files of the LXC containers and uncomment the two lines for LUN presentation.

Send feedback to gilbert@orabuntu-lxc.com
Thank You
Gilbert Standen
October 2017
