#!/bin/bash

# Weave Net
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.d/10-kubernetes.conf
sudo sysctl -p --system

# Cluster worker join
sudo kubeadm join cluster-endpoint:6443 --token ilcokw.423bkb8y4yll10c2 \
    --discovery-token-ca-cert-hash sha256:8dc950495ea73ed02bc79e1de53fefb8fcb035c6727577d679184df191632d3d
