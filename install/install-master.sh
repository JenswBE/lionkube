#!/bin/bash

# Config
INT_IF=ens10

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
sudo ufw allow in on ${INT_IF} to any port 8472  proto udp # Canal

# Create Kubernete cluster
sudo kubeadm init --apiserver-advertise-address=10.0.0.2 \
                  --control-plane-endpoint=cluster-endpoint \
                  --ignore-preflight-errors=NumCPU \
                  --pod-network-cidr=10.244.0.0/16

# Copy kubectl config (with regular user)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable kubectl bash completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
source <(kubectl completion bash)

# Canal
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/canal.yaml
kubectl edit configmaps --namespace=kube-system canal-config
# ==> Set under "data" canal_iface: ens10
