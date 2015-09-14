i=10
n=16
while [ $i -le $n ]
do
sudo lxc-start -n lxcora$i
sleep 5
sudo lxc-stop -n lxcora$i
sleep 5
sudo lxc-start -n lxcora$i
sleep 10
i=$((i+1))
done
