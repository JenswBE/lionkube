#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init Grafana
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Create config
kubectl create secret generic \
  -n grafana \
  grafana-admin \
  --from-literal=GF_SECURITY_ADMIN_USER=${GRAFANA_ADMIN_USER:?} \
  --from-literal=GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASS:?}
kubectl create secret generic \
  -n grafana \
  grafana-smtp-relay \
  --from-literal=GF_SMTP_HOST=${MAIL_HOST:?}:${MAIL_PORT:?} \
  --from-literal=GF_SMTP_USER=${MAIL_USER:?} \
  --from-literal=GF_SMTP_PASSWORD=${MAIL_PASS:?}
kubectl create configmap \
  -n grafana \
  grafana-smtp-from \
  --from-literal=GF_SMTP_FROM_ADDRESS=${GRAFANA_SMTP_FROM_ADDRESS:?} \
  --from-literal=GF_SMTP_FROM_NAME=${GRAFANA_SMTP_FROM_NAME:?}

# Deploy Grafana
../../kube-apply-env ./40-grafana.kae.yml
../../kube-apply-env ./50-ingress-grafana.kae.yml
