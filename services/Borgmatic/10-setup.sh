#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =====================================
# =      EXECUTE ON A WORKER NODE     =
# =====================================
# Create directory to store files to backup
sudo mkdir -p /media/tmp/backup
sudo chmod 700 /media/tmp/backup

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Init Borgmatic
kubectl apply -f ./20-namespace.yml

# Create SSH key
ssh-keygen -N "" -f "${HOME}/borg-${CLUSTER_NAME:?}"
kubectl create secret generic \
  -n borgmatic \
  borgmatic-ssh-key \
  --from-file=id_rsa="${HOME}/borg-${CLUSTER_NAME:?}"

# Fill known_hosts file
kubectl create configmap \
  -n borgmatic \
  borgmatic-known-hosts \
  --from-literal=known_hosts="$(ssh-keyscan -p${BORGMATIC_SSH_PORT:?} ${BORGMATIC_SSH_HOST:?})"

# Set mail relay credentials
# See config map borgmatic-mail-config in 80-borgmatic.yml
#     for hostname, port and mail from settings
kubectl create secret generic \
  -n borgmatic \
  borgmatic-mail-creds \
  --from-literal=MAIL_USER=${MAIL_USER:?} \
  --from-literal=MAIL_PASSWORD=${MAIL_PASS:?}

# Set passphrase
kubectl create secret generic \
  -n borgmatic \
  borgmatic-passphrase \
  --from-literal=BORG_PASSPHRASE=${BORGMATIC_PASSPHRASE:?}

# Deploy Borgmatic
../../kube-apply-env ./30-borgmatic.yml

# Check if everything is setup correctly (WARNING: Might run a long time!)
kubectl exec -n borgmatic deploy/borgmatic -- borgmatic --verbosity 1

# Export repo key
kubectl exec -n borgmatic deploy/borgmatic -- sh -c "BORG_RSH=\"ssh -p ${NEXTCLOUD_BORG_SSH_PORT:?}\" borg key export --qr-html \"borg@${NEXTCLOUD_BORG_SSH_HOST}:/backup/${CLUSTER_NAME}-nextcloud\" /tmp/repokey.html"
kubectl exec -n borgmatic deploy/borgmatic -- sh -c 'cat /tmp/repokey.html' -- > "${HOME}/nextcloud-borgmatic-repokey.html"
kubectl exec -n borgmatic deploy/borgmatic -- sh -c 'shred -u /tmp/repokey.html'
