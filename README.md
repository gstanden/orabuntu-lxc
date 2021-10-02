# What is Orabuntu-LXC/D 7.0.0-alpha ELENA ?

Announcing Orabuntu-LXC/D v7.0.0-alpha ELENA ("**E**nterprise **L**XD **E**dition **N**ew **A**MIDE") available now (in MASTER branch only) introducing support for fully-automated N-node LXD cluster creation on all Orabuntu-LXC/D supported distros (CentOS, Fedora, RedHat, Ubuntu, and Oracle Linux). The github will continue to be known as "Orabuntu-LXC" but the [logo](https://github.com/gstanden) has been updated with "Orabuntu-LXD" to communicate LXD cluster support.

New features of Orabuntu-LXC/D v7.0.0-alpha ELENA:

* Automated LXD N-node clusters over OpenvSwitch VLAN's on CentOS, Fedora, RedHat, Ubuntu and Oracle Linux.
* User-selectable tunnel-type for multi-host deployments [ gre | geneve | vxlan ].
* New /anylinux/CONFIG file which centralizes deployment configuration parameters.
* Adds support for nftables and firewalld for LXD clusters and LXC multi-host "spanned" networks.
* Continues to offer option of LXC networks spanned across multiple hosts, as well as the new LXD cluster option
* Numerous improvements and enhancements

Orabuntu-LXC/D ELENA BUILDS EVERYTHING itself for the currently supported distros: 

* Oracle Linux 6.x, 7.x, 8.x
* Ubuntu 16.04+ (16.04 and all higher versions)
* CentOS 6.x, 7.x, 8.x
* Fedora 22-35+ (tested on 22, 24, 29, 33 and 34)
* RedHat 6.x, 7.x, 8.x

**Note 1**:  Linux 6 support cannot be guaranteed due to de-support of Linux 6 by Linux vendors. Still supported but on a "best effort" basis only.

**Note 2**:  Orabuntu-LXC SCST deployer support: de-support pending for kernels older than 2.6 (notified by SCST maintainers).

**Note 3**:  LXD options NA for Linux 6 all distros, NA for Ubuntu 16.04, and NA for Fedora 22-28; these hosts LXC option only.
       
**Orabuntu-LXC/D ELENA installer does all of the following automatically**:

* Automatically detects your OS and branches to the appropriate build pathway
* Builds/Deploys OpenvSwitch as RPM or DEB packages and builds RPM or DEB packages from source if necessary
* Builds the OpenvSwitch Network
* Configures VLANs on the OpenvSwitch Network
* Connects the OpenvSwitch network physical host interfaces using nftables or iptables rules
* Builds/Deploys LXC as RPM or DEB packages and builds LXC RPM or DEB packages from source if necessary
* Creates an LXC-containerized replicated Ubuntu Focal 20.04 DNS/DHCP container running bind9 and isc-dhcp-server (see **Note 1** below)
* Replicates the LXC-containerized DNS/DHCP container to all Orabuntu-LXC physical GRE-connected hosts
* Optionally stores LXC-containerized DNS/DHCP updates at Amazon S3 for replication
* Automatically detects filesystem types which support lxc-snapshot overlayfs for LXC-containerized DNS/DHCP
* Updates the LXC-containerized DNS/DHCP container replicas with the latest zone and lease updates every x minutes.
* Configures multi-host **using user-selectable tunnel-type of [ geneve | vxlan | GRE ]**
* **Optionally automatically creates the LXD cluster**
* Builds the LXC **or LXD containers**
* Configures all OpenvSwitch switches and LXC or **LXD** containers as systemd services
* Configures gold copy LXC or **LXD** containers (on a separate network) according to your specifications
* Creates clones of the gold copy LXC or **LXD** containers
* Builds SCST Linux SAN from source code as RPM or DKMS-enabled DEB packages
* Creates the target, group, and LUNs according to your specifications
* Creates the multipath.conf file and configures multipath
* Present LUNs in 3 locations, including a container-friendly non-symlink location under /dev/lxc_luns
* Present LUNs to containers directly, only the LUNs for that container, at full bare-metal storage performance.

**Note 1** CentOS 7 and RedHat 7 use Ubuntu Hirsute 21.04 for the LXC containerized replicated DNS/DHCP. See [discussion thread here](https://discuss.linuxcontainers.org/t/no-dhcp-request-on-centos7/12253)

**Note 2** All Orabuntu-LXC supported distros and releases were tested on freshly installed systems using LVM.  If you install on existing machines it is possible unforseen issues could arise during the Orabuntu-LXC deployments.  Please open an issue at the Orabuntu-LXC github if you run into an issue on an existing machine.

Orabuntu-LXC does all of this and much more with just these easy steps:

Step 0

Create a physical host or VM host of CentOS, Fedora, Redhat, Ubuntu or Oracle Linux.  Use of LVM when building the host is strongly recommeded so that the optional Orabuntu-LXC fully-automated SCST Linux SAN deployer can be fully-leveraged after the LXC or LXD N-node hosts have been deployed.

Step 1

Make sure your Linux distribution is updated.  

On Debian-family Linuxes this is:

```
sudo apt-get -y update
sudo apt-get -y upgrade
```

On Redhat-family Linuxes this is:

```
sudo yum -y update ("older" distro releases)
sudo dnf -y update ("newer" distro releases)
```

Step 2

Install manually the following packages (if on Debian-family Linux):

```
sudo apt-get -y install unzip wget openssh-server net-tools bind9utils
```
Install manually the following packages (if on RedHat-family Linux):
```
sudo [yum|dnf] -y install unzip wget openssh-server net-tools bind-utils
```

Step 3a

Download the latest Orabuntu-LXC 7.0.0-alpha ELENA release (as of September 26, 2021 this is in MASTER branch only) to 

"/home/username/Downloads" 

and unzip it, then navigate to the "anylinux" directory. **Note** that the software can be downloaded to any directory owned by the install user; the "Downloads" directory is just a recommended download destination.

Step 3b

If a non-root administrative user is not available on the host, create it with the appropriate script:
```
./uekulele/uekulele-services-0.sh (RedHat-family linuxes)
./orabuntu/orabuntu-services-0.sh (Ubuntu-family linuxes)
```

**Note 1:** The linux user account used to install Orabuntu-LXC must have "sudo ALL" privilege.  On Ubuntu Linux this is typically the "ubuntu" user.  For CentOS, Fedora, RedHat and Oracle Linux, use the "./uekulele/uekulele-services-0.sh" script.  The script by default creates the "orabuntu" user with all required sudo privileges and required directories, but the script can be edited to use any arbitrary user-settable username. I typically edit the file and create "ubuntu" user on the RedHat-family linuxes as my installer account because I develop Orabuntu-LXC on an Ubuntu physical host running CentOS, Fedora, RedHat and Oracle Linux VM's in VirtualBox, so using an "ubuntu" linux user throughout simplifies interoperability between the Ubuntu host and the VM guests, but you can create an install user with any username.  

**Note 2:** the uekulele-services-0.sh script by default sets the linux install user password to the same as username ("ubuntu/ubuntu") but there is a random password generator in the uekulele-services-0.sh script so edit the script to use the random password generator for security if desired.

Step 4

Edit the **/anylinux/CONFIG** file to select either LXC or LXD. For example, to select LXD clusters, set the following parameters in the CONFIG file as shown below. It's highly-recommended to set both of these parameters to "Y" as a pair because even if deploying a single LXD node, this creates the single server as a "one-node LXD cluster" which makes the single-node LXD "cluster-ready" so that another node can be easily added later if desired, since the clustering is already setup. In the case of HUB HOST the LXDCluster=Y switch creates a "single-node" LXD cluster, and in the case of GRE HOST an "N-node" LXD cluster depending on how many GRE hosts have been added to the cluster.
```
LXD=Y
LXDCluster=Y
```
If instead LXC containers (not LXD) multi-host span is desired, set both of these parameters to "N".

Step 5

Edit other install parameters in the **/anylinux/CONFIG** file as desired or required.

Step 6

**Note 1:** if LXD=Y and LXDCluster=Y are selected, it will be necessary to first create the required ZFS storage pool for the LXD cluster.  The naming convention olxc-001 (for HUB node) and optionally olxc-00[2,3,4 ...] (for GRE node if creating N-node LXD Cluster) etc is suggested, but any arbitrary user-settable naming scheme can be used in the ./anylinux/CONFIG file for naming the ZFS storage pools.

**Note 2:** When clustering with v7.0.0-**alpha** ELENA it is strongly recommended to REBOOT each node after Orabuntu-LXC has completed before moving on to the next LXD cluster node or LXC multi-host node to be installed with Orabuntu-LXC. For example the first node for Fedora 34 needs a reboot to assign ip addresses to the clone containers.  These requirement to reboot the first cluster node before installing additional nodes will be REMOVED before the actual release of v7.0.0-alpha ELENA but for now when using this alpha in the master branch, reboot of first node before moving on to install LXD cluster nodes is strongly recommended to ensure the first node remains and/or is fully configured across reboots.

To create the ZFS storage pools, add /dev/sdb and /dev/sdc storage, and then create the ZFS storage pool.  For Oracle Linux, scripts to fully automate the creation of the required olxc-001 zfs pool are located as shown below.  The script takes a single command line parameter which is the name of the ZFS storage pool to be created.  For example if the name of the storage pool is "olxc-001" the script to install ZFS and create the storage pool would be as shown below.
```
zfsutils/oracle/zpool_oracle7_uek.sh olxc-001
zfsutils/oracle/zpool_oracle8_uek.sh olxc-001
```
The scripts can be edited to use other than (/dev/sdb + /dev/sdc) for example (/dev/sdg + /dev/sdk).  

There are scripts in distro subdirectories to create the required ZFS storage pools for all supported Orabuntu-LXC distros (CentOS, Fedora, RedHat, Ubuntu and Oracle Linux).

Step 7

The ipaddress subnets still need to be edited in "./anylinux/anylinux-services.sh" script.  Edit that file and search for "pgroup1" and then set the ip address subnets as desired.  Settings for SeedNet and BaseNet are required (default is 172.29.108 and 10.209.53) but they can be set to arbitrary ipv4 subnets.  The StorNet# nets are optional but should have a value in them.  They are also set to defaults but can be set to any arbitrary value.  The StorNet# are used when additional networks are needed, such as for Oracle Database RAC, or iSCSI dedicated storage network, etc., and the StorNet# are only invoked if $Product is set to products other than the default product setting of "Product=no-product".

Other than pre-creating the olxc-001 on the HUB host and the olxc-00[2,3,4,...] on the GRE host, the Orabuntu-LXC main scripts
```
anylinux-services.HUB.HOST.sh new
anylinux-services.GRE.HOST.sh new
```
are still totally automated as just as they have always been, and the scripts are a "one-button push" fully-automated way to create the containers and networks just the same as the way they work for LXC deployments.

If LXC containers are preferred, then set these two parameters as a pair to "N" shown below. 
```
LXD=N
LXDCluster=N
```
Also in the /anylinux/CONFIG file select whether Oracle Linux 8.4 or Oracle Linux 7.9 containers as shown below.
```
MajorRelease=8
PointRelease=4
```
Step 8

Run the HUB HOST script (as a **NON-root** "administrative" user with "SUDO ALL" privilege or "wheel" privilege) the following script:

```
./anylinux-services.HUB.HOST.sh new
```

**Note**: After the script finishes, if you have set LXD=Y and LXDCluster=Y then **you will need to log out/log back in again to host server to have access to commands like "lxc list" "lxc cluster list" etc.**

Otherwise, that's it. It runs fully-automated and delivers LXC networks spanned via OpenvSwitch SDN networks across multiple hosts, **or now alternatively an LXD cluster** container infrastructure across multiple hosts via OpenvSwitch SDN networks. There are optional switches in the CONFIG file to deploy Docker snap and microk8s snap.  Currently, the LXD cluster features of Orabuntu-LXC only supports ZFS storage pools.  

If, on the other hand, it is desired to further customize Orabuntu-LXC, it is highly-flexible and configurable using the parameters in the file: 

```
/anylinux/CONFIG
```
including support for any two separate user-selectable IP subnet ranges, and 2 user-selectable domain names, and much more. One network, for example the "SeedNet" network can also be used as an out-of-band maintenance network, and the other network used for production containers.

With the replicated and constantly updated LXC containerized DNS/DHCP solution, GRE-connected hosts (such as developer laptops) can be disconnected from the network and still have full DNS/DHCP lookup services for any containers stored locally on the developer laptop.  Plus, containers that are added by the developer after detachment from the Orabuntu-LXC network will be added to the local copy of the LXC containerized DNS/DHCP.

**Note**: I haven't done any work recently with the "Amazon Cloud" part of the project, and currently only support LXC networks spanned across Ubuntu 16.04 EC2 containers.  Nothing has been done yet implementing the LXD Cluster features across Amazon EC2 instances.  Support for Orabuntu-LXC deployed LXD clusters on Amazon EC2 is on the roadmap! 

Step 9

To add other flavors of LXD container to the Orabuntu-LXC DHCP OpenvSwitch networks, after Orabuntu-LXC scripts have finished, and the system is fully-configured, simply choose the profile desired and then launch the container.  There are two user-settable networks created as previously mentioned.  The default networks for this example are 10.209.53.0/24 and 172.29.108.0/24 (but these are user-settable and can be changed prior to running Orabuntu-LXC they are BaseNet and SeedNet, respectively) which have LXD profiles "olxc_sw1a" and "olxc_sx1a" respectively.  So for example to add a Fedora 34 LXD container with DHCP networking to the 172.29.108.0/24 "sx1" "SeedNet" OpenvSwitch network run the follwing command as shown below.

```
[ubuntu@o83sv2 uekulele]$ lxc launch -p olxc_sx1a images:fedora/34 fed34d10
Creating fed34d10
Starting fed34d10                           
[ubuntu@o83sv2 uekulele]$ lxc listlxc config device add ora79d17 asm disk source=/dev/lxc_luns path=/dev/lxc_luns
+----------+---------+----------------------+------+-----------+-----------+----------+
|   NAME   |  STATE  |         IPV4         | IPV6 |   TYPE    | SNAPSHOTS | LOCATION |
+----------+---------+----------------------+------+-----------+-----------+----------+
| fed34d10 | RUNNING | 172.29.108.12 (eth0) |      | CONTAINER | 0         | o83sv1   |
+----------+---------+----------------------+------+-----------+-----------+----------+
```

Step 10

If using the optional SCST Linux SAN fully-automated deployer which is found in "/opt/olxc/home/scst-files" (absolute path may differ based on location of the original Orabuntu-LXC install stage) AFTER Orabuntu-LXC deployment has finished, then first run "/opt/olxc/home/scst-files/create-scst.sh"  and then when that completes successfully, use the following command to expose local host SCST Linux SAN LUNs to any given container on that SAME host. This would for example when creating an LXD containerized database such as an Oracle database using ASM that required storage LUNs. An example command is shown below.

```
lxc config device add ora84d10 asm disk source=/dev/lxc_luns path=/dev/lxc_luns
```

**Note 1** that the LUNs are available in three places on the LXD host:
```
/dev/mapper
/dev/asm
/dev/lxc_luns
```
and that the /dev/lxc_luns location is specially-designed so that the LUNs are "non-softlinked" so that the multi-path LUNs are available by simply exposing /dev/lxc_luns to the container with no need to also expose an endpoint of a LUN soft link as would be necessary if say /dev/mapper was exposed to the container.  Also note the the names "lxc_luns" and "asm" are user-settable and can be changed by the user in the scripts prior to launching the "create-scst.sh" script.

**Note 2** This is one of the reasons creating a "single-node" LXD cluster is strongly-recommended when only deploying Orabuntu-LXC on a single node.  The profiles (olxc_sw1a and olxc_sx1a) used in the "-p" switch of the "lxc config device add" statement are part of the LXD init cluster config preseed script and are built in to the LXD deployment when selecting "LXD=Y" AND "LXDCluster = Y" setting BOTH to "Y".  By also setting "LXDCluster = Y" the system will get the olxc_sw1a and olxc_sx1a scripts built-in ready to use for any additional non-Oracle Linux containers added to the networks, and, the single-node is built "cluster-ready" as previously noted in an earlier section above.

#  More Detailed: Install Orabuntu-LXC v7.0.0-alpha ELENA 

An administrative non-root user account is required (such as the install account). The non-root user needs to have "sudo ALL" privilege.

Be sure you are installing on an internet-connected LAN-connected host that can download source software from repositories which include yum.oracle.com, archive.ubuntu.com, SourceForge, etc.

On a Debian-family Linux, such as Ubuntu, this would be membership in the "sudo" group, e.g.
```
orabuntu@UL-1710-S:~$ id orabuntu
uid=1001(orabuntu) gid=1001(orabuntu) groups=1001(orabuntu),27(sudo)
orabuntu@UL-1710-S:~$ cat /etc/lsb-release 
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=17.10
DISTRIB_CODENAME=artful
DISTRIB_DESCRIPTION="Ubuntu 17.10"
orabuntu@UL-1710-S:~$ 
```
On a RedHat-family Linux, such as Fedora, this would be membership in the "wheel" group, e.g.
```
[orabuntu@fedora27 archives]$ id orabuntu
uid=1000(orabuntu) gid=1000(orabuntu) groups=1000(orabuntu),10(wheel)
[orabuntu@fedora27 archives]$ cat /etc/fedora-release 
Fedora release 27 (Twenty Seven)
[orabuntu@fedora27 archives]$
```
For Debian-family Linuxes the following script can be used to create the required administrative install user.
```
./orabuntu-services-0.sh
```
For RedHat-family Linuxes the following script can be used to create the required administrative install user.
```
./uekulele-services-0.sh
```
The first Orabuntu-LXC install is always the "HUB" host install. 

Install the Orabuntu-LXC HUB host as shown below (if installing an Orabuntu-LXC release). 
```
cd /home/username/Downloads/orabuntu-lxc-6.13.25.x-beta/anylinux
./anylinux-services.HUB.HOST.sh new
```
That's all. This one command will do the following:

    * Install required packages
    * Install or build LXC from source 
    * Install or build OpenvSwitch from source
    * Build the LXC containerized DNS/DHCP 
    * Detect filesystem type and use overlayfs technology if supported for LXC containerized DNS/DHCP
    * Build Oracle Linux LXC or LXD containers
    * Build the LXD cluster optionally
    * Build the OpenvSwitch networks (with VLANs)
    * Configure the IP subnets and domains specified in the anylinux-services.sh file
    * Put the LXC containers on the OvS networks
    * Build a DNS/DHCP LXC container
    * Configure the containers according to specifications in the "product" subdirectory.
    * Clone the number of containers specified in the anylinux-services.sh file
    * Install Docker and a sample network-tools Docker container

Note that although the software is unpacked at /home/username/Downloads, nothing is actually installed there. The installation actuall takes place at /opt/olxc/home/username/Downloads which is where the installer puts all installation files. The distribution at /home/username/Downloads remains static during the install.

The install is customized and configured in the file:

```
anylinux/CONFIG
```
To add additional physical hosts you use
```
./anylinux-services.GRE.HOST.sh new
```
This script requires configuring these parameters in the "anylinux/CONFIG" script.  

    * SPOKEIP
    * HUBIP
    * HubUserAct
    * HubSudoPwd
    * Product
    
If you used the scripts to create an "orabuntu" user then HubUserAct=orabuntu and HubSudoPwd=orabuntu (or optionally the generated password).  The products currently available in the "products" directory are "oracle-db" and "workspaces" but you can create your own product file sets and put them in the products directory.

Note that the subnet ranges chosen in the "anylinux-services.HUB.HOST.sh" install must be used unchanged when running the script "anylinux-services.GRE.HOST.sh" so that the multi-host networking works correctly.

To put VM's on the Orabuntu-LXC OpenvSwitch network, on either a HUB physical host, or, on a GRE physical host, see the guide in the Orabuntu-LXC wiki which gives an example (VirtualBox) of putting a VM on the LXC OpenvSwitch network.

**Note**: These VM scripts below have not been updated for LXD features yet.

To install Orabuntu-LXC in a VM running on the LXC OpenvSwitch network on the HUB host use the following script.  In this case, Orabuntu-LXC is already installed on the phyiscal host, a VM has been put on the LXC OpenvSwitch networks, and now Orabuntu-LXC is installed in the VM.  This results in containers that are running in the VM on the LXC OpenvSwitch network, as well as the existing LXC containers which are running on the Orabuntu-LXC physical host.  All of these containers, VM's and physical hosts can talk to each other by default.

```
./anylinux-services.VM.ON.HUB.HOST.1500.sh new
```

To install Orabuntu-LXC in a VM running on the LXC OpenvSwitch network on a GRE-connected host use the following script:
```
./anylinux-services.VM.ON.GRE.HOST.1420.sh new
```
In this case again it is necessary to configure parameters in the "anylinux-services.VM.ON.GRE.HOST.1420.sh" script:

    * SPOKEIP
    * HUBIP
    * HubUserAct
    * HubSudoPwd
    * Product

To add Oracle Linux container versions (e.g. add some Oracle Linux 7.3 LXC containers to a deployment of Oracle Linux 6.9 LXC containers) use either

```
anylinux-services.ADD.RELEASE.ON.HUB.HOST.1500.sh
```
or
```
anylinux-services.ADD.RELEASE.ON.GRE.HOST.1420.sh
```
depending again on whether container versions are being add on an Orabuntu-LXC HUB host, or a GRE-tunnel-connected Orabuntu-LXC host, respectively.  In this case it is necessary to go into anylinux-services.sh file and edit the container version variables (MajorRelease, PointRelease) in pgroup2.

To add more clones of an already existing version, e.g. add more Oracle Linux 7.3 LXC containers to a set of existing Oracle Linux 7.3 LXC containers, use
```
anylinux-services.ADD.CLONES.sh
```
Note that Orabuntu-LXC also includes the default LXC Linux Bridge for that distro, e.g. for CentOS and Fedora
```
[orabuntu@fedora27 logs]$ ifconfig virbr0
virbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 192.168.122.1  netmask 255.255.255.0  broadcast 192.168.122.255
        ether 52:54:00:8b:e7:18  txqueuelen 1000  (Ethernet)
        RX packets 3189  bytes 187049 (182.6 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 4739  bytes 28087232 (26.7 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

[orabuntu@fedora27 logs]$ cat /etc/fedora-release 
Fedora release 27 (Twenty Seven)
[orabuntu@fedora27 logs]$ 
```
and for Oracle Linux, Ubuntu and Red Hat Linux:
```
orabuntu@UL-1710-S:~$ ifconfig lxcbr0
lxcbr0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        inet 10.0.3.1  netmask 255.255.255.0  broadcast 0.0.0.0
        ether 00:16:3e:00:00:00  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

orabuntu@UL-1710-S:~$ 
```

so to include containers other than Oracle Linux in your deployment, use the default LXC linux bridge to add non-Orabuntu-LXC LXC containers, and those containers will be able to talk to the containers on the OvS network right out of the box. In this way Ubuntu Linux LXC containers, Alpine Linux LXC containers, etc. can be added to the mix using the standard Linux Bridge (non-OVS).

# Why Oracle Linux

Why is Orabuntu-LXC built around Oracle Linux?  I chose Oracle Linux because at the time Orabuntu-LXC development began (2015), it was arguably the only free downloadable readily-available Red Hat-family Linux backed by the full power and credit of a major software vendor, actually one of the largest, namely Oracle Corporation. Oracle (unlike at that time, in 2015, Red Hat) made their production-grade Linux readily and easily available for free (including free access to their public YUM servers) and because Oracle Linux have made extensive and successful modifications to Oracle Linux to make it very container-friendly, extremely fast, and an outstanding platform for container deployments of all types.  Oracle Linux explicitly supports LXC and Docker containers, and since those are the core technologies supported by Orabuntu-LXC, Oracle Linux was (and still is) really the #1 choice for production-grade Linux container deployments where a Red Hat-family Linux is required, and there is a need for a production-grade, industrial-strength container solution built around a Red Hat-family Linux backed by a major software vendor, and there is really only one credible choice that meets those requirements, and it's Oracle Linux.

If you run Oracle Linux as your LXC host, and Orabuntu-LXC Oracle Linux LXC containers, you have a 100% Oracle Corporation next-generation container infrastructure solution at no cost whether in development or in production, and, which can at any time be converted to paid support from Oracle Corporation, when and if the time comes for that.

# Docker

Orabuntu-LXC deployes docker for all of our supported platforms (Fedora, CentOS, Ubuntu, Oracle Linux, Red Hat) and the docker containers on docker0 by default can be accessed on their ports from the LXC Linux Containers, VMs, and physical hosts.  This provides out of the box a mechanism to put multilayer products into LXC containers and connect them to services prodvided from Docker Containers.

# Virtual Machines

VM's can now be directly attached to the Orabuntu-LXC OpenvSwitch VLAN networks easily using just the functionality in for example the Oracle VirtualBox GUI.  The VMs attached to OpenvSwitch will get IP addresses on the same subnet as the LXC containers and will have full out of the box networking between the LXC containers running on the physical host and the VMs.  But even beyond that, Orabuntu-LXC can be installed in the VM's that are already on the host OpenvSwitch network and the Orabuntu-LXC Linux containers inside the VMs will have full out of the box networking with all the VMs, and all the physical hosts (HUB or GRE), and all the LXC and Docker containers running on the physical hosts, and all of these VMs and containers will all be in DNS and will be accessible from each other via their DNS names, with full forward and reverse lookup services provided by the redundant and fault-tolerant new Orabuntu-LXC DNS/DHCP LXC container replicas.

# Orabuntu-LXC DNS/DHCP Replication

Version 6.0-beta AMIDE edition includes near real-time replication of the LXC DNS/DHCP container that is on the OpenvSwitch networks.  On the Orabuntu-LXC HUB host is the primary DNS/DHCP LXC container which provides DNS/DHCP services to all GRE-connected physical hosts, VM's and LXC Containers, whether on physical host or in VM's.  

Every Orabuntu-LXC physical host when deployed automatically gets a replica of the DNS/DHCP LXC container from the HUB host.  This replica is installed in the down state and remains down while the HUB host LXC DNS/DHCP container is running.  However, every 5 minutes (or at an interval specified by the user) the LXC DNS/DHCP container on the HUB host checks for any DNS/DHCP zone updates and if it finds any, it propagates those changes to all the DNS/DHCP LXC container replicas on all GRE-connected Orabuntu-LXC physical hosts.

If at any time DNS/DHCP services are needed, such as if the HUB DNS/DHCP goes down, or if a GRE-connected host needs to be detached from the network, the replica DNS/DHCP LXC container can be started on that local host, and will immediately apply all of the latest updates from the master DNS/DHCP LXC container on HUB host (using the "dns-sync" service), and will be able to resolve DNS and provide DHCP for all GRE-connected hosts and HUB host on the network. (Be sure that only one DNS/DHCP LXC replica is up at any given time).  A replica can be converted to master status simply by copying the list of customer GRE-connected physical hosts to the DNS/DHCP replica, since all replicas have all scripting on board to function as primary DNS/DHCP.  This can also be useful if a developer laptop is a GRE-replicated host which will provide the developer with full DNS/DHCP while disconnected from the network for all LXC containers installed locally on the developer laptop.

This functionality can be used with any HA monitoring solution such as HP Service Guard to monitor that at all times at least one DNS/DHCP LXC container on the network is up and running.

# OpenvSwitch

Orabuntu-LXC uses OpenvSwitch as it's core switch technology.  This means that all of the power of OpenvSwitch production-grade Software Defined Networking (SDN) is available in an Orabuntu-LXC deployment.  This includes a rich production-ready switch feature set http://www.openvswitch.org/ and other high performance features that can be added-on, such as OVS-DPDK https://software.intel.com/en-us/articles/open-vswitch-with-dpdk-overview.

# SCST Linux SAN

The included Orabuntu-LXC SCST Linux SAN deployer (scst-files.tar) clears away the fog that has for too long surrounded SCST deployments on Ubuntu Linux.  The Orabuntu-LXC SCST Linux SAN deployer installs SCST on Ubuntu Linux using DKMS-enabled DEB packages, for worry-free hands-off SCST performance across host kernel updates.  Support for RPM based distros, as well as DEB based distros, is FULLY AUTOMATED from start to finish.  Kick off the Orabuntu-LXC SCST installer and go get a cup of coffee or jog around the block.  When you come back multipath, production-ready LUNs are waiting for your project, and the /etc/multipath.conf file has been built for you and installed automatically. SCST module updates after host kernel updates are handled transparently by DKMS technology allowing users and administrators to focus on the rich production-ready feature set of SCST used by many of the largest technology, services, and hardware companies.  http://scst.sourceforge.net/users.html

# WeaveWorks

Although Orabuntu-LXC provides it's own multi-host solution, it can also be used with WeaveWorks technologies, and can be managed from Google Cloud Platform (GCP) using WeaveWorks technology for web-based access and management from anywhere.

# Security Considerations

Orabuntu-LXC multi-host configuration does NOT require key-exchange technology aka automated key logins.  Therefore, Orabuntu-LXC can be used in PCI-DSS environments where key-exchange is not permitted and can be used in any situation where no data at all can be written during login. Orabuntu-LXC is also excellent for certain types of LDAP authentication mechanisms where public-key technology cannot be used.  Orabuntu-LXC is potentially also useful for implementation on routers where public-key technology again may not be an option.

The root account is NOT used for Orabuntu-LXC installation.  All that is required currently is an adminstrative user with "SUDO ALL" privilege, and work is underway on the roadmap to get the minimal set of SUDO privileges defined so that not even SUDO ALL privilege will be needed.  Interestingly, once Orabuntu-LXC is installed, the administrative SUDO ALL user used to install Orabuntu-LXC can actually be DELETED using userdel for example because after installation that user is no longer needed.  All the GRE-tunnels and other functionality of Orabuntu-LXC continue to operate normally under root authority even though the install user no longer exists.  For GRE-connected Orabuntu-LXC hosts, there is a user called "amide" which has two sudo privileges, "mkdir" and "cp" which is used to handle updating the LXC containerized DNS/DHCP replicas across all the Orabuntu-LXC physical hosts, but even this user can be replaced with the Orabuntu-LXC built-in AmazonS3 LXC containerized DNS/DHCP replication option for secured operations.

# Installer Logging

The Orabuntu-LXC installer uses the highly-sophisticated sudoreplay logging facility, which not only logs every single sudo command, but also allows actualy PLAYBACK of the installer step - not just a static log - but an actual VIDEO of that install step.  And sudoreplay allows speedup or slowdown of the install step video, so it is possible to review a lengthy install step (such as building OpenvSwitch from source code) speeded-up.  And playback includes every input and output that the actual session encountered, so the entire session is captured in all respects.  And this functionality does not require any direct edit to the sudoers file, rather it uses /etc/sudoers.d and sets removable parameters that can be turned after off/removed after the install.

To monitor the log during or after an install, go to the "installs/logs" subdirectory of the Orabuntu-LXC release and cat or tail the root-owned "username.log" file.

Gilbert Standen
Founder and Creator
Principal Solution Architect
Orabuntu-LXC
St. Louis, MO
August 2021
gilbert@orabuntu-lxc.com
