# Orabuntu-LXC

Any Oracle on Any Linux at bare-metal resource utilization with density and elasticity 10X+ hypervisor-based systems.

Orabuntu-LXC is for running any Oracle Enteprise software directly on an Ubuntu 15.x or 16.x desktop (linux 3.x or 4.x kernel, respectively) using Oracle Linux LXC containers.  "Oracle Linux" is Oracle Corporations own free flavor of Linux and is ideally suited to running Oracle enterprise software.  The solution method of running Oracle Linux containers on Ubuntu Linux should generally work on any flavor of Linux, so devs are invited to port orabuntu-lxc over to other Linux distros, such as for example, Gentoo Linux.  

Orabuntu-LXC is specifically for Ubuntu Linux so that you can run Oracle enteprise software in LXC containers at bare metal compute, storage, and network utilizations, and with a very short elastic spin-up time, on Ubuntu Linux.  Orabuntu-LXC does all the heavy lifting of containers creation, openvswitch networking, preparation of LXC containers for Oracle installation, and DHCP/DNS configuration for you in less than 15 minutes, for as many containers as you specify.  You can create 10, 50, 100 or more containers, all Oracle-ready, in just 15 minutes.  No more installing VirtualBox or VMWare for Linux, no more loading virtual CD's, and installing a virtualized OS; with Orabuntu-LXC you run the scripts and within about 15 minutes you have as many LXC Oracle Linux oracle-ready containers as you want, because Orabuntu-LXC also installs all the Oracle prerequisites into the seed containers before cloning it to as many LXC Oracle Linux containers as you need, so that you are assured all containers are identical and all containers are fully Oracle-install-ready.  Each containers has it's own network and address space, so it looks and feels just like a VM, but it boots up much faster and performs much better, because there is no virtualized hardware, and so the containers boot directly from init in just seconds instead of minutes.  Orabuntu-LXC also automatically installs an OpenvSwitch (http://openvswitch.org/) Software Defined Networking (SDN) backbone which not only networks all your Oracle-ready containers with a production ready industrial-grade switch and network solution, but it also includes and integrated DHCP/DNS solution so that your containers automatically get a DHCP IP address on first startup, and that IP address is automatically added to DNS for you, so that you don't have to edit DNS zone files, etc., but rather all networking, DHCP, and DNS is all automatically configured for you.  The Orabuntu-LXC solution is designed to be a "just add water and stir" type solution for getting Oracle enteprise products up and running on your Ubuntu Linux desktop faster than you can say "Jack Daniels" so that you can concentrate on working with Oracle and not configuring and installing systems.

Oracle Enterprise Edition Software on Ubuntu Linux using LXC Containers.
This software runs Oracle Enteprise Edition RAC database on Ubuntu 15.04 or 15.10 or 16.04 64-bit Desktop Edition using Oracle Linux LXC Containers.  Additional instructions for an install of Oracle 12c (12.1.0.2.0) RAC ASM Flex Cluster using GNS are provided at the 'nandydandyoracle' website ( https://sites.google.com/site/nandydandyoracle ).

One can think of orabuntu-lxc as a sort of Oracle Enterprise Linux 'emulation layer' for Ubuntu Linux, although it is much more than just that. Orabuntu-lxc is an automation layer for LXC that will create 10's or 100's of oracle-ready LXC containers (i.e. 'servers') of any OEL5, OEL6, or OEL7 version in just minutes, fully networked on OpenvSwitch SDN and ready for Oracle Enterprise software install.  Just add a downloaded Oracle install media, mix, and voila!  Oracle Enterprise is built!

======================
Why Linux Containers ?
======================

The Oracle Linux LXC containers run at bare metal resource utilization for network, storage, and CPU with NO hypervisor performance penalty.  That is because LXC does NOT use a hypervisor.  Every container accesses all compute resources at bare-metal utilization and speed.  Also, because there is NO hypervisor, LXC Linux containers achieve 10x the density of hypervisor-based systems per unit compute resource.  Because LXC Linux containers deploy in seconds instead of hours or days, LXC Linux containers also achieve huge improvements in elasticity compared to hypervisor-based systems, because they can be spun up in seconds as needed.  

Install on a FRESH INSTALL of 15.04 or 15.10 or 16.04 ONLY. I have not bulletproofed this for install on "been-running-for-awhile" deployments of Ubuntu.  It could overwrite stuff so review the scripts VERY carefully first if you are going to put this on an Ubuntu 15.x that you have been using for a long time that is already customized. 

I have NOT tested this yet on Ubuntu 12.x, 13.x, or 14.x          (tests and validation coming soon for these versions!)

NOTE:  My email is gilstanden@hotmail.com if you hit bugs or issues or have questions!

Technology Platforms:

  isc-dhcp-server

  bind9

  openvswitch  ( http://openvswitch.org/ )

  lxc ( https://linuxcontainers.org/ )

Screenshots and additional information can be found at the following Google Site:

https://sites.google.com/site/nandydandyoracle/technologies/lxc/oracle-rac-6-node-12c-gns-asm-flex-cluster-ubuntu-15-04-install

=============================
New Feature Version 2.5
=============================

Feature 1

The ubuntu-clone.sh script can be used to add additional clone containers for OEL releases for which you already have an oelXX container and for which clones have already previously been created.  

ubuntu-clone.sh 6 7 3

will create 3 more OEL 6.7 cloned containers in addition to any already created.  It will number the index of the cloned containers at the n+1th index.  For example, if ora67c14 is the highest-indexed clone of oel67, then the ubuntu-clone.sh will create the clone containers {ora67c15, ora67c16, ora67c17}. As another example, if the highest indexed container is ora59c14, then the new ora67 containers will still be the same set starting at c15.  The highest current index is evaulated across all oelXX versions.

Feature 2

You can now add in the ASM private network interfaces and RAC private network interfaces to the container clones as an option, and also remove them from the seed container once the clone is done so that the seed oelXX container continues to have only a single DHCP interface.

=============================
New Feature Version 3.1
=============================

The SCST SAN option NO LONGER REQUIRES A CUSTOM KERNEL!  Yay!  Orabuntu-LXC scst-files.tar now uses SCST branch 3.1.x which does not require compiling a custom kernel anymore for Linux kernels >= 2.6.30.  Just unpack the scst-files.tar and run the scripts according to the README.  The scripts will install SCST, configure an SCST SAN, and also automatically build the required /etc/multipath.conf file for the SAN. 

An experimental tgt-files.tar file introduces in version 3.0 the option to use TGT Linux file-backed SAN instead of SCST.  However, now that SCST no longer requires a custom kernel build, SCST is strongly recommended due to its superior and rich feature set. 

In version 3.0 of orabuntu-lxc, you can choose to use SCST or TGT.  Using both at the same time is not recommended due to the default ports for both solutions is port 3260.  The current release of scst-files.tar and tgt-files.tar does not support non-default ports for SCST or TGT and therefore the two solutions should not be used together or mixed.

Note that 4K sector size format LUNs currently CANNOT be used with Oracle databases in LXC on Ubuntu hosts because there is no ASMLib currently available for Ubuntu Linux. Orabuntu-LXC is hoping to port ASMLib over to Ubuntu but this is currently a long-term goal.  IN the meantime, if one wants to work with Oracle database on 4K format LUNs then Oracle DB can be built in a conventional VM such as VMWare or KVM alongside LXC containers all on the same host.  Inside of RedHat-based VM's ASMLib can be configured and the SCST iscsi LUNs can be passed through to the VM for a true 4K system for testing with Oracle database.  Therefore, there is still a use case where SCST is preferred if the need is to test 4K sector size format LUNs with Oracle, because TGT cannot provide that, while SCST CAN.

=============================
Installation
=============================

Phase 1:  Create the LXC Oracle Enteprise Linux (OEL 5.x, OEL 6.x or OEL 7.x) containers

To install:

1. Download the zip file from https://github.com/gstanden/orabuntu-lxc to your ~/Downloads directory on Ubuntu 15.x
2. Unzip the zip file which will create the directory ~/Downloads/orabuntu-lxc-master
3. Change directory to ~/Downloads/orabuntu-lxc-master
4. (Optional) run ubuntu-services-0.sh as a standalone pre-check utility to evaluate orabuntu-lxc install impacts.
5. Run the script ~/Downloads/orabuntu-lxc-master/ubuntu-services.sh (with appropriate parameters as discussed below).
6. You can accept defaults on all prompts the first time through the install.

Note:  OEL5 OEL6 OEL7 LXC Containers are supported.  

!!! =============================
```
~/Downloads/ubuntu-services.sh MajorRelease MinorRelease NumCon corp\.yourdomain\.com nameserver

Example
~/Downloads/orabuntu-lxc-master/ubuntu-services-sh $1 $2 $3 $4                $5
~/Downloads/orabuntu-lxc-master/ubuntu-services.sh 6  7  4  orabuntu-lxc\.com stlns01

Example explanation:

Create containers with Oracle Enterprise Linux 6.7 OS version.
Create four clones of the seed (oel67) container.  The clones will be named {ora67c10, ora67c11, ora67c12, ora67c13}.
Define the domain for cloned containers as "orabuntu-lxc.com".  Be sure to include backslash before any "." dots.
Define the nameserver for the "orabuntu-lxc.com" domain to be "stlns01" (FQDN:  "stlns01.orabuntu-lxc.com").
```

KEEP IN MIND WHEN READING THE USAGE NOTES BELOW THAT IT IS STRONGLY ADVISED TO ONLY INSTALL THIS SOFTWARE ON A FRESH INSTALL OF UBUNTU 15.10 OR 15.04 or 16.04 AND NOT TO INSTALL THIS ON A HIGHLY-CONFIGURED UBUNTU DESKTOP OR SERVER THAT HAS BEEN RUNNING FOR A LONG TIME WITH MANY CUSTOM-CONFIGURATIONS ALREADY IMPLEMENTED.  

THIS SOFTWARE MAKES CHANGES TO DHCP AND BIND9 (NAMED) CONFIGURATIONS SO IT COULD DISRUPT LOOKUPS AND NAME RESOLUTIONS ON AN ALREADY-BEEN-RUNNING-FOR-AWHILE UBUNTU HOST!

That being said, if you do want to install it on an existing Ubuntu deployment that is customized and has been running for awhile, use the ubuntu-services-0.sh pre-check script to evaluate effects of the orabuntu-lxc install.  This script will show all configuration files that will be overwritten or updated by orabuntu-lxc install.

NOTE 1:  If you do a second run of ubuntu-services.sh to create additional containers of a different OS version, be aware that the software looks for the file "/etc/orabuntu-lxc-release" and if found, it skips some of the setup steps such as Ubuntu host OS package installs (unpack of ubuntu-host.tar) since those steps were already done on the first pass, and proceeds directly to the creation of the new seed container.

NOTE 2:  Note that the seed containers (oel67, oel65, oel59, ...) get created on the 10.207.29.x network, while the cloned containers to be used for actual projects get created on the 10.207.39.x network.  Do not install Oracle Enterprise softwares into the oelxx containers, because these are your fully-configured, oracle-ready SEED containers which you can clone later to make more oracle-ready containers of that specific OEL version if you need more (use the ubuntu-clone.sh script for that).

NOTE 3:  When re-running the software, you are prompted early on to delete DHCP leases (Y/N) and to delete existing containers (Y/N).  If running the software a second time as mentioned above to create another set of containers of a different OEL version, answer "N" to all the questions so that your first run of containers is not destroyed, nor the first SEED container.

NOTE 4:  The DHCP lease delete steps and the container delete steps are useful if you run the whole set of scripts for the first time, and you run into some problem and want to start completely over.  In that case, answer "Y" to deleting DHCP leases, answer "Y" to delete containers, and answer "N" to "delete only the oelxx SEED container" so that the result will be ALL DHCP leases deleted, and ALL containers deleted, so that you are starting from scratch again.  Also, be sure before re-running "from scratch again" to DELETE the file "/etc/orabuntu-lxc-release" using "sudo rm /etc/orabuntu-lxc-release" so that the software executes ALL OS configuration steps again on the re-run of the first install.  Also, you may want to delete the /var/lib/bind/*.jnl files.  It is also recommended to do a reboot of the Ubuntu host if doing a complete re-run from scratch after the cleanup steps.

========================================
Oracle ASM Storage Options (SCST or TGT)
========================================

Orabuntu-LXC is for creating Oracle-ready LXC containers running on an Ubuntu Linux 3.x or 4.x kernel.  You can connect these containers to any file-backed or external SAN as long as you can present that storage to the Ubuntu Linux host such that the storage LUNs are in the /dev/mapper directory (because /dev/mapper is where Orabuntu-LXC is designed to look for the LUNs).  The /dev/mapper directory and /dev/ directory are shared with all the containers, which is how the containers get access to the storage at the host OS level.

However, if you are using Orabuntu-LXC to develop Oracle solutions or pilot a deployment on a desktop, you may want to create file-backed LUNs right on the same desktop.  Therefore, Orabuntu-LXC comes with automated scripted deployment bundles for two of the more well known Linux file-backed SAN solutions, namely SCST (http://scst.sourceforge.net/) and TGT (http://stgt.sourceforge.net/).  Which solution one might choose for an Orabuntu-LXC deployment is discussed below.

=============================
Why SCST ?
=============================

SCST supports native 4K controller block format as well as 512-byte.  It's also used in production in selected models of all-flash storage systems from Violin Memory and Kaminario, as well as others. Use of SCST with Orabuntu-LXC allows use of native 4K storage format so that working with all-flash storage that uses 4K format storage can be simulated effectively. Create the SCST Linux SAN LUNs for ASM if you are going to use ASM with your Oracle deployments. You will need storage LUNs for yourOracle Database so this module creates file-backed LUNs providing a SAN for the containers. In general, SCST is a highly-feature-rich production-grade SAN solution with many more options and features supported compared to TGT, so if you have advanced SAN configuration features and need special supported features, check the documentation for SCST because you may just need the more advanced solution of SCST.  With the release of version 3.1 of Orabuntu-LXC a custom-kernel build is NO LONGER NEEDED for SCST.  The scst-files.tar bundle includes scripting which installs SCST, creates an SCST target and LUNs, and even creates the fully configured multipath.conf file. 

Another thing to be aware of is that if you are using an Ubuntu desktop and you want to update your desktop regularly, you will NO LONGER need to compile a new custom kernel everytime you get a kernel update, so this is another reason that with SCST 3.1.x branch there really are no good reasons not to use SCST anymore.

In summary, SCST is a great solution if you want to have the most feature rich SAN solution.  N

============================= 
Why TGT ?
=============================

You can opt to use other solutions for file-backed storage such as Linux TGT.  I have develped an automated Linux TGT SAN script package to go with this project, which is now released for use with version 3.0 of orabuntu-lxc.  

The main reason for choosing SCST Linux SAN is that SCST supports native 4K format with no 512-byte emulation layer, so SCST is useful for testing both 4K and 512-byte native format storage with various Oracle database softwares. Note however that SCST is one of the most feature-rich Linux SAN solutions and is used in versions of commercial products such as some Kaminario all-flash SANs and some Violin Memory all-flash SANs.  created the scripts to automatically build SCST for you, since guides to implement SCST on Ubuntu Linux are hard to find on the internet, while Linux TGT SAN guides are readily available and good.  

IMPORTANT:  Whatever storage solution you use, your storage LUNs will appear in '/dev/mapper/' directory with multipath friendly names that have 'asm*' as the prefix of the friendly name, because multipath "friendly names" with the "asm" prefix is how my scripts prepare storage for presentation to Oracle.  So if you are using an actual SAN solution such as Tegile, Violin Memory, Dell, IBM, etc. my SCST install scripts will get the wwid of your LUNs and assign multipath friendly names to them with an 'asm' prefix, such as for exmaple:
```
/dev/mapper/asm_systemdg_00' 
```
which of course will actually refer to a /dev/dm- device.  If you are on Ubuntu 15.10, the storage will be a symlink in /dev/mapper to the /dev/dm-* device, or, if you are on Ubuntu 15.04 the storage will 'usually' be a device node (no symlink) in /dev/mapper but note that in Ubuntu 15.04 the disposition of multipath storage in /dev/mapper can sometimes be a mix of device nodes and symlinks as shown for example below:
```
gstanden@W1504:~$ ls -l /dev/mapper
brw-rw---- 1 grid asmadmin 252,   2 Dec  8 11:29 asm_fra1_01
lrwxrwxrwx 1 grid asmadmin        7 Dec  8 11:07 asm_fra1_02 -> ../dm-5
```
NOTE:  The orabuntu-lxc software can handle both (a) actual device nodes in /dev/mapper and (b) symlinks in /dev/mapper and so mixtures of both device nodes and symlinks is fine.  The only requirement for my scripting is that the storage for Oracle in /dev/mapper have the 'asm*' prefix.  Both of the above forms of storage presentation in /dev/mapper (symlink or device node or mixtures of both) are fine no problems.

UPDATE 2015-12-07:  You can now run the SCST setup scripts from '~/Downloads/orabuntu-lxc-master/scst-files/' directory!  
```
tar -xvf scst-files.tar
cd scst-files
Run the create-scst-*.sh files in the order shown below.
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-1a.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-1b.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-1c.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-1d.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-2a.sh (host reboots into SCST kernel at script end)
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-2b.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-3.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-4a.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-4b.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-5a.sh
  ~/Downloads/orabuntu-lxc-master/scst-files/create-scst-5b.sh (host reboots at script end)
```
Once all these scripts have run the SCST SAN and LUNs will be ready for the Oracle Grid Infrastructure 12c install.

NOTE:  If you are going to create an Oracle RAC database, then you will need to login to the LXC container as the 'grid' user and run 'asmca' in the usual way and create the '+DATA' and '+FRA' diskgroups for the database before doing the Oracle database install.

Follow the instructions at the Google Sites page referenced above.

!!!==============================

Phase 3:  Administration of the LXC containers and the Oracle database and ASM

Connect to the containerized Oracle instances from your Ubuntu 15.x OS terminal using the following example strings after first installing Oracle Instantclient to Ubuntu 15.x using the instructions here:

https://sites.google.com/site/nandydandyoracle/technologies/lxc/docker-11gr2-ee-ul (installing instantclient subsection

(In what follows below the ORACLE_SID=VMEM1 for the database)
```
sqlplus sys/password@lxc1-scan.gns1.orabuntu-lxc.com:1521/VMEM1 as sysdba  (for sys connection)
sqlplus system/password@lxc1-scan.gns1.orabuntu-lxc:1521/VMEM1             (for system connection)
```
To manage the LXC containers from the Ubuntu host command line:
```
sudo lxc-stop -n ora67c10
sudo lxc-start -n ora67c10
sudo lxc-console -n ora67c10 
sudo lxc-ls -f 
```
NOTE:  I will be adding the instantclient install to the scripted solution soon.



