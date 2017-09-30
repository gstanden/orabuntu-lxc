# Orabuntu-LXC

Orabuntu-LXC v5 EE Multihost is high-performance LXC Linux Container software https://linuxcontainers.org/ for Oracle for the Enterprise or the Desktop. It uses LXC with OpenvSwitch http://openvswitch.org/ and VLANs and provides a DNS/DHCP dynamic containerized bundled naming DHCP services solution.  

Build an environment of 10 Oracle Linux containers for example in about 15 minutes complete with full networking capability and DNS/DHCP.  Erase that same entire 10-container environment in less than 1 minute and create a new enviro! Great, fast solution for re-provisioning local or cloud training environments literally in just minutes at the push of a single button!

The available library of Oracle Linux container templates include Oracle Linux 5, 6 and 7 https://www.oracle.com/linux/index.html.  You can create customized gold copies libraries of Oracle Linux 5, 6 and 7 LXC containers that you have customized with your specialized package prerequities and other customizations and then deploy those containers as you need them.  The possibilities are endless!  Our seed containers run on a separate network that talks with the container design network.

But wait, there's more on networking! Orabuntu-LXC v5 EE MultiHost comes with a BUILT-IN Oracle GNS (Grid Naming Service) capability built into the DNS DHCP networking solution.  You can use Oracle GNS right out of the box when installing Oracle RAC into Orabuntu-LXC v5 EE MultiHost Oracle Linux LXC containers.  Our Oracle GNS is located at 10.207.39.3 and is the easiest way to deploy Oracle 12c ASM Flex Cluster RAC.  

[ubuntu@ol74b-server orabuntu-lxc]$ nslookup 10.207.39.3
Server:		127.0.0.1
Address:	127.0.0.1#53

3.39.207.10.in-addr.arpa	name = lxc1-gns-vip.urdomain1.com.
[ubuntu@ol74b-server orabuntu-lxc]$ 

With Orabuntu-LXC v5 EE MultiHost you can do it because unlike VirtualBox our software switches are NOT just Linux bridges, they are real production-quality multilayer full-featured switches very similar to what Google, Facebook and Twitter run in their datacenters.

Ideal for training classes, prototyping, development, and now, with Orabuntu-v5 EE enterprise deployment as well!  Orabuntu-LXC v5 EE includes a GRE tunnel auto-configuration which allows you to build hub-and-spoke networks of LXC physical hosts and span your container networks across the physical hosts. You can easily build your own add-on GRE tunnels to connect the spoke hosts to each other and build a "wheel" of hosts!  With the production-grade industrial-strength OpenvSwitch network http://openvswitch.org/ that Orabuntu-LXC v5 EE MultiHost uses, you can do pretty much anything you can imagine with your networking.

The included central DNS/DHCP solution provides DNS/DHCP for all the containers across all the hosts.  

But wait, there's more!  Orabuntu-LXC v5 EE comes with the scst-files.tar bundle. The scst-files.tar bundle will install and create an SCST Linux file-backed SAN http://scst.sourceforge.net/ for use with your LXC container deployment, but not only that, it will also automagically build an /etc/multipath.conf file customized for your hardware and environment and bring up all your file-backed multipath LUNs ready for use with your Orabuntu-LXC containers.  Want to use "real" FC or Infiniband LUNs with Orabuntu-LXC?  No problem!  SCST Linux SAN is a full-featured production-ready industrial-strength Linux SAN solution developed in cooperation with SanDisk Corporation and is used in many production flash arrays from Kaminario, Violin Memory and others http://scst.sourceforge.net/users.html. Orabuntu-LXC includes SCST deployment code which deploys SCST as an RPM package (RedHat-family linuxes) or as a DKMS-enabled DEB package (Debian-family linuxes) which means SCST will automatically rebuild its' kernel modules transparently whenever you upgrade your kernel. We announced that here: https://sourceforge.net/p/scst/mailman/message/36026527/ and are now listed on the SCST homepage as the solution for building SCST DKMS packages here: http://scst.sourceforge.net/downloads.html.  

Whether you want to use Orabuntu-LXC v5 for the desktop, or for the enterprise, the technology stack is IDENTICAL in both environments, and blazing fast performance in both environments.  Orabuntu-LXC a converged high-performance technology stack for running Oracle Linux LXC containers on Linux Hosts (we currently support Oracle Linux, RedHat Linux, CentOS Linux, and Ubuntu Linux).  If you architect your enterprise deployment on Orabuntu-LXC v5 EE MultiHost you can literally just forklift that design into your datacenter with NO CHANGES because Orabuntu-LXC v5 EE MultiHost has no additives, no artificial flavors or preservatives and is totally built on mainline Linux core technology with no hypervisors, no vmdk's, and no virtualized hardware: Just baremetal performance from compute, network and storage at blazing fast performance with high-density and amazing fast-spinup elasticity.

And yes, Virginia, you can run Oracle RDBMS 12c ASM Flex Cluster RAC even directly on Ubuntu Linux kernel in our Oracle Linux containers with perfect results with our Orabuntu-LXC v5 EE MultiHost edition.

You can review my slideshow from my Linux Foundation presentation here (a little bit dated here and there) but still with very relevant overview of the power of LXC Linux containers for running Oracle Enterprise software and now with the amazing rapid-deployment full-featured, enterprise-ready, desktop-ready power of Orabuntu-LXC v5 EE MultiHost Editon!

http://events.linuxfoundation.org/sites/events/files/slides/Standen_Linux_Clusters_1.pdf

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
* Will clone the seed to whatever number of clone containers you require of that version
* Includes an enterprise-grade SAN solution (SCST) 
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
