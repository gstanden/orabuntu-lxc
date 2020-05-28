groupadd -g 1001 oinstall	> /dev/null 2>&1
groupadd -g 1100 asmadmin	> /dev/null 2>&1
groupadd -g 1200 dba		> /dev/null 2>&1
groupadd -g 1300 asmdba		> /dev/null 2>&1
groupadd -g 1201 oper		> /dev/null 2>&1
groupadd -g 1301 asmoper	> /dev/null 2>&1

# new additions 12c
groupadd -g 1401 backupdba	> /dev/null 2>&1
groupadd -g 1501 dgdba		> /dev/null 2>&1
groupadd -g 1601 kmdba		> /dev/null 2>&1
groupadd -g 1701 osacfs		> /dev/null 2>&1
groupadd -g 1801 osaudit	> /dev/null 2>&1

usermod -a -G backupdba,dgdba,kmdba oracle
# end new additions 12c

useradd -u 1098 -g oinstall -G asmadmin,asmdba,asmoper,dba grid > /dev/null 2>&1
useradd -u 1100 -g oinstall oracle                              > /dev/null 2>&1
usermod -a -G dba,asmdba,oper,oinstall oracle
mkdir -p /u00/app/12.1.0/grid
mkdir -p /u00/app/grid
chown -R grid:oinstall /u00
mkdir -p /u00/app/oracle
chown oracle:oinstall /u00/app/oracle
chmod -R 775 /u00
