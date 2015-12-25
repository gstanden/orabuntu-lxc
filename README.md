# orabuntu-lxc

Any Oracle on Any Linux at bare-metal resource utilization with density and elasticity 10X+ hypervisor-based systems.

Oracle Enterprise Edition Software on Ubuntu Linux using Oracle Enterprise Linux (OEL) LXC Containers.
This software runs Oracle Enteprise Edition RAC database on Ubuntu 15.04 or 15.10 64-bit Desktop Edition using Oracle Enteprise Linux 6.5 LXC Containers.  Additional instructions for an install of Oracle 12c (12.1.0.2.0) RAC ASM Flex Cluster using GNS are provided at the 'nandydandyoracle' website ( https://sites.google.com/site/nandydandyoracle ).

One can think of orabuntu-lxc as a sort of Oracle Enterprise Linux 'emulation layer' for Ubuntu Linux, although it is much more than just that.

Why Linux Containers ?

The Oracle Enterprise Edition 6.5 LXC Linux containers run at bare metal resource utilization for network, storage, and CPU with NO hypervisor performance penalty.  That is because LXC does NOT use a hypervisor.  Every container accesses all compute resources at bare-metal utilization and speed.  Also, because there is NO hypervisor, LXC Linux containers achieve 10x the density of hypervisor-based systems per unit compute resource.  Because LXC Linux containers deploy in seconds instead of hours or days, LXC Linux containers also achieve huge improvements in elasticity compared to hypervisor-based systems, because they can be spun up in seconds as needed.  

Install on a FRESH INSTALL of 15.04 or 15.10 ONLY. I have not bulletproofed this for install on "been-running-for-awhile" deployments of Ubuntu.  It could overwrite stuff so review the scripts VERY carefully first if you are going to put this on an Ubuntu 15.x that you have been using for a long time that is already customized. 

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
!!! IMPORTANT PLEASE READ !!!
=============================

Phase 1:  Create the LXC Oracle Enteprise Linux (OEL 5.x, OEL 6.x, or OEL 7.x) containers

To install:

1. Download the zip file from https://github.com/gstanden/orabuntu-lxc to your ~/Downloads directory on Ubuntu 15.x
2. Unzip the zip file which will create the directory ~/Downloads/orabuntu-lxc-master
3. Change directory to ~/Downloads/orabuntu-lxc-master
4. Run the script ubuntu-services.sh with your desired parameters (see usage notes below).
5. Run ONLY on fresh install of Ubuntu 15.04 or 15.10 !
6. Run the script ~/Downloads/orabuntu-lxc-master/ubuntu-services.sh (note, it's a fully-automated, slightly-interactive)

Note 1: Oracle Enterprise Linux (OEL) OEL5, OEL6 and OEL7 LXC Linux Containers are supported.

!!! =============================

About the ubuntu-services.sh script.

The ubuntu-services.sh script is a master script which runs all of the below scripts automatically.  

When you run the scripts the first time, just accept the default answers to the prompts about terminating DHCP leases and destroying containers.  The defaults, in order, are "Y", "Y", "N" and the questions are "Terminate Leases ?", "Destroy Existing Containers?", and "Destroy only a specific container ?" respectively.  Just take the defaults on all 3 questions when installing the software for the first time.

!!! =============================

Run ~/Downloads/orabuntu-lxc-master/ubuntu-services.sh script first.  

Usage is shown below:

~/Downloads/orabuntu-lxc-master/ubuntu-services-1.sh 6 7 5 orabuntu-lxc\\.com stlns01

"6 7" is the major and minor release version of the OEL Linux that you wish to use for building your LXC containers.
Typical values would by "6 5" (for OEL 6.5) or "5 9" (for OEL 5.9).  Choose the OEL 5.x, 6.x, 7.x release that you want.

"5" is the number of cloned containers of that release of OEL to be created from the fully oracle-ready configured seed container.

"orabuntu-lxc\\.com" is the name of the domain for your container network.  Choose the domain that you want. It can be of the form "somedomain\\.com" or "somedomain\\.net" etc., and it can also be of the form "corp\\.somedomain\\.com" but just be sure to put the backslash in front of any "." characters because the domain gets post-processed by sed and the "." needs to be escaped in the passed-in domain parameter.

"stlns01" is the name of your nameserver for your domain.  Choosed the name that you want. This server name will get the "10.207.39.1" IP address and it will have the nslookup name "stlns01.yourdomain.com".

"ora$1$2c" is the LXC container name prefix.  For the parameters shown above, the script will create 4 LXC containers with the names {ora67c10, ora67c11, ora67c12, ora67c13} assuming that you created the OEL 6.7 containers on the first run (numbering always starts at "10" so as not to run afoul of a bug in 12.1.0.2.0 that affects server names that do not have the same number of character counts (ora67c1 vs ora67c10).

So inside the ubuntu-services.sh script we have:

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

KEEP IN MIND WHEN READING THE USAGE NOTES BELOW THAT IT IS STRONGLY ADVISED IN THE STERNEST TERMS TO ONLY INSTALL THIS SOFTWARE ON A FRESH INSTALL OF UBUNTU 15.10 OR 15.04 AND NOT TO INSTALL THIS ON A HIGHLY-CONFIGURED UBUNTU DESKTOP OR SERVER THAT HAS BEEN RUNNING FOR A LONG TIME WITH MANY CUSTOM-CONFIGURATIONS ALREADY IMPLEMENTED.  DOING SO IS AT YOUR OWN RISK.  THIS SOFTWARE MAKES CHANGES TO DHCP AND BIND9 (NAMED) CONFIGURATIONS SO IT COULD DISRUPT LOOKUPS AND NAME RESOLUTIONS ON AN ALREADY-BEEN-RUNNING-FOR-AWHILE UBUNTU HOST!

NOTE 1: Creating additional containers after the initial run with different OEL version:  You can rerun the ubuntu-services.sh script with a new version paramters (e.g. "7 1") The indexes of the add-on second run of container creation will start from the next highest index, so if you ran "6 7 5 orabuntu-lxc\\.com stlns01" as your first run ubuntu-services.sh parameters, and then ran "7 1 2 orabuntu-lxc\\.com stlns01" as your second run parameters, you would get the following list of containers:

oel67

oel71

ora67c10

ora67c11

ora67c12

ora67c13

ora67c14

ora67c15

ora71c16

ora71c17

NOTE 1: The first run produces n+1 containers (one more than requested) due to a bug I will fix soon.  Workaround is just to request n-1 when you really want n for the first run.

NOTE 2:  If you do a second run of ubuntu-services.sh to create additional containers of a different OS version, be aware that the software looks for the file "/etc/orabuntu-release" and if found, it skips some of the setup steps (such as package installs and the unpack of ubuntu-host.tar) since those steps were already done on the first pass, and it proceeds pretty much directly to the creation of the new seed container.  Be sure on second, third, fourth runs to be sure to answer "N", "N" to "Terminate Leases" and "Destroy Containers" because these are the answers which will preserve your existing containers, and simply add the new containers to the deployment without destroying any existing containers.

NOTE 3:  Note that the seed containers (oel67, oel65, oel59, ...) get created on the 10.207.29.x network, while the cloned containers to be used for actual projects get created on the 10.207.39.x network.  Do not install Oracle Enterprise softwares into the oelxx containers, because these are your fully-configured, oracle-ready SEED containers which you can clone later to make more oracle-ready containers of that specific OEL version if you need more.  Support for user-settable subnets is coming soon!

NOTE 4:  When re-running the software, you are prompted early on to delete DHCP leases (Y/N) and to delete existing containers (Y/N).  If running the software a second time as mentioned above to create another set of containers of a different OS version, answer "N" to the questions about terminating leases and deleting containers so that your first run of containers is not destroyed, nor the first SEED container.

NOTE 5:  The DHCP lease delete steps and the container delete steps are useful if you run the whole set of scripts for the first time, and you run into some problem and want to start completely over.  In that case, answer "Y" to deleting DHCP leases, answer "Y" to delete containers, and answer "N" to "delete only the oelxx SEED container" so that the result will be ALL DHCP leases deleted, and ALL containers deleted, so that you are starting from scratch again.  Also, be sure before re-running "from scratch again" to DELETE the file "/etc/orabuntu-release" using "sudo rm /etc/orabuntu-release" so that the software executes ALL OS configuration steps again on the re-run of the first install.

BUG 1:  Note that on the first run of the software, the scripting creates one extra container above what you specify.  So if you specify to create 3 containers, it will actually create 4 for you.  I'll get this cleaned up in a day or two. On subsequent re-runs of the script, the container quantity will match exactly what you specify.  The workaround is to specify n-1 containers on the first run in order to get the desired "n" containers from the first run!

!!! =============================

Phase 2:  Create the SCST Linux SAN LUNs for Oracle Grid Infrastructure

This Phase 2 is OPTIONAL.  You will need storage LUNs for your Oracle Grid Infrastructure (GI) and your Oracle Database so this module creates file-backed LUNs and the SCST custom kernel providing a SAN for the containers.

You can opt to use other solutions for file-backed storage such as Linux TGT.  I will be developing an automated Linux TGT SAN script package to go with this project, but that is on the roadmap only for now.  Linux TGT is much simpler to implement and does not require a custom Linux kernel.  

The main reason for choosing SCST Linux SAN is that SCST supports native 4K format with no 512-byte emulation layer, so SCST is useful for testing both 4K and 512-byte native format storage with various Oracle database softwares.  If you will not need 4K native support, TGT is probably a much simpler choice since it does not require a custom kernel.  Note however that SCST is one of the most feature-rich Linux SAN solutions and is used in versions of commercial products such as some Kaminario all-flash SANs and some Violin Memory all-flash SANs. Because SCST is much more difficult to implement, I created the scripts to automatically build SCST for you, since guides to implement SCST on Ubuntu Linux are hard to find on the internet, while Linux TGT SAN guides are readily available and good.  My scripts are a scripted automation of the manual steps of the amazingly accurate and awesome guide that Chris Weiss created here:  

https://gist.github.com/chrwei/42f8bbb687290b04b598

Without the great work by Chris Weiss sharing this method publicly, my scst-files.tar archive for automatically building SCST SAN for Oracle on Ubuntu Linux would simply not exist.  If you run into bugs or script failures on your hardware for my scripts, please send me the error information to gilstanden@hotmail.com .  My scripts create the SCST custom kernel, create the SCST target and LUNs, and also build the /etc/multipath.conf file and install it automatically.  It's likely that some issues might be encountered on various hardware at the /etc/multipath.conf creation step, so if you hit issues with that step, I'd like to know about it if you have time to send details.

IMPORTANT:  Whatever storage solution you use, your storage LUNs will appear in '/dev/mapper/' directory with multipath friendly names that have 'asm*' as the prefix of the friendly name, because multipath "friendly names" with the "asm" prefix is how my scripts prepare storage for presentation to Oracle.  So if you are using an actual SAN solution such as Tegile, Violin Memory, Dell, IBM, etc. my SCST install scripts will get the wwid of your LUNs and assign multipath friendly names to them with an 'asm' prefix, such as for exmaple:

/dev/mapper/asm_systemdg_00' 

which of course will actually refer to a /dev/dm- device.  If you are on Ubuntu 15.10, the storage will be a symlink in /dev/mapper to the /dev/dm-* device, or, if you are on Ubuntu 15.04 the storage will 'usually' be a device node (no symlink) in /dev/mapper but note that in Ubuntu 15.04 the disposition of multipath storage in /dev/mapper can sometimes be a mix of device nodes and symlinks as shown for example below:

gstanden@W1504:~$ ls -l /dev/mapper

brw-rw---- 1 grid asmadmin 252,   2 Dec  8 11:29 asm_fra1_01

lrwxrwxrwx 1 grid asmadmin        7 Dec  8 11:07 asm_fra1_02 -> ../dm-5

NOTE:  The orabuntu-lxc software can handle both (a) actual device nodes in /dev/mapper and (b) symlinks in /dev/mapper and so mixtures of both device nodes and symlinks is fine.  The only requirement for my scripting is that the storage for Oracle in /dev/mapper have the 'asm*' prefix.  Both of the above forms of storage presentation in /dev/mapper (symlink or device node or mixtures of both) are fine no problems.

UPDATE 2015-12-07:  You can now run the SCST setup scripts from '~/Downloads/orabuntu-lxc-master/scst-files/' directory!  

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

Once all these scripts have run the SCST SAN and LUNs will be ready for the Oracle Grid Infrastructure 12c install.

NOTE:  If you are going to create an Oracle RAC database, then you will need to login to the LXC container as the 'grid' user and run 'asmca' in the usual way and create the '+DATA' and '+FRA' diskgroups for the database before doing the Oracle database install.

Follow the instructions at the Google Sites page referenced above.

!!!==============================

Phase 3:  Administration of the LXC containers and the Oracle database and ASM

Connect to the containerized Oracle instances from your Ubuntu 15.x OS terminal using the following example strings after first installing Oracle Instantclient to Ubuntu 15.x using the instructions here:

https://sites.google.com/site/nandydandyoracle/technologies/lxc/docker-11gr2-ee-ul (installing instantclient subsection)

sqlplus sys/password@lxc1-scan.gns1.vmem.org:1521/VMEM1 as sysdba  (for sys connection)

sqlplus system/password@lxc1-scan.gns1.vmem.org:1521/VMEM1         (for system connection)

To manage the LXC containers from the Ubuntu host command line:

sudo lxc-stop -n oel71c15

sudo lxc-start -n oel59c10

sudo lxc-console -n oel67c21 

sudo lxc-ls -f 

NOTE:  I will be adding the instantclient install to the scripted solution soon.



