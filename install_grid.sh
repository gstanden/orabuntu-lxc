userdel -r grid
cd /home
rm -rf grid
useradd -u 1098 -g oinstall -G asmadmin,asmdba,asmoper,dba grid
rm -rf /u00
mkdir -p /u00/app/12.1.0/grid
mkdir -p /u00/app/grid
chown -R grid:oinstall /u00
mkdir -p /u00/app/oracle
chown oracle:oinstall /u00/app/oracle
chmod -R 775 /u00
# need to set passwd for grid on lxcora01 before clone
# need to run ssh-keygen -t rsa on all nodes before grid install
