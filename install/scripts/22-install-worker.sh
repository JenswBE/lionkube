#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# Firewall
sudo ufw allow in on ${INT_IF:?} to any port 10250 proto tcp # Kubelet
sudo ufw allow in on ${INT_IF:?} to any port 8472  proto udp # Canal

# Set cloud provider to external
cat <<EOF | sudo tee /etc/default/kubelet
KUBELET_EXTRA_ARGS=--cloud-provider=external
EOF

# Restart kubelet
sudo systemctl restart kubelet

# Floating IP
echo -e "auto ${EXT_IF:?}:1
iface ${EXT_IF:?}:1 inet static
  address ${HETZNER_FLOATING_IP:?}
  netmask 32" | sudo tee /etc/network/interfaces.d/60-floating-ip.cfg
sudo systemctl restart networking

# Cluster worker join
sudo kubeadm join cluster-endpoint:6443 --token REPLACE_ME --discovery-token-ca-cert-hash REPLACE_ME
