chkconfig ntpd on
service ntpd start
chkconfig sendmail off
service avahi-daemon stop

# Needed for nslookup utility
yum -y install bind-utils

# Oracle Needed for TFA Install During Oracle GI install
yum -y install tar
yum -y install perl
yum -y install which
yum -y install bash

# Oracle Needed for hugepages_settings.sh script
yum -y install bc

# Uncomment if using NFS
# chown grid:asmadmin /shared_data
# service rpcbind start
# mount -a
