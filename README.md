# Installing Orabuntu-LXC v6.0-beta AMIDE Edition

You need an administrative user account such as the install account (i.e. the install user need to have "sudo ALL" privilege).  On Ubuntu Linux this would be membership in the "sudo" group, and on Oracle Linux this would be membership in the "wheel" group, for example.

Download Orabuntu-LXC to /home/username/Downloads and unzip the distribution.  We strongly recommend staging the software in the /home/username/Downloads directory.  You can use the script "uekulele-services-0.sh" or "orabuntu-services-0.sh" to create the required user and directories for Orabuntu-LXC install.

Change directory to /home/username/Downloads/orabuntu-lxc-master/anylinux.

Run  "./anylinux-services.HUB.HOST.sh new" command.

That's all.  This one command will build Oracle Linux LXC containers, build the OpenvSwitch networks (with VLANs) on whatever IP subnets and domains you specify, put the LXC containers on the OvS networks, build a DNS/DHCP LXC container, and configure the containers according to your specifications (configured in the "products" subdirectory).  Each product in the "products" directory gets 3 files.  Examples are included for Oracle DB, and for Workspaces.  

Note that although the software is unpacked at /home/username/Downloads, nothing is actually installed there.  The installation actuall takes place at /opt/olxc/home/username/Downloads which is where the installer puts all installation files.  Your distribution at /home/username/Downloads remains static during the install.

You can configure the install in the "anylinux-services.sh" file.  Search for {pgroup1, pgroup2, pgroup3} to see the configurable settings.  When first trying out Orabuntu-LXC, the simplest approach is probably to just build a VM of one of a supported vanilla Linux distro (Oracle Linux, Ubuntu, CentOS, Fedora, or Red Hat) and then just download and run as described above "./anylinux-services.HUB.HOST.sh new" and then after install study the setup to see how the configurations in "anylinux-services.sh" affect the deployment.

When you want to add additional physical hosts you use the "./anylinux-services.GRE.HOST.sh new" script command.  This script requires configuring SPOKEIP, HUBIP, HubUserAct, HubSudoPwd, and Product variables.  Note that once you have chosen subnet ranges in anylinux-services.HUB.HOST.sh you need to leave those unchanged when running anylinux-services.GRE.HOST.sh so that the multi-host networking works correctly.

If you want to put VM's on either a HUB physical host or a GRE phyical host, and you want those VM's to be on the Orabuntu-LXC OpenvSwitch networks (and get DHCP IP addresses from the same DNS/DHCP container as the LXC containers) then you use "anylinux-services.VM.ON.HUB.HOST.1500.sh" or "anylinux-services.VM.ON.GRE.HOST.1420.sh" depending on whether your VM's will run on the HUB Orabuntu-LXC host or on a GRE-tunnel-connected Orabuntu-LXC physical host, respectively.  In this case again it is necessary to configure SPOKEIP, HUBIP, HubUserAct, HubSudoPwd, and Product variables.

If you want to add additional Oracle Linux container versions (e.g. 7.3, 6.9 etc.) you use either "anylinux-services.ADD.RELEASE.ON.HUB.HOST.1500.sh" or "anylinux-services.ADD.RELEASE.ON.GRE.HOST.1420.sh" depending again on whether you are adding container versions on an Orabuntu-LXC HUB host or a GRE-tunnel-connected Orabuntu-LXC host, respectively.

If you want to add more clones of an already existing version, e.g. you have 3 Oracle Linux 7.3 LXC containers and you want to add 2 more Oracle Linux 7.3. LXC containers, then you use "anylinux-services.ADD.CLONES.sh" script.

Note that Orabuntu-LXC also includes the default LXC Linux Bridge for that distro (e.g. virbr0 for CentOS and Fedora, and lxcbr0 for Oracle Linux, Ubuntu and Red Hat Linux) so if you want to include containers other than Oracle Linux in your deployment, you can use the default LXC linux bridge to add non-Orabuntu-LXC LXC containers to your deployments, and those containers will be able to talk to the containers on the OvS network right out of the box.  In this way you can add Ubuntu Linux LXC containers, Alpine Linux LXC containers, etc. to the mix using the standard Linux Bridge (non-OVS).

# Why Oracle Linux

