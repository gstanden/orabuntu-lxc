# orabuntu-lxc
Oracle Enterprise Edition Software on Ubuntu Linux using LXC Containers.
This software runs Oracle Enteprise Edition RAC database on Ubuntu 15.04 or 15.10 64-bit Desktop Edition using Oracle Enteprise Linux 6.5 LXC Containers.  

Install on a FRESH INSTALL of 15.04 or 15.10 ONLY. I have not bulletproofed this for install on a been-running-for-awhile Ubuntu.  It could overwrite stuff. 

I have NOT tested this yet on Ubuntu 12.x, 13.x, or 14.x.

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

Due to sloppy hardcoded references to "/home/gstanden" etc. in the scripting, please read the following carefully:

Due to some script which references the 'gstanden' Ubuntu OS account, this version of the scripts must be run while logged in as the 'gstanden' user and must be run from the /home/gstanden/Downloads/orabuntu-lxc-master directory.

There are two ways to address this hardcoding references problem.  

The first way is to do a fresh install of Ubuntu 15.04 or 15.10 and create the default user to be 'gstanden' and then just do the install starting from 'ubuntu-services-1.sh' script.

The second way is to use the 'ubuntu-services-0.sh' file which creates a 'gstanden' user for the install.

Whichever way is used, it is required for this release of the software with the hardcoded references problem that you be logged in as 'gstanden' OS user account, and that the scripts be located in '/home/gstanden/Downloads' directory and be run from that location.  Note that simply creating a '/home/gstanden' directory without the 'gstanden' user won't work.  You need both the user 'gstanden' and the '/home/gstanden/Downloads' directory in order for the scripts to install successfully with this release of the scripts.  I am working to remove this problem and remove all the hardcoded references and user dependencies and hope to release those updates very soon so that the 'gstanden' user will not be a requirement to run the scripts.

Note also that whichever workaround is used, the scripts MUST be run from '/home/gstanden/orabuntu-lxc-master/' directory.  Note that that is an UPDATE 2015-12-06 that the scripts for the container creation are to be run from /home/gstanden/orabuntu-lxc-master directory (previously it was /home/gstanden/Downloads but that has been fixed so that the scripts can now be run from the orabuntu-lxc-master subdirectory of Downloads).

Therefore, after downloading and unzipping the github archive, you MUST run 'ubuntu-services-0.sh' first from whatever username you are logged in as.  For example, if you were logged in as "jsmith" you would run the ubuntu-services-0.sh file from the path:

/wherever-you-downloaded/orabuntu-lxc-master/ubuntu-services-0.sh

for a user 'jsmith' typically this would be:

/home/jsmith/Downloads/orabuntu-lxc-master/ubuntu-services-0.sh

The ubuntu-services-0.sh script will create the 'gstanden' user, grant it 'sudo' privilege, and will put all the orabuntu-lxc scripts into the '/home/gstanden/Downloads' directory and then it will reboot the Ubuntu host.

Log back in after reboot as 'gstanden' user.

Then cd to '/home/gstanden/Downloads'.

Then start the install with 'ubuntu-services-1.sh'.

NOTE:  Some of the scripts reboot the Ubuntu OS.  Be sure to login as the 'gstanden' user after each reboot to run the next script! 

!!! =============================
 
  /home/your-username/Downloads/orabuntu-lxc-master/ubuntu-services-0.sh 

  This creates the 'gstanden' account. 

  This is a fix for sloppy hardcoding.

!!! =============================

Update 2015-12-06:  There are no reboots anymore.  You just run all the scripts.  There is a new script too:

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services.sh
  
and this new script is a master script which runs all of the below scripts automatically.  Note that all of the scripts are individually re-runnable, and the whole set of scripts is also re-runnable, so if you have a failure of one script for any reason, just fix the problem, and re-run that script.  If you want to re-run the whole set of scripts, just re-run ubuntu-services.sh again to re-run them all.  Note also the ubuntu-services-3d.sh takes a parameter integer that is the number of containers to create.  Edit ubuntu-services.sh to set the parameter for ubuntu-services-3c.sh.

UPDATE:  You just run the file '/home/gstanden/Downloads/orabuntu-lxc/ubuntu-services.sh' to do the install.  

  This is where the software proper begins.

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-1.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-2a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-2b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3a.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3b.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3c.sh

  /home/gstanden/Downloads/orabuntu-lxc-master/ubuntu-services-3d.sh

The above steps will create the Oracle Enterprise Edition 6.5 LXC oracle-ready containers.

!!! =============================

Phase 2:  Create the SCST Linux SAN LUNs for Oracle Grid Infrastructure

UPDATE 2015-12-06:  You STILL must run the SCST setup from '/home/gstanden/Downloads/scst-files/' directory.  I'm working to adjust the paths for the SCST setup, but have not gotten to it yet.  But at least you don'd have to move all the scripting into your ~/Downloads directory anymore! Progress!

tar -xvf scst-files.tar

cd scst-files

Run the create-scst-*.sh files in the order shown below.

  /home/gstanden/Downloads/create-scst-1a.sh

  /home/gstanden/Downloads/create-scst-1b.sh

  /home/gstanden/Downloads/create-scst-1c.sh

  /home/gstanden/Downloads/create-scst-1d.sh

  /home/gstanden/Downloads/create-scst-2a.sh (host will reboot after this script to boot into new SCST kernel)

  /home/gstanden/Downloads/create-scst-2b.sh

  /home/gstanden/Downloads/create-scst-3.sh

  /home/gstanden/Downloads/create-scst-4a.sh

  /home/gstanden/Downloads/create-scst-4b.sh

  /home/gstanden/Downloads/create-scst-5a.sh

  /home/gstanden/Downloads/create-scst-5b.sh (host will reboot after this script).

Once all these scripts have run the SCST SAN and LUNs will be ready for the Oracle Grid Infrastructure 12c install

Follow the instructions at the Google Sites page referenced above.

# NOTE:  I am working to fix the hardcoded 'gstanden' problem and I am also working to remove all the reboot steps and to package this as a .deb package.


