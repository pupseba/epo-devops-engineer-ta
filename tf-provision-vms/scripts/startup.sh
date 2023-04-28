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
systemctl restart containerd ; systemctl enable containerd

# Executes code depending on the node it is running on
if [[ $HOSTNAME == "master01" ]]; then
  kubeadm init --control-plane-endpoint=master01 --pod-network-cidr=172.17.128.0/18 | tee /tmp/kubeadm_output
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
elif [[ $HOSTNAME == master* ]]; then
  if [[ $HOSTNAME != "master01"]]; then
  ssh -i /tmp/core -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel=ERROR" core@master01 'cat /tmp/kubeadm_output | tail -n2' | bash -s -- --control-plane
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
  fi
elif [[ $HOSTNAME == worker* ]]; then
  ssh -i /tmp/core -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -o "LogLevel=ERROR" core@master01 'cat /tmp/kubeadm_output | tail -n2' | bash
fi
