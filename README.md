# Orabuntu-LXC

Begin Update:  December 2, 2017

Note that in the following, this new update feature is only available on Oracle Linux 7 VM's at this time, but it should be ported very very soon to Ubuntu VM's as well. As far as physical hosts, ANY Orabuntu-LXC supported physical host can be used, including Ubuntu, Oracle Linux, and RedHat.  Only the VirtualBox VMs have to be Oracle Linux 7.  Support for Ubuntu VMs for this same feature will be released very soon.

Orabuntu-LXC latest development branch now supports putting your Oracle VirtualBox VM's on the Orabuntu-LXC OpenvSwitch network on the physical host.  To use this new feature, first install Orabuntu-LXC on the physical host (Oracle Linux, RedHat, Ubuntu), then next install VirtualBox on the physical host, and finally, bridge the VirtualBox VM to ports on the sw1 and/or sx1 OpenvSwitches.  For example, use pre-configured ports s2 and a2 on OpenvSwitches sw1 and sx1, respectively.

If you want to also install Orabuntu-LXC itself in a VirtualBox VM that is on Orabuntu-LXC OpenvSwitch networks of the physical host then you must also set "Allow All" as the promiscuous mode of the VirtualBox Virtual NICs using the VirtualBox GUI or alternatively by using the VBoxManager CLI commands.  This will allow LXC containers running on the Orabuntu-LXC OpenvSwitch networks inside the VM to talk with the LXC containers running on the Orabuntu-LXC OpenvSwitch networks on the phyiscal host.  Indeed, this will allow all LXC containers, whether running in the VM or on the physical host, to have ssh connectivity with each other, and also with all hosts (both the physical host and the VM host).

Also, all VM hosts, and the physical host, and the LXC containers whether on the physical host or in the VM's, will ALL be in DNS and are accessible via DNS resolution or via IPs.

