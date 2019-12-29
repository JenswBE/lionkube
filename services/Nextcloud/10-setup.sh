#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =============================
# = EXECUTE ON WORKER NODE(S) =
# =============================

# Setup Nextcloud folder on Hetzner Storage box
sudo apt install sshfs
sudo mkdir -p /media/nextcloud/data   # Create mount point
sudo mkdir -p /root/ssh_keys          # Create SSH key directory
sudo chmod 700 /root/ssh_keys         # Restrict permissions
sudo ssh-keygen -C "${HOSTNAME}" -N '' -f /root/ssh_keys/nextcloud # Generate SSH key

# --- ACTION REQUIRED ---
# Append contents of /root/ssh_keys/nextcloud.pub to ~/.ssh/authorized_keys on Storage box

ssh-keyscan -p 23 -H ${STORAGE_BOX_HOST:?} | sudo tee /root/.ssh/known_hosts # Add storage box to known_hosts
sudo tee /etc/systemd/system/media-nextcloud-data.mount <<EOF
[Unit]
Description=Mount unit for Nextcloud data

[Mount]
What=${NEXTCLOUD_STORAGE_BOX_USER:?}@${STORAGE_BOX_HOST:?}:./data
Where=/media/nextcloud/data
Type=fuse.sshfs
Options=Port=23,IdentityFile=/root/ssh_keys/nextcloud,allow_other,default_permissions,uid=33,gid=33

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl start media-nextcloud-data.mount
sudo systemctl enable media-nextcloud-data.mount

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Label nodes (repeat for each node you executed above instructions on)
kubectl label nodes <NODE_NAME> mount.media.nextcloud.data=true

# Init Nextcloud
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Set initial passwords for MariaDB
kubectl create secret generic \
  -n nextcloud \
  mariadb-user-root \
  --from-literal=MYSQL_ROOT_PASSWORD=${NEXTCLOUD_MARIADB_ROOT_PASS:?}
kubectl create secret generic \
  -n nextcloud \
  mariadb-user-nextcloud \
  --from-literal=MYSQL_PASSWORD=${NEXTCLOUD_MARIADB_USER_PASS:?}

# Deploy Nextcloud
../../kube-apply-env ./40-mariadb.yml
../../kube-apply-env ./50-nextcloud.yml
../../kube-apply-env ./60-ingress.yml
