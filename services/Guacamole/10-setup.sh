#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init Guacamole
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Create config
# https://github.com/JenswBE/imap-alerter
kubectl create secret generic \
  -n guacamole \
  guacamole-db-user \
  --from-literal=POSTGRES_USER=guacdb \
  --from-literal=POSTGRES_PASSWORD=${GUACAMOLE_DB_PASS:?}

# Deploy Guacamole
../../kube-apply-env ./40-database.yml
../../kube-apply-env ./50-backend.yml
../../kube-apply-env ./60-frontend.yml
../../kube-apply-env ./70-ingress.yml

# Setup remote guacd through a SSH tunnel
# 1. Generate SSH key
ssh-keygen -N "" -f ${HOME}/guacd-lionkube-flash
# 2. Save private key in secret
kubectl create secret generic -n guacaomle guacd-flash-ssh-key --from-file=id_rsa=${HOME}/guacd-lionkube-flash
# 3. Start SSH tunnel
../../kube-apply-env ./80-ssh-tunnel.yml
# 4. Copy the public key to the target host with `scp <SSH_KEY>.pub <TARGET>:~/`.
#    E.g. `scp guacd-lionkube-flash.pub flash.jensw.be:~/`
# 5. Follow instructions on Flash Gateway
#    https://github.com/JenswBE/flash#ssh-tunnel-for-guacd
