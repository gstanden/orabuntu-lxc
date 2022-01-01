n=1
Cmd0=1
while [ $Cmd0 -ne 0 ] && [ $n -le 5 ]
do
        dnf upgrade -y --refresh
        Cmd0=`echo $?`
        n=$((n+1))
        sleep 5
done
dnf install -y epel-release
dnf install -y sshpass
systemctl enable kubelet.service
# kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all --kubernetes-version=v1.23.0-beta.0 | tee kubeadm_init.log
kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all | tee kubeadm_init.log
# kubeadm reset -f
# kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all | tee kubeadm_init.log
echo "Sleeping 30 seconds while kubernetes master starts running ..."
sleep 30
cat kubeadm_init.log | grep -A1 join | grep -A1 token > joincluster.sh
chmod +x joincluster.sh
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile

# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
# sleep 30
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
# sleep 30
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

sleep 5

echo "Sleeping 30 seconds while weavenet starts running ..."
echo ''
kubectl get pods --all-namespaces -o wide
sleep 30
echo ''
kubectl get pods --all-namespaces -o wide
sleep 30
echo ''
kubectl get pods --all-namespaces -o wide
sleep 30
sed -i '${s/$/ --ignore-preflight-errors=all/}' joincluster.sh
sleep 5
sshpass -p root scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /root/joincluster.sh root@10.207.39.5:/root/.
sshpass -p root scp    -o CheckHostIP=no -o StrictHostKeyChecking=no -p /root/joincluster.sh root@10.207.39.6:/root/.
echo ''
sshpass -p root ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no root@10.207.39.5 "/root/joincluster.sh"
sleep 10
echo ''
sshpass -p root ssh -t -o CheckHostIP=no -o StrictHostKeyChecking=no root@10.207.39.6 "/root/joincluster.sh"

# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
# sleep 30
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
# sleep 30
# kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
# sleep 30

clear

echo ''
echo "=============================================="
echo "kubectl describe node maestro...              "
echo "=============================================="
echo ''

kubectl describe node maestro

echo ''
echo "=============================================="
echo "Done: kubectl describe node maestro.          "
echo "=============================================="
echo ''

sleep 10

clear

echo ''
echo "=============================================="
echo "kubectl describe node violin1...              "
echo "=============================================="
echo ''

kubectl describe node violin1

echo ''
echo "=============================================="
echo "Done: kubectl describe node violin1.          "
echo "=============================================="
echo ''

sleep 10

clear

echo ''
echo "=============================================="
echo "kubectl describe node violin2...              "
echo "=============================================="
echo ''

kubectl describe node violin2

echo ''
echo "=============================================="
echo "Done: kubectl describe node violin2.          "
echo "=============================================="
echo ''

sleep 10

clear

