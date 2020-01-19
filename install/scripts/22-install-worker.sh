#!/usr/bin/env bash

# =============================
# = EXECUTE ON WORKER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Firewall
sudo ufw allow in on ${INT_IF:?} to any port 10250 proto tcp # Kubelet
# See ../cloud-init.template.yml for common UFW rules

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
# Either use the join command generated with kubeadm init or generate a new join command with
kubeadm token create --print-join-command # Run on master node
sudo kubeadm join ... # Run on worker node

# Setup Hetzner Storage box: tmp folder
sudo apt install sshfs
sudo mkdir -p /media/tmp # Create mount point
sudo mkdir -p /root/ssh_keys # Create SSH key directory
sudo chmod 700 /root/ssh_keys # Restrict permissions
sudo ssh-keygen -C "${HOSTNAME}" -N '' -f /root/ssh_keys/hetzner-sb-tmp # Generate SSH key

# --- ACTION REQUIRED ---
# Append contents of /root/ssh_keys/hetzner-sb-tmp.pub to ~/.ssh/authorized_keys on Storage box
sudo less /root/ssh_keys/hetzner-sb-tmp.pub

# Add storage box to known_hosts
ssh-keyscan -p 23 -H ${STORAGE_BOX_HOST:?} | sudo tee /root/.ssh/known_hosts

# Mount tmp folder
GID=$(id -g)
sudo tee /etc/systemd/system/media-tmp.mount <<EOF
[Unit]
Description=Mount unit for Tmp folder

[Mount]
What=${STORAGE_BOX_TMP_USER:?}@${STORAGE_BOX_HOST:?}:./
Where=/media/tmp
Type=fuse.sshfs
Options=Port=23,IdentityFile=/root/ssh_keys/hetzner-sb-tmp,allow_other,default_permissions,uid=${UID},gid=${GID}

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start media-tmp.mount
sudo systemctl enable media-tmp.mount