Finally, if you want to have 2 or more VirtualBox VM's running on the physical host and allow all of the LXC containers on all of the VM's and the physical host to all be able to ssh to each other, then set the "GRE=Y" parameter in the "anylinux-services.sh" file when installing Orabuntu-LXC into the 2nd, 3rd, 4th, etc. VMs.  One of the nice things about this setup (VirtualBox VM's on physical Orabuntu-LXC host) is that you can use MTU 1500 throughout even though traffic is going over a GRE tunnel between the VMs.

So, if you were setting this up, you would do the first install Orabuntu-LXC on the physical host with the following settings:
```
SudoPassword=<your-sudo-password>
GRE=N
MultiHost="new:N:1:$SudoPassword:192.168.1.82:10.207.39.13:1500:ubuntu:ubuntu:$GRE"
```
Then create a VirtualBox VM with two bridged adapters, one bridged to port s2 on switch sw1 on the physical host, and one bridged to a2 on switch sx1 on the physical host, and optionally both adapters set to "Allow All" promiscuous mode (if you are planning to install Orabuntu-LXC itself in the VirtualBox VMs).

If installing Orabuntu-LXC in the first VirtualBox VM, then use these settings (note IP address settings in MultiHost variable don't matter at this step, they are only used if GRE=Y):
```
SudoPassword=<your-sudo-password>
GRE=N
MultiHost="new:Y:4:$SudoPassword:10.207.39.14:10.207.39.17:1500:ubuntu:ubuntu:$GRE"
```
If installing Orabuntu-LXC in the second VirtualBox VM, use these settings (note set the first IP addresses reading from left to right in MultiHost to the IP address of the first VM you installed with Orabuntu-LXC and the second IP address to the second VM that you are about to install now with Orabuntu-LXC) as shown below.  These IP are used to automatically build the GRE tunnel between these two VM's.  If you have more than 2 VM's you can decide which two VM's you want to connect via a GRE tunnel and set the IP's accordingly. 
```
SudoPassword=<your-sudo-password>
GRE=Y
MultiHost="new:Y:5:$SudoPassword:10.207.39.14:10.207.39.17:1500:ubuntu:ubuntu:$GRE"
```
Note that you should increment the 3rd variable of MultiHost (e.g. "5" above) for each VM you subsequently install so that the OpenvSwitches get unique names on each VM, and so that the SCST LUNs on each host get unique names.

That's it basically.  All of the GRE tunnel setup is handled by the scripts, and the install is kicked off as usual by running "./anylinux-services.sh".  This feature isn't available for Ubuntu VM's yet, but it is available for both Ubuntu and Oracle Linux physical hosts, as long as your VM's are Oracle Linux 7.

End Update:  December 2, 2017

Orabuntu-LXC v5 EE Multihost https://github.com/gstanden/orabuntu-lxc is high-performance LXC Linux Container software https://linuxcontainers.org/ for Oracle for the Enterprise or the Desktop. It uses LXC with OpenvSwitch http://openvswitch.org/ and VLANs and provides a DNS/DHCP dynamic containerized bundled naming DHCP services solution.  Orabuntu-LXC v5 EE MultiHost is licensed under GPL3 https://www.gnu.org/licenses/gpl-3.0.en.html.

Build an environment of 10 Oracle Linux https://www.oracle.com/linux/index.html containers for example in about 15 minutes complete with full networking capability and DNS/DHCP.  Erase that same entire 10-container environment in less than 1 minute and create a new enviro! Great, fast solution for re-provisioning local or cloud training environments literally in just minutes at the push of a single button!

The available library of Oracle Linux container templates include Oracle Linux 5, 6 and 7.  You can create customized gold copies libraries of Oracle Linux 5, 6 and 7 LXC containers that you have customized with your specialized package prerequities and other customizations and then deploy those containers as you need them.  The possibilities are endless!  Our seed containers run on a separate OpenvSwitch network that talks with the main default container design network.

Need additional networks with custom IP ranges for your work?  No problem!  Just add the forward and reverse zone files to the included DNS DHCP container, and add another OpenvSwitch, configure the patch ports to the main switch (all easy and quick) and voila! you have the additional networks you need, and you can add as many as you like, all with full networking configured.

With Orabuntu-LXC v5 EE MultiHost you can do it because unlike VirtualBox our software switches are NOT just Linux bridges, they are real production-quality multilayer full-featured switches very similar to what Google, Facebook and Twitter run in their datacenters.

But wait, there's more on networking! Orabuntu-LXC v5 EE MultiHost comes with a BUILT-IN Oracle GNS (Grid Naming Service) capability built into the DNS DHCP networking solution.  You can use Oracle GNS right out of the box when installing Oracle RAC into Orabuntu-LXC v5 EE MultiHost Oracle Linux LXC containers.  Our Oracle GNS is located at 10.207.39.3 and is the easiest way to deploy Oracle 12c ASM Flex Cluster RAC.  

```
[ubuntu@ol74b-server orabuntu-lxc]$ nslookup 10.207.39.3
Server:		127.0.0.1
Address:	127.0.0.1#53

3.39.207.10.in-addr.arpa	name = lxc1-gns-vip.urdomain1.com.
[ubuntu@ol74b-server orabuntu-lxc]$
```

Ideal for training classes, prototyping, development, and now, with Orabuntu-v5 EE MultiHost enterprise deployment as well!  Orabuntu-LXC v5 EE MultiHost includes a GRE tunnel auto-configuration which allows you to build hub-and-spoke networks of LXC physical hosts and span your container networks across the physical hosts. You can easily build your own add-on GRE tunnels to connect the spoke hosts to each other and build a "wheel" of hosts!  With the production-grade industrial-strength OpenvSwitch network http://openvswitch.org/ that Orabuntu-LXC v5 EE MultiHost uses, you can do pretty much anything you can imagine with your networking.

The included central DNS/DHCP solution provides DNS/DHCP for all the containers across all the hosts.  

But wait, there's more!  Orabuntu-LXC v5 EE MultiHost comes with the scst-files.tar bundle. The scst-files.tar bundle will install and create an SCST Linux file-backed SAN http://scst.sourceforge.net/ for use with your LXC container deployment, but not only that, it will also automagically build an /etc/multipath.conf file customized for your hardware and environment and bring up all your file-backed multipath LUNs with friendly names, with owner, group, and mode set, and multipath-ready in container-specific directories under for example, /dev/containername1, for use with your Orabuntu-LXC v5 EE MultiHost containers.  

Want to present "real" FC or Infiniband LUNs directly into your Orabuntu-LXC v5 EE MultiHost LXC containers?  No problem!  SCST Linux SAN is a full-featured production-ready industrial-strength Linux SAN solution developed in cooperation with SanDisk Corporation and is used in many production flash arrays from Kaminario, Violin Memory and others http://scst.sourceforge.net/users.html. Orabuntu-LXC includes SCST deployment code which deploys SCST as an RPM package (RedHat-family linuxes) or as a DKMS-enabled DEB package (Debian-family linuxes) which means when you install SCST with OUR Orabuntu-LXC v5 EE MultiHost scst-files.tar installer, SCST will automatically rebuild its' kernel modules transparently whenever you upgrade your kernel. We announced that here: https://sourceforge.net/p/scst/mailman/message/36026527/ and are now listed on the SCST homepage as the solution for building SCST DKMS packages here: http://scst.sourceforge.net/downloads.html.  

Whether you want to use Orabuntu-LXC v5 EE MultiHost for the desktop, or for the enterprise, the technology stack is IDENTICAL in both environments, and blazing fast performance in both environments.  Orabuntu-LXC v5 EE MultiHost is a converged high-performance technology stack for running Oracle Linux LXC containers on Linux Hosts (we currently support Oracle Linux, RedHat Linux, CentOS Linux, and Ubuntu Linux).  If you architect your enterprise deployment on Orabuntu-LXC v5 EE MultiHost you can literally just forklift that design into your datacenter with NO CHANGES because Orabuntu-LXC v5 EE MultiHost has no additives, no artificial flavors or preservatives and is totally built on mainline Linux core technology with no hypervisors, no vmdk's, and no virtualized hardware: Just baremetal performance from compute, network and storage at blazing fast performance with high-density and amazing fast-spinup elasticity.

And yes, Virginia, you can run Oracle RDBMS 12c ASM Flex Cluster RAC even directly on Ubuntu Linux kernel in our Oracle Linux containers with perfect results with our Orabuntu-LXC v5 EE MultiHost edition.

You can review my slideshow from my Linux Foundation presentation here (a little bit dated here and there) but still with very relevant overview of the power of LXC Linux containers for running Oracle Enterprise software and now with the amazing rapid-deployment full-featured, enterprise-ready, desktop-ready power of Orabuntu-LXC v5 EE MultiHost Editon!

http://events.linuxfoundation.org/sites/events/files/slides/Standen_Linux_Clusters_1.pdf

Orabuntu-LXC v5 EE MultiHost is an open source GPL3 licensed product of Stillman Real Consulting LLC http://www.consultingcommandos.us/ and we would love to help your enterprise deploy Orabuntu-LXC v5 EE MultiHost and turbocharge performance and efficiency in your landscape.

Stillman Real Consulting LLC, an Oracle Consulting provider of enterprise database consulting and support services with a vision of providing to our clients excellence and cutting-edge Oracle consulting with compliance to all applicable accounting and privacy standards with respect to the data entrusted to our consultants.  Stillman Real Consulting LLC, delivering compliance to our clients with Sarbanes-Oxley (SOX);  21 CFR Part 11;  and HIPAA as well as other company-specific and industry-specific laws, regulations, and guidelines. 

To install the software:

* Create an "ubuntu" linux user that has SUDO ALL privilege (root privileges)
* Connect as the "ubuntu" admin linux user and create a "/home/ubuntu/Downloads" directory if it does not already exist.
* Note that for RedHat based linuxes there is a script to create the "ubuntu" admin user.  Those scripts are:
* uekulele-services-0.sh
* lxcentos-services-0.sh
* You can also just create an "ubuntu" linux admin user at the time you install the OS.
* Install unzip package on OS 
* Download zip archive github dev code or release from github to "/home/ubuntu/Downloads" directory or user wget, curl etc.
* Unzip the zip archive.
* If download was a release, you MUST move the release top directory to "orabuntu-lxc-master" e.g.
```
       * mv orabuntu-5.0-beta orabuntu-lxc-master 
```
* This is because some absolute paths still need to be removed and for now you must do the mv step.
* Navigate to /home/ubuntu/Downloads/orabuntu-lxc-master/anylinux
* Edit the "anylinux-services.sh" script to set the parameters you want for your deployment.
* As the "ubuntu" user, run the following command:  "./anylinux/anylinux-services.sh"
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
