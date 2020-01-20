data#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =============================
# = EXECUTE ON WORKER NODE(S) =
# =============================

# Setup Nextcloud folder on Hetzner Storage box
sudo mkdir -p /data/nextcloud # Create mount point
sudo ssh-keygen -C "${HOSTNAME}" -N '' -f /root/ssh_keys/hetzner-sb-nextcloud # Generate SSH key

# --- ACTION REQUIRED ---
# Append contents of /root/ssh_keys/hetzner-sb-nextcloud.pub to ~/.ssh/authorized_keys on Storage box
sudo less /root/ssh_keys/hetzner-sb-nextcloud.pub

# Add storage box to known_hosts
ssh-keyscan -p 23 -H ${STORAGE_BOX_HOST:?} | sudo tee /root/.ssh/known_hosts

# Mount Nextcloud folder
sudo tee /etc/systemd/system/data-nextcloud.mount <<EOF
[Unit]
Description=Mount unit for Nextcloud

[Mount]
What=${NEXTCLOUD_STORAGE_BOX_USER:?}@${STORAGE_BOX_HOST:?}:./
Where=/data/nextcloud
Type=fuse.sshfs
Options=Port=23,IdentityFile=/root/ssh_keys/hetzner-sb-nextcloud,allow_other,default_permissions,uid=33,gid=33

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start data-nextcloud.mount
sudo systemctl enable data-nextcloud.mount

# Create directories and set permissions (Only on first host)
sudo mkdir -p /data/nextcloud/{data,backup}
sudo chmod 700 /data/nextcloud/{data,backup}

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Assign label to worker node
kubectl label nodes <WORKER_NODE_NAME> mount.data.nextcloud=true
