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
  --from-literal=GF_SECURITY_ADMIN_USER=${HOME_DASHBOARD_GRAFANA_ADMIN_USER:?} \
  --from-literal=GF_SECURITY_ADMIN_PASSWORD=${HOME_DASHBOARD_GRAFANA_ADMIN_PASS:?}
kubectl create secret generic \
  -n grafana \
  grafana-smtp-relay \
  --from-literal=GF_SMTP_HOST=${MAIL_HOST:?}:${MAIL_PORT:?} \
  --from-literal=GF_SMTP_USER=${MAIL_USER:?} \
  --from-literal=GF_SMTP_PASSWORD=${MAIL_PASS:?}
kubectl create configmap \
  -n grafana \
  grafana-smtp-from \
  --from-literal=GF_SMTP_FROM_ADDRESS=${HOME_DASHBOARD_GRAFANA_SMTP_FROM_ADDRESS:?} \
  --from-literal=GF_SMTP_FROM_NAME=${HOME_DASHBOARD_GRAFANA_SMTP_FROM_NAME:?}

# Deploy Grafana
../../kube-apply-env ./40-grafana.yml
../../kube-apply-env ./50-ingress-grafana.yml
