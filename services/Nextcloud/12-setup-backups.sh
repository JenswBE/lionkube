#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Setup mysqldump for MariaDB
kubectl apply -f ./70-backup-mariadb.yml

# Create SSH key
ssh-keygen -N "" -f "${HOME}/borg-${CLUSTER_NAME:?}-nextcloud"
kubectl create secret generic \
  -n nextcloud \
  borgmatic-ssh-key \
  --from-file=id_rsa="${HOME}/borg-${CLUSTER_NAME:?}-nextcloud"
shred -u "${HOME}/borg-${CLUSTER_NAME:?}-nextcloud"

# --- ACTION REQUIRED ---
# Append contents of ~/borg-${CLUSTER_NAME}-nextcloud.pub to ~/.ssh/authorized_keys on Borg server
sudo less "${HOME}/borg-${CLUSTER_NAME:?}-nextcloud"

# Fill known_hosts file
kubectl create configmap \
  -n nextcloud \
  borgmatic-known-hosts \
  --from-literal=known_hosts="$(ssh-keyscan -p${NEXTCLOUD_BORG_SSH_PORT:?} ${NEXTCLOUD_BORG_SSH_HOST:?})"

# Set mail relay credentials
# See config map borgmatic-mail-config in 80-borgmatic.yml
#     for hostname, port and mail from settings
kubectl create secret generic \
  -n nextcloud \
  borgmatic-mail-creds \
  --from-literal=MAIL_USER=${MAIL_USER:?} \
  --from-literal=MAIL_PASSWORD=${MAIL_PASS:?}

# Set passphrase
kubectl create secret generic \
  -n nextcloud \
  borgmatic-passphrase \
  --from-literal=BORG_PASSPHRASE=${NEXTCLOUD_BORG_PASSPHRASE:?}

# Deploy Borgmatic
../../kube-apply-env ./80-borgmatic.kae.yml

# Check if everything is setup correctly (WARNING: Might run a long time!)
kubectl exec -n nextcloud deploy/borgmatic -- borgmatic --verbosity 1

# Export repo key
kubectl exec -n nextcloud deploy/borgmatic -- sh -c "BORG_RSH=\"ssh -p ${NEXTCLOUD_BORG_SSH_PORT:?}\" borg key export --qr-html \"borg@${NEXTCLOUD_BORG_SSH_HOST}:/backup/${CLUSTER_NAME}-nextcloud\" /tmp/repokey.html"
kubectl exec -n nextcloud deploy/borgmatic -- sh -c 'cat /tmp/repokey.html' -- > "${HOME}/nextcloud-borgmatic-repokey.html"
kubectl exec -n nextcloud deploy/borgmatic -- sh -c 'shred -u /tmp/repokey.html'
