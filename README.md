# orabuntu-lxc
Oracle Enteprise Edition Software on Ubuntu Linux using LXC Containers.
This software runs Oracle Enteprise Edition RAC database on Ubuntu 15.04 64-bit Desktop Edition using Oracle Enteprise Linux 6.5 LXC Containers.  Install on a fresh install of 15.04 only.

NOTE:  My email is gilstanden@hotmail.com if you hit bugs or issues or have questions!

Technology Platforms:

  isc-dhcp-server

  bind9

  openvswitch

  lxc

Screenshots and additional information can be found at the following Google Site:

https://sites.google.com/site/nandydandyoracle/technologies/lxc/oracle-rac-6-node-12c-gns-asm-flex-cluster-ubuntu-15-04-install

=============================================================
!!! IMPORTANT PLEASE READ !!!
=============================================================

Due to sloppy some hardcoded references to "/home/gstanden" etc. in the scripting, please read the following carefully:

Due to some script which references the 'gstanden' Ubuntu OS account, this version of the scripts must be run while logged in as the 'gstanden' user and must be run from the /home/gstanden/Downloads directory.

Therefore, after downloading and unzipping the github archive, you MUST run 'ubuntu-services-0.sh' first.

The ubuntu-services-0.sh script will create the 'gstanden' user, grant it 'sudo' privilege, and will put all the orabuntu-lxc scripts into the '/home/gstanden/Downloads' directory and then it will reboot the Ubuntu host.

Log back in after reboot as 'gstanden' user.
Then cd to '/home/gstanden/Downloads'.
Then start the install with 'ubuntu-services-1.sh'.

!!! ==============================================================
 
  /home/your-username/Downloads/orabuntu-lxc-master/ubuntu-services-0.sh 

  This creates the 'gstanden' account. 

  This is a fix for sloppy hardcoding.

!!! ==============================================================

  This is where the software proper begins.

  /home/gstanden/Downloads/ubuntu-services-1.sh  (host will reboot after this script)

  /home/gstanden/Downloads/ubuntu-services-2a.sh (host will reboot after this script)

  /home/gstanden/Downloads/ubuntu-services-2b.sh (host will reboot after this script)

  /home/gstanden/Downloads/ubuntu-services-3a.sh

  /home/gstanden/Downloads/ubuntu-services-3b.sh

  /home/gstanden/Downloads/ubuntu-services-3c.sh

  /home/gstanden/Downloads/ubuntu-services-3d.sh

The above steps will create the Oracle Enterprise Edition 6.5 LXC oracle-ready containers.

!!! ==============================================================

Phase 2:  Create the SCST Linux SAN LUNs for Oracle Grid Infrastructure

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

  /home/gstanden/Downloads/create-scst-5b.sh

Once all these scripts have run the SCST SAN and LUNs will be ready for the Oracle Grid Infrastructure 12c install

Follow the instructions at the Google Sites page referenced above.

# NOTE:  I am working to fix the hardcoded 'gstanden' problem and I am also working to remove all the reboot steps and to package this as a .deb package.


