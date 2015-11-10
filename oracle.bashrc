# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

umask 022
export ORACLE_BASE=/u00/app/oracle
export ORACLE_HOME=/u00/app/oracle/product/12.1.0/dbhome_1
export ORACLE_SID=VMEM11
export PATH=$PATH:$ORACLE_HOME/bin
