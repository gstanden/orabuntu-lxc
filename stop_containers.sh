i=10
n=22
while [ $i -le $n ]
do
sudo lxc-stop -n lxcora$i
i=$((i+1))
done
