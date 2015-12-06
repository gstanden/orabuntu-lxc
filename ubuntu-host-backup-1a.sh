#!/bin/bash

export DATEXT=`date +'%y%m%d_%H%M%S'`

# sudo cp -p /etc/multipath.conf /etc/multipath.conf.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/iscsi/initiatorname.iscsi /etc/iscsi/initiatorname.iscsi.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/dhcp/dhclient.conf /etc/dhcp/dhclient.conf.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/bind/rndc.key /etc/bind/rndc.key.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/bind/named.conf.options /etc/bind/named.conf.options.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/bind/named.conf.local /etc/bind/named.conf.local.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/default/bind9 /etc/default/bind9.lxc.oracle.bak.$DATEXT
# sudo cp -p /var/lib/bind/rev.vmem.org /var/lib/bind/rev.vmem.org.lxc.oracle.bak.$DATEXT
# sudo cp -p /var/lib/bind/fwd.vmem.org /var/lib/bind/fwd.vmem.org.lxc.oracle.bak.$DATEXT
# sudo cp -p /var/lib/bind/rev.mccc.org /var/lib/bind/rev.mccc.org.lxc.oracle.bak.$DATEXT
# sudo cp -p /var/lib/bind/fwd.mccc.org /var/lib/bind/fwd.mccc.org.lxc.oracle.bak.$DATEXT
# sudo cp -p /etc/NetworkManager/dnsmasq.d/local /etc/NetworkManager/dnsmasq.d/local.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/network/interfaces /etc/network/interfaces.lxc.oracle.bak.$DATEXT
# sudo cp -p /etc/network/if-up.d/openvswitch-net /etc/network/if-up.d/openvswitch-net.lxc.oracle.bak.$DATEXT
# sudo cp -p /etc/network/if-up.d/openvswitch /etc/network/if-up.d/openvswitch.lxc.oracle.bak.$DATEXT
# sudo cp -p /etc/network/if-down.d/openvswitch /etc/network/if-down.d/openvswitch.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw1.sh /home/gstanden/OpenvSwitch/crt_ovs_sw1.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw2.sh /home/gstanden/OpenvSwitch/crt_ovs_sw2.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw3.sh /home/gstanden/OpenvSwitch/crt_ovs_sw3.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw4.sh /home/gstanden/OpenvSwitch/crt_ovs_sw4.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw5.sh /home/gstanden/OpenvSwitch/crt_ovs_sw5.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw6.sh /home/gstanden/OpenvSwitch/crt_ovs_sw6.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw7.sh /home/gstanden/OpenvSwitch/crt_ovs_sw7.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw8.sh /home/gstanden/OpenvSwitch/crt_ovs_sw8.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sw9.sh /home/gstanden/OpenvSwitch/crt_ovs_sw9.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/crt_ovs_sx1.sh /home/gstanden/OpenvSwitch/crt_ovs_sx1.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/del-bridges.sh /home/gstanden/OpenvSwitch/del-bridges.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/OpenvSwitch/create_asm_luns.sh /home/gstanden/OpenvSwitch/create_asm_luns.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/Networking/nslookups.sh /home/gstanden/Networking/nslookups.sh.lxc.oracle.bak.$DATEXT
# sudo cp -p /home/gstanden/Networking/crt_links.sh /home/gstanden/Networking/crt_links.sh.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/apparmor.d/lxc/lxc-default /etc/apparmor.d/lxc/lxc-default.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/security/limits.conf /etc/security/limits.conf.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/sysctl.conf /etc/sysctl.conf.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/exports /etc/exports.lxc.oracle.bak.$DATEXT
sudo cp -p /etc/resolv.conf /etc/resolv.conf.lxc.oracle.bak.$DATEXT
