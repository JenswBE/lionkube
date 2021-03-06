#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init Passit
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Create config
kubectl create secret generic \
  -n passit \
  postgresql-password \
  --from-literal=POSTGRES_PASSWORD=${PASSIT_DB_PASS:?}
kubectl create secret generic \
  -n passit \
  passit-secret-key \
  --from-literal=SECRET_KEY=${PASSIT_SECRET_KEY:?}
kubectl create secret generic \
  -n passit \
  passit-email-url \
  --from-literal=EMAIL_URL="smtp+tls://${PASSIT_MAIL_USER:?}:${PASSIT_MAIL_PASS:?}@${PASSIT_MAIL_HOST:?}:587"
kubectl create secret generic \
  -n passit \
  backup-postgresql-pgpass \
  --from-literal=pgpass=postgresql:5432:passit:passit:${PASSIT_DB_PASS:?}
  # hostname:port:database:username:password

# Deploy Passit
../../kube-apply-env ./40-postgresql.kae.yml
../../kube-apply-env ./50-passit.kae.yml
../../kube-apply-env ./60-ingress.kae.yml
kubectl apply -f ./70-backup-postgresql.yml
