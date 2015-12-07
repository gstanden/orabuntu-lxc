# orabuntu-lxc
Oracle Enterprise Edition Software on Ubuntu Linux using LXC Containers.
This software runs Oracle Enteprise Edition RAC database on Ubuntu 15.04 or 15.10 64-bit Desktop Edition using Oracle Enteprise Linux 6.5 LXC Containers.

Why Linux Containers ?

The Oracle Enterprise Edition 6.5 LXC Linux containers run at bare metal resource utilization for network, storage, and CPU with NO hypervisor performance penalty.  That is because LXC does NOT use a hypervisor.  Every container access all computer resources at bare-metal utilization.  Also, because there is NO hypervisor, LXC Linux containers achieve 10x the density of hypervisor-based systems per unit compute resource.  Because LXC Linux containers deploy in seconds instead of hours or days, LXC Linux containers also achieve huge improvements in elasticity, because they can be spun up in seconds as needed.  

Install on a FRESH INSTALL of 15.04 or 15.10 ONLY. I have not bulletproofed this for install on "been-running-for-awhile" deployments of Ubuntu.  It could overwrite stuff so review the scripts VERY carefully first if you are going to put this on an Ubuntu 15.x that you have been using for a long time that is already customized. 

I have NOT tested this yet on Ubuntu 12.x, 13.x, or 14.x          (tests and validation coming soon for these versions!)

NOTE:  My email is gilstanden@hotmail.com if you hit bugs or issues or have questions!

Technology Platforms:

  isc-dhcp-server

  bind9

  openvswitch

  lxc

Screenshots and additional information can be found at the following Google Site:

https://sites.google.com/site/nandydandyoracle/technologies/lxc/oracle-rac-6-node-12c-gns-asm-flex-cluster-ubuntu-15-04-install

=============================
!!! IMPORTANT PLEASE READ !!!
=============================

To install:

1. Download the zip file from https://github.com/gstanden/orabuntu-lxc to your ~/Downloads directory on Ubuntu 15.x
2. Unzip the zip file which will create the directory ~/Downloads/orabuntu-lxc-master
3. Change directory to ~/Downloads/orabuntu-lxc-master
4. Edit the script ubuntu-services.sh to tell ubuntu-services-3c.sh how many oracle-ready containers you want to create.
5. Run ONLY on fresh install of Ubuntu 15.04 or 15.10 !
6. Run as the "gstanden" user (Fix is coming for this problem.  For now, you must create a "gstanden" account for the install)
6. Run the script ~/Downloads/orabuntu-lxc-master/ubuntu-services.sh (note, it's a fully-automated, non-interactive script).

!!! =============================

About the ubuntu-services-0.sh script
 
  /home/your-username/Downloads/orabuntu-lxc-master/ubuntu-services-0.sh 

  This creates the 'gstanden' account. 

  This is a fix for sloppy hardcoding.

!!! =============================

Update 2015-12-06:  There are no reboots anymore. 

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services.sh
  
and this new script is a master script which runs all of the below scripts automatically.  Note that all of the scripts are individually re-runnable, and the whole set of scripts is also re-runnable, so if you have a failure of one script for any reason, just fix the problem, and re-run that script.  If you want to re-run the whole set of scripts, just re-run ubuntu-services.sh again to re-run them all.  Note also the ubuntu-services-3c.sh takes a parameter integer that is the number of containers to create.  Edit ubuntu-services.sh to set the parameter for ubuntu-services-3c.sh.

UPDATE:  You just run the file '/home/gstanden/Downloads/orabuntu-lxc/ubuntu-services.sh' to do the install.  

  This is where the software proper begins.

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-1.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-2a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-2b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3c.sh X  {where X is an integer between 1 and 99}

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3d.sh

The above steps will create the Oracle Enterprise Edition 6.5 LXC Oracle-enterprise-edition RAC-ready containers.

!!! =============================

Phase 2:  Create the SCST Linux SAN LUNs for Oracle Grid Infrastructure

This Phase 2 is OPTIONAL.  You will need storage LUNs for your Oracle Grid Infrastructure (GI) and your Oracle Database so this module creates file-backed LUNs and the SCST custom kernel providing a SAN for the containers.

You can opt to use other solutions for file-backed storage such as Linux TGT.  I will be developing an automated Linux TGT SAN script package to go with this project, but that is on the roadmap only for now.  Linux TGT is much simpler to implement and does not require a custom Linux kernel.  

The main reason for choosing SCST Linux SAN is that SCST supports native 4K format with no 512-byte emulation layer, so SCST is useful for testing both 4K and 512-byte native format storage with various Oracle database softwares.  If you will not need 4K native support, TGT is probably a much simpler choice since it does not require a custom kernel.  Note however that SCST is one of the most feature-rich Linux SAN solutions and is used in versions of commercial products such as some Kaminario all-flash SANs and some Violin Memory all-flash SANs. Because SCST is much more difficult to implement, I created the scripts to automatically build SCST for you, since guides to implement SCST on Ubuntu Linux are hard to find on the internet, while Linux TGT SAN guides are readily available and good.  My scripts are a scripted automation of the manual steps of the amazingly accurate and awesome guide that Chris Weiss created here:  

https://gist.github.com/chrwei/42f8bbb687290b04b598

Without the great work by Chris Weiss sharing this method publicly, my scst-files.tar archive for automatically building SCST SAN for Oracle on Ubuntu Linux would simply not exist.  If you run into bugs or script failures on your hardware for my scripts, please send me the error information to gilstanden@hotmail.com .  My scripts create the SCST custom kernel, create the SCST target and LUNs, and also build the /etc/multipath.conf file and install it automatically.  It's likely that some issues might be encountered on various hardware at the /etc/multipath.conf creation step, so if you hit issues with that step, I'd like to know about it if you have time to send details.

IMPORTANT:  Whatever storage solution you use, your storage LUNs will appear in '/dev/mapper/' directory with multipath friendly names that have 'asm*' as the prefix of the friendly name, because multipath "friendly names" with the "asm" prefix is how my scripts prepare storage for presentation to Oracle.  So if you are using an actual SAN solution such as Tegile, Violin Memory, Dell, IBM, etc. my SCST install scripts will get the wwid of your LUNs and assign multipath friendly names to them with an 'asm' prefix, such as for exmaple:

/dev/mapper/asm_systemdg_00' 

which of course will actually refer to a /dev/dm- device.  If you are on Ubuntu 15.10, the storage will be a symlink in /dev/mapper to the /dev/dm-* device and if you are on Ubuntu 15.04 the storage will be a device node (no symlink) in /dev/mapper.

UPDATE 2015-12-07:  You can now run the SCST setup scripts from '/home/gstanden/Downloads/orabuntu-lxc-master/scst-files/' directory!  

tar -xvf scst-files.tar

cd scst-files

Run the create-scst-*.sh files in the order shown below.

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-1a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-1b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-1c.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-1d.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-2a.sh (host will reboot after this script to boot into new SCST kernel)

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-2b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-3.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-4a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-4b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-5a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/create-scst-5b.sh (host will reboot after this script).

Once all these scripts have run the SCST SAN and LUNs will be ready for the Oracle Grid Infrastructure 12c install

Follow the instructions at the Google Sites page referenced above.

# NOTE:  I am working to fix the hardcoded 'gstanden' problem.


