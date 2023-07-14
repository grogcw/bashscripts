#!/bin/bash

# Flag variable to track valid input
valid_input=false

# Loop until valid input is received
while [ "$valid_input" = false ]; do
	# Prompt the user to continue or stop
	echo "This script requires to be run as root on a machine with a correct ip configuration."
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

# Ask for the name of the variable "localhost"
echo "Enter a hostname :"
read localhost_name

ipv4_address=$(ifconfig | awk '/inet / && !/127.0.0.1/ {split($2, a, ":"); print a[2]}')

# Regular expression pattern for IPv4 validation
ip_pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

# Check if a valid IP address was found
if ! echo "$ipv4_address" | grep -Eq "$ip_pattern"; then
    echo "Unable to retrieve a valid IP address for the default network interface."
    exit 1
fi

if [ -f "/etc/os-release" ]; then
    # Read the value of the ID field from /etc/os-release
    distribution=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
    
    # Check if the distribution matches Rocky Linux or RHEL to add EPEL
    if [ "$distribution" = "rocky" ]; then
		dnf config-manager --set-enabled crb
		dnf install epel-release
    elif [ "$distribution" = "rhel" ]; then
		subscription-manager repos --enable codeready-builder-for-rhel-9-$(arch)-rpms
		dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    else
        echo "Unknown Linux distribution."
		exit 1
    fi
else
    echo "Unable to determine the Linux distribution."
    exit 1
fi

echo "Grab a cofee..."

# Add Docker's repo
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Add kubernetes' repo
cat > /etc/yum.repos.d/k8s.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Update dnf cache
dnf makecache
dnf makecache --refresh


# Set hostname and modify hosts file accordingly
hostnamectl set-hostname $localhost_name
echo $ipv4_address $localhost_name >> /etc/hosts

# Update packages
dnf update -y

# Install base packages
dnf install git zsh screen htop curl wget

#reboot

# Set SELinux policy
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Add modprobe modules
modprobe overlay
modprobe br_netfilter

# Modify k8s to use modules
cat > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
EOF

# Modify system to add bridging capability
cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Refresh system modules
sysctl --system

# Set swap to 0 (required by kubelet)
swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

# Install container services and tools
dnf install -y containerd.io
dnf install -y {kubelet,kubeadm,kubectl} --disableexcludes=kubernetes

# Add firewall rules for master node
firewall-cmd --permanent --add-port={6443,2379,2380,10250,10251,10252}/tcp
firewall-cmd --reload

# Create containerd's config
mv /etc/containerd/config.toml /etc/containerd/config.toml.orig
containerd config default > /etc/containerd/config.toml

# Modify containerd's config
sudo sed -i 's/^            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml

# Start services
systemctl enable --now containerd.service
systemctl enable --now kubelet.service

# Kubeadm prepare and init
kubeadm config images pull
kubeadm init

# KUBECONFIG export for later use
export KUBECONFIG=/etc/kubernetes/admin.conf

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile.d/k8s.sh

# Install Calico
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

# Get and install HELM
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Add portainer's repo and install it.
helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm upgrade --install --create-namespace -n portainer portainer portainer/portainer
