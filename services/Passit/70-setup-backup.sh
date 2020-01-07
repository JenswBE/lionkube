#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =====================================
# =      EXECUTE ON A WORKER NODE     =
# =====================================

# Create directory to store backup
sudo mkdir -p /media/tmp/backup/passit

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Create config
kubectl create secret generic \
  -n passit \
  backup-postgresql-pgpass \
  --from-literal=pgpass=postgresql:5432:passit:passit:${PASSIT_DB_PASS:?}
  # hostname:port:database:username:password

# Deploy backup
kubectl apply -f ./30-storage.yml
