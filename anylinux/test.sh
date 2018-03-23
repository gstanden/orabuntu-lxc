MultiHostVar8=orabuntu
MultiHostVar9=orabuntu
MultiHostVar5=10.0.140.218
Sx1Index=201
Sx1Net=172.29.108

function CheckHighestSx1IndexHit {
sshpass -p $MultiHostVar9 ssh -qt -o CheckHostIP=no -o StrictHostKeyChecking=no $MultiHostVar8@$MultiHostVar5 "sudo -S <<< "$MultiHostVar9" nslookup -timeout=1 $Sx1Net.$Sx1Index" | grep -c 'name ='
}
HighestSx1IndexHit=$(CheckHighestSx1IndexHit)

echo $HighestSx1IndexHit

while [ $HighestSx1IndexHit = 1 ]
do
	Sx1Index=$((Sx1Index+1))
	HighestSx1IndexHit=$(CheckHighestSx1IndexHit)
done
echo $Sx1Index
