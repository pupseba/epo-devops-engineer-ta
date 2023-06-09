#!/bin/bash

HOSTNAME=$(hostname)

# Executes always

## Prepares system
apt-get update -y
apt install apt-transport-https -y

## Installs kubernetes packages
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt install kubelet kubeadm kubectl -y
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

## Installs containerd
modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sysctl --system

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository --yes "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install containerd.io -y
containerd config default>/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: true
pull-image-on-create: false
disable-pull-on-run: false
EOF

systemctl restart containerd ; systemctl enable containerd

# Executes code depending on the node it is running on
if [[ $HOSTNAME == "master01" ]]; then
  kubeadm init --control-plane-endpoint=master01 --pod-network-cidr=192.168.0.0/16 &> /tmp/kubeadm_output
  sleep 90
  mkdir -p /root/.kube
  cp -i /etc/kubernetes/admin.conf /root/.kube/config
  chown $(id -u):$(id -g) /root/.kube/config
  echo "Kubernetes cluster is ready" > /tmp/cluster_ready
  sleep 90
  echo "Sleep is over" >> /tmp/cluster_ready
  kubectl --kubeconfig=/root/.kube/config apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml
  echo "K8s install dashboard" >> /tmp/cluster_ready
  kubectl --kubeconfig=/root/.kube/config apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
  echo "Prepare k8s dashboard" >> /tmp/cluster_ready
  kubectl --kubeconfig=/root/.kube/config apply -f /tmp/yamls/k8s_dashboard.yaml
  echo "Deploy elastic operator" >> /tmp/cluster_ready
  kubectl create -f https://download.elastic.co/downloads/eck/2.7.0/crds.yaml
  kubectl apply -f https://download.elastic.co/downloads/eck/2.7.0/operator.yaml
  echo "Deploy logging-system" >> /tmp/cluster_ready
  sleep 30
  kubectl --kubeconfig=/root/.kube/config apply -f /tmp/yamls/logging.yaml
  echo "Finished" >> /tmp/cluster_ready

elif [[ $HOSTNAME == master* ]]; then
  if [[ $HOSTNAME != "master01" ]]; then
  sleep 180
  ssh -i /tmp/core -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel=ERROR" core@master01 'cat /tmp/kubeadm_output | tail -n2' | bash -s -- --control-plane
  sleep 180
  mkdir -p /root/.kube
  cp -i /etc/kubernetes/admin.conf /root/.kube/config
  chown $(id -u):$(id -g) /root/.kube/config
  fi
elif [[ $HOSTNAME == worker* ]]; then
  sleep 180
  ssh -i /tmp/core -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel=ERROR" core@master01 'cat /tmp/kubeadm_output | tail -n2' | bash
fi
