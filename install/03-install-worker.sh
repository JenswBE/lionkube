#!/bin/bash

# Load config
source ./00-configuration.sh

# Firewall
sudo ufw allow in on ${INT_IF:?} to any port 10250 proto tcp # Kubelet
sudo ufw allow in on ${INT_IF:?} to any port 8472  proto udp # Canal

# Set cloud provider to external
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--cloud-provider=external
EOF

# Cluster worker join
sudo kubeadm join cluster-endpoint:6443 --token ilcokw.423bkb8y4yll10c2 \
    --discovery-token-ca-cert-hash sha256:8dc950495ea73ed02bc79e1de53fefb8fcb035c6727577d679184df191632d3d

# Floating IP
echo -e "auto ${EXT_IF:?}:1
iface ${EXT_IF:?}:1 inet static
  address ${HETZNER_FLOATING_IP:?}
  netmask 32" | sudo tee /etc/network/interfaces.d/60-floating-ip.cfg
sudo systemctl restart networking
