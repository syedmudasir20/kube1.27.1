# Let us update and upgrade the packages

sudo apt-get update && sudo apt-get upgrade -y

# Ensure two modules are loaded after reboot

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF


# Disable swap if not on a cloud instance - done anyway

sudo swapoff -a


# Load the modules now

sudo modprobe overlay

sudo modprobe br_netfilter


# Update sysctl to load iptables and ipforwarding

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

#
# Install some necessary software

sudo apt-get install curl apt-transport-https vim git wget  software-properties-common lsb-release ca-certificates  -y

# Install and configure containerd

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  


sudo apt-get update &&  sudo apt-get install containerd.io
sudo containerd config default | sudo tee /etc/containerd/config.toml

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 5
debug: false
EOF

# Get containerd running, append or create several files.
sudo cat <<EOF | sudo tee /etc/containerd/config.toml
version = 2
[plugins."io.containerd.runtime.v1.linux"]
 shim_debug = true
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
 runtime_type = "io.containerd.runc.v2"
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]
 runtime_type = "io.containerd.runsc.v1"
EOF

sleep 10

sudo systemctl daemon-reload
sudo systemctl enable --now containerd

sudo systemctl restart containerd


# Add the Kubernetes repo

sudo sh -c "echo 'deb http://apt.kubernetes.io/ kubernetes-xenial main' >> /etc/apt/sources.list.d/kubernetes.list"


# Add the GPG key for the new repo

sudo sh -c "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -"



# Install the Kubernetes packages

sudo apt-get update

sudo apt-get install -y kubeadm=1.27.1-00 kubelet=1.27.1-00 kubectl=1.27.1-00

sudo apt-mark hold kubelet kubeadm kubectl









