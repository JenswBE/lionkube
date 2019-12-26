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
