# orabuntu-lxc
Oracle Enteprise Edition Software on Ubuntu Linux using LXC Containers.
This software runs Oracle Enteprise Edition RAC database on Ubuntu 15.04 64-bit Desktop Edition using Oracle Enteprise Linux 6.5 LXC Containers.  Install on a fresh install of 15.04 only.

Technology Platforms:

  isc-dhcp-server

  bind9

  openvswitch

  lxc

Screenshots and additional information can be found at the following Google Site:

https://sites.google.com/site/nandydandyoracle/technologies/lxc/oracle-rac-6-node-12c-gns-asm-flex-cluster-ubuntu-15-04-install

UNZIP THE DOWNLOADED ZIP IN THE ~/Downloads DIRECTORY!  This means that when you download this github zip file it will be here:

  ~/Downloads/orabuntu-lxc-master.zip

when the file is unzipped it will create the following directory:

  /home/oracle/Downloads/orabuntu-lxc-master

Therefore, because of the way the scripts are designed, you need to do the following:

  cd /home/oracle/Downloads/orabuntu-lxc-master

  cp -p * ../.

Phase 1:  Create the LXC Containers for Oracle 12 RAC ASM Flex Cluster

Run the ubuntu-services-*.sh files in the order shown below.

  ubuntu-services-1.sh  (host will reboot after this script)

  ubuntu-services-2a.sh (host will reboot after this script)

  ubuntu-services-2b.sh (host will reboot after this script)

  ubuntu-services-3a.sh

  ubuntu-services-3b.sh

  ubuntu-services-3c.sh

  ubuntu-services-3d.sh

The above steps will create the Oracle Enterprise Edition 6.5 LXC oracle-ready containers.


Phase 2:  Create the SCST Linux SAN LUNs for Oracle Grid Infrastructure

tar -xvf scst-files.tar

cd scst-files

Run the create-scst-*.sh files in the order shown below.

  create-scst-1a.sh

  create-scst-1b.sh

  create-scst-1c.sh

  create-scst-1d.sh

  create-scst-2a.sh (host will reboot after this script to boot into new SCST kernel)

  create-scst-2b.sh

  create-scst-3.sh

  create-scst-4a.sh

  create-scst-4b.sh

  create-scst-5a.sh

  create-scst-5b.sh

Once all these scripts have run the SCST SAN and LUNs will be ready for the Oracle Grid Infrastructure 12c install

Follow the instructions at the Google Sites page referenced above.

