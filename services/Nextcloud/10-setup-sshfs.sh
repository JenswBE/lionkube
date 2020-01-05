#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =============================
# = EXECUTE ON WORKER NODE(S) =
# =============================

# Setup Nextcloud folder on Hetzner Storage box
sudo apt install sshfs
sudo mkdir -p /media/nextcloud # Create mount point
sudo mkdir -p /root/ssh_keys # Create SSH key directory
sudo chmod 700 /root/ssh_keys # Restrict permissions
sudo ssh-keygen -C "${HOSTNAME}" -N '' -f /root/ssh_keys/nextcloud # Generate SSH key

# --- ACTION REQUIRED ---
# Append contents of /root/ssh_keys/nextcloud.pub to ~/.ssh/authorized_keys on Storage box

ssh-keyscan -p 23 -H ${STORAGE_BOX_HOST:?} | sudo tee /root/.ssh/known_hosts # Add storage box to known_hosts

# Mount Nextcloud folder
sudo tee /etc/systemd/system/media-nextcloud.mount <<EOF
[Unit]
Description=Mount unit for Nextcloud

[Mount]
What=${NEXTCLOUD_STORAGE_BOX_USER:?}@${STORAGE_BOX_HOST:?}:./
Where=/media/nextcloud
Type=fuse.sshfs
Options=Port=23,IdentityFile=/root/ssh_keys/nextcloud,allow_other,default_permissions,uid=33,gid=33

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start media-nextcloud.mount
sudo systemctl enable media-nextcloud.mount

# Create directories and set permissions (Only on first host)
sudo mkdir -p /media/nextcloud/{data,backup}
sudo chmod 700 /media/nextcloud/{data,backup}

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Assign label to worker node
kubectl label nodes <WORKER_NODE_NAME> mount.media.nextcloud=true
