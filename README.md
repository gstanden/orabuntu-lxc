# Orabuntu-LXC

To install the software:

* Create an "ubuntu" linux user that has SUDO ALL privilege (root privileges)
* Connect as the "ubuntu" admin linux user and create a "/home/ubuntu/Downloads" directory if it does not already exist.
* Note that for RedHat based linuxes there is a script to create the "ubuntu" admin user.  Those scripts are:
* uekulele-services-0.sh
* lxcentos-services-0.sh
* You can also just create an "ubuntu" linux admin user at the time you install the OS.
* Install unzip package on OS 
* Download our github zip archive from our github to "/home/ubuntu/Downloads" directory or user wget, curl etc.
* Unzip the zip archive.
* Navigate to /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux
* Edit the "anylinux-services.sh" script to set the parameters you want for your deployment.
* As the "ubuntu" user, run the following script:  "./anylinux-services.sh"
* That's it.  There are a few prompts you answer. The software is coded in bash so you can easily take out prompts.
* The software automatically does the following:
* Creates an Ubuntu Xenial DNS/DHCP LXC container providing dynamic DNS/DHCP services to your LXC networks.
* Creates an OpenvSwitch SDN (Software-Defined Network) with VLAN support on which the containers run.
* A seed Oracle Linux (5 6 or 7) LXC container configured with the prerequisites of your choice (see script 3)
* Will optionally add in additional networks
* Will clone the seed container to a user-set number of identical copies.
* Will start the clone containers and assign a DHCP address and add them to DNS dynamically
* Orabuntu-LXC comes with an enterprise-grade SAN solution (SCST) 
* SCST can be used with your Orabuntu-LXC container deployment.
* SCST comes with "scst-files.tar" which completely automates building file-backed LUNs for your LXC deployment.
* SCST can of course be used alternatively with manual configuration of fiber channel HBA's, Infiniband, etc.
* Multipath LUNs are configured on boot in directories of the form:
* /dev/containername1
* /dev/containername2 etc.
* To present the LUNs edit the config files of the LXC containers and uncomment the two lines for LUN presentation.
* Note that when presenting the storage you need to edit the path to the storage in the config file too.
* Note that our blog https://sites.google.com/site/nandydandyoracle has much valuable hands-on learning.

#### Please follow the Orabuntu-LXC project with your github account and log issues here at this github.

Send feedback to gilbert@orabuntu-lxc.com
Thank You, 
Gilbert Standen, 
October 2017
