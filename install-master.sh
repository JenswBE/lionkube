#!/bin/bash

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
ufw allow in on ${EXT_IF} to any port 6443 proto tcp
ufw allow out on ens10 to 10.0.0.0/12 port 10250 proto tcp

# Create Kubernete cluster (Control plane only)
kubeadm init --apiserver-advertise-address=10.0.0.2 --control-plane-endpoint=cluster-endpoint --ignore-preflight-errors=NumCPU

# Copy kubectl config (with regular user)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Weave Net
echo "net.bridge.bridge-nf-call-iptables=1" >> /etc/sysctl.d/10-kubernetes.conf
sysctl -p --system
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
