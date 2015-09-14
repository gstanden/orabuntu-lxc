#!/bin/bash

function CheckStorageDevices () { ls -l /dev/mapper | grep systemdg | grep -c '>'; }
StorageDevices=$(CheckStorageDevices)

# while [ $StorageDevices -ne 0 ]
# do
sudo iscsiadm --mode node --targetname iqn.2015-08.org.vmem:w520.san.asm.luns   --portal 10.207.41.1 --login
sudo iscsiadm --mode node --targetname iqn.2015-08.org.vmem:w520.san.asm.luns   --portal 10.207.40.1 --login
sudo iscsiadm --mode node --targetname iqn.2015-08.org.vmem:w520.san.asm.luns   --portal 10.207.41.1 --logout
sudo iscsiadm --mode node --targetname iqn.2015-08.org.vmem:w520.san.asm.luns   --portal 10.207.40.1 --logout
sudo multipath -F
sudo iscsiadm --mode node --targetname iqn.2015-08.org.vmem:w520.san.asm.luns   --portal 10.207.41.1 --login
sudo iscsiadm --mode node --targetname iqn.2015-08.org.vmem:w520.san.asm.luns   --portal 10.207.40.1 --login
StorageDevices=$(CheckStorageDevices)
# done
