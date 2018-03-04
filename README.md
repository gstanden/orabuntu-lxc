Installing Orabuntu-LXC

You need an administrative user account such as the install account (i.e. the install user need to have "sudo ALL" privilege).  On Ubuntu Linux this would be membership in the "sudo" group, and on Oracle Linux this would be membership in the "wheel" group, for example.

Download Orabuntu-LXC to /home/username/Downloads and unzip the distribution.  We strongly recommend staging the software in the /home/username/Downloads directory.  You can use the script "uekulele-services-0.sh" or "orabuntu-services-0.sh" to create the required user and directories for Orabuntu-LXC install.

Change directory to /home/username/Downloads/orabuntu-lxc-master/anylinux.

Run ./anylinux-services.HUB.HOST.sh new

That's all.  This one command will build Oracle Linux LXC containers, build the OpenvSwitch networks (with VLANs) on whatever IP subnets and domains you specify, put the LXC containers on the OvS networks, build a DNS/DHCP LXC container, configure the containers according to your specifications (configured in the "products" subdirectory).  

Note that although the software is unpacked at /home/username/Downloads, nothing is actually installed there.  The installation actuall takes place at /opt/olxc/home/username/Downloads which is where the installer puts all installation files.  Your distribution at /home/username/Downloads remains static during the install.

You can configure the install in the anylinux-services.sh file.  Search for {pgroup1, pgroup2, pgroup3} to see the configurable settings.

When you want to add additional physical hosts you use the "./anylinux-services.GRE.HOST.sh new" script command.  This script requires configuring SPOKEIP, HUBIP, HubUserAct, HubSudoPwd, and Product variables.  Note that once you have chosen subnet ranges in anylinux-services.HUB.HOST.sh you need to leave those unchanged when running anylinux-services.GRE.HOST.sh so that the multi-host networking works correctly.

If you want to put VM's on either a HUB physical host or a GRE phyical host, and you want those VM's to be on the Orabuntu-LXC OpenvSwitch networks (and get DHCP IP addresses from the same DNS/DHCP container as the LXC containers) then you use anylinux-services.VM.ON.HUB.HOST.1500.sh or anylinux-services.VM.ON.GRE.HOST.1420.sh depending on whether your VM's will run on the HUB Orabuntu-LXC host or on a GRE-tunnel-connected Orabuntu-LXC physical host, respectively.  In this case again it is necessary to configure SPOKEIP, HUBIP, HubUserAct, HubSudoPwd, and Product variables.

If you want to add additional Oracle Linux container versions (e.g. 7.3, 6.9 etc.) you use either anylinux-services.ADD.RELEASE.ON.HUB.HOST.1500.sh or anylinux-services.ADD.RELEASE.ON.GRE.HOST.1420.sh depending again on whether you are adding container versions on an Orabuntu-LXC HUB host or a GRE-tunnel-connected Orabuntu-LXC host, respectively.

If you want to add more clones of an already existing version, e.g. you have 3 Oracle Linux 7.3 LXC containers and you want to add 2 more Oracle Linux 7.3. LXC containers, then you use anylinux-services.ADD.CLONES.sh script.

Note that Orabuntu-LXC also includes the default LXC Linux Bridge for that distro (e.g. virbr0 for CentOS and Fedora, and lxcbr0 for Oracle Linux, Ubuntu and RedHat Linux) so if you want to include containers other than Oracle Linux in your deployment, you can use the default LXC linux bridge to add non-Orabuntu-LXC LXC containers to your deployments, and those containers will be able to talk to the containers on the OvS network right out of the box.  In this way you can add Ubuntu Linux LXC containers, Alpine Linux LXC containers, etc. to the mix using the standard Linux Bridge (non-OVS).

Why is Orabuntu-LXC built around Oracle Linux?  We chose Oracle Linux because it is the only RedHat-family Linux backed by the full power and credit of Oracle Corporation, because Oracle (unlike RedHat) makes their production-grade Linux available for free (including free access to their public YUM servers) and because Oracle Corporation and Oracle Linux under the direction of it's current product manager Avi Miller have made extensive and successful modifications to Oracle Linux to make it very container-friendly, extremely fast, and an outstanding platform for container deployments of all types.  Oracle Linux explicitly supports LXC and Docker containers, and since those are the core technologies supported by Orabuntu-LXC, we feel Oracle Linux is really the #1 choice for production-grade Linux container deployments where a RedHat-family Linux is required.

Gilbert Standen
St. Louis, MO
March 4, 2018
gilbert@orabuntu-lxc.com
