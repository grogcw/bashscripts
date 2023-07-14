#!/bin/bash

# Flag variable to track valid input
valid_input=false

# Loop until valid input is received
while [ "$valid_input" = false ]; do
    # Prompt the user to continue or stop
    echo "This script requires to be run as root and will erase and reconstruct a base cluster."
    read -p "Do you wish to continue ? (Yes/No) [Yes]: "

    # Convert user input to lowercase for case-insensitive comparison
    user_input_lower=$(printf "%s" "$REPLY" | tr '[:upper:]' '[:lower:]')

    # Check user input and take action accordingly
    case $user_input_lower in
        "" | "y" | "yes")
            valid_input=true
            ;;
        "n" | "no")
            echo "Stopping."
            exit 0
            ;;
        *)
            echo "Invalid input."
            ;;
    esac
done

kubeadm reset -f
systemctl stop containerd
systemctl stop docker.socket
systemctl stop docker.service
systemctl stop $(systemctl list-units --all | awk '/kube/ {print $1}')
systemctl stop kubelet
dnf remove -y containerd.io docker-ce kubelet kubeadm kubectl
rm -rf /etc/containerd
rm -rf /etc/cni
rm -rf /etc/kubernetes
rm -rf /etc/docker
rm -rf /var/lib/kubelet
rm -rf /var/lib/cni
rm -rf /var/lib/containerd
rm -rf /var/lib/calico
rm -rf /data
ip link delete docker0
ipvsadm --clear
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
dnf makecache
dnf install -y containerd.io docker-ce kubelet kubeadm kubectl --disableexcludes=kubernetes
mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
containerd config default > /etc/containerd/config.toml
sudo sed -i 's/^            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd.service
systemctl enable --now kubelet.service
systemctl start kubelet
kubeadm config images pull
kubeadm init
export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile.d/k8s.sh
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml

# Taint node for later use
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

# Create StorageClass, PersistentVolume and tag it as default
cat > /root/sc.yaml << EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

cat > /root/pv.yaml << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations: {}
  name: storage-pv
spec:
  accessModes:
    - ReadWriteOnce
  capacity:
    storage: 10Gi
  local:
    path: /data
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - kubernetes
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  volumeMode: Filesystem
EOF

mkdir /data

kubectl apply -f /root/sc.yaml
kubectl apply -f /root/pv.yaml
kubectl patch storageclass local-storage -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Add portainer's repo and install it.
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm upgrade --install --create-namespace -n portainer portainer portainer/portainer