Why is Orabuntu-LXC built around Oracle Linux?  We chose Oracle Linux because it is the only free downloadable readily-available Red Hat-family Linux backed by the full power and credit of a major software vendor, actually one of the largest, namely Oracle Corporation. Oracle (unlike Red Hat) makes their production-grade Linux available for free (including free access to their public YUM servers) and because Oracle Linux is under the direction of it's current Product Management Director, Avi Miller, Oracle have made extensive and successful modifications to Oracle Linux to make it very container-friendly, extremely fast, and an outstanding platform for container deployments of all types.  Oracle Linux explicitly supports LXC and Docker containers, and since those are the core technologies supported by Orabuntu-LXC, we feel Oracle Linux is really the #1 choice for production-grade Linux container deployments where a Red Hat-family Linux is required, and we saw a need for a production-grade, industrial-strength container solution built around a Red Hat-family Linux backed by a major software vendor, and there is really only one credible choice that meets those requirements, and it's Oracle Linux.

If you run Oracle Linux as your LXC host, and Orabuntu-LXC Oracle Linux LXC containers, you have a 100% Oracle Corporation next-generation container infrastructure solution at no cost whether in development or in production, and, which can at any time be converted to paid support from Oracle Corporation, when and if the time comes for that.

# Docker

Orabuntu-LXC deployes docker for all of our supported platforms (Fedora, CentOS, Ubuntu, Oracle Linux, Red Hat) and the docker containers on docker0 by default can be accessed on their ports from the LXC Linux Containers, VMs, and physical hosts.  This provides out of the box a mechanism to put multilayer products into LXC containers and connect them to services prodvided from Docker Containers.

# Virtual Machines

VM's can now be directly attached to the Orabuntu-LXC OpenvSwitch VLAN networks easily using just the functionality in for example the Oracle VirtualBox GUI.  The VMs attached to OpenvSwitch will get IP addresses on the same subnet as the LXC containers and will have full out of the box networking between the LXC containers running on the physical host and the VMs.  But even beyond that, Orabuntu-LXC can be installed in the VM's that are already on the host OpenvSwitch network and the Orabuntu-LXC Linux containers inside the VMs will have full out of the box networking with all the VMs, and all the physical hosts (HUB or GRE), and all the LXC and Docker containers running on the physical hosts, and all of these VMs and containers will all be in DNS and will be accessible from each other via their DNS names, with full forward and reverse lookup services provided by the redundant and fault-tolerant new Orabunt-LXC DNS/DHCP LXC container replicas.

# Orabuntu-LXC DNS/DHCP Replication

Version 6.0-beta AMIDE edition includes near real-time replication of the LXC DNS/DHCP container that is on the OpenvSwitch networks.  On the Orabuntu-LXC HUB host is the primary DNS/DHCP LXC container which provides DNS/DHCP services to all GRE-connected physical hosts, VM's and LXC Containers, whether on physical host or in VM's.  

Every Orabuntu-LXC physical host when deployed automatically gets a replica of the DNS/DHCP LXC container from the HUB host.  This replica is installed in the down state and remains down while the HUB host LXC DNS/DHCP container is running.  However, every 5 minutes (or at an interval specified by the user) the LXC DNS/DHCP container on the HUB host checks for any DNS/DHCP zone updates and if it finds any, it propagates those changes to all the DNS/DHCP LXC container replicas on all GRE-connected Orabuntu-LXC physical hosts (which nevertheless are always not running during these updates - which is possible because the LXC container filesystem is available even when the container is not running).

If at any time DNS/DHCP services are needed, such as if the HUB DNS/DHCP goes down, or if a GRE-connected host needs to be detached from the network, the replica DNS/DHCP LXC container can be started on that local host, and will immediately apply all of the latest updates from the master DNS/DHCP LXC container on HUB host (using the "dns-sync" service), and will be able to resolve DNS and provide DHCP for all GRE-connected hosts and HUB host on the network. (Be sure that only one DNS/DHCP LXC replica is up at any given time).  A replica can be converted to master status simply by copying the list of customer GRE-connected physical hosts to the DNS/DHCP replica, since all replicas have all scripting on board to function as primary DNS/DHCP.  This can also be useful if a developer laptop is a GRE-replicated host which will provide the developer with full DNS/DHCP while disconnected from the network for all LXC containers installed locally on the developer laptop.

This functionality can be used with any HA monitoring solution such as HP Service Guard to monitor that at all times at least 1 DNS/DHCP LXC container on the network is up and running.

# OpenvSwitch

Orabuntu-LXC uses OpenvSwitch as it's core switch technology.  This means that all of the power of OpenvSwitch production-grade Software Defined Networking (SDN) is available in an Orabuntu-LXC deployment.  This includes high performance features such as OVS-DPDK https://software.intel.com/en-us/articles/open-vswitch-with-dpdk-overview.


Gilbert Standen
St. Louis, MO
March 4, 2018
gilbert@orabuntu-lxc.com
