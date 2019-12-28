#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init Home Dashboard
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Create config
kubectl create secret generic \
  -n home-dashboard \
  influxdb-admin \
  --from-literal=INFLUXDB_ADMIN_USER=${HOME_DASHBOARD_INFLUXDB_ADMIN_USER:?} \
  --from-literal=INFLUXDB_ADMIN_PASSWORD=${HOME_DASHBOARD_INFLUXDB_ADMIN_PASS:?}
kubectl create secret generic \
  -n home-dashboard \
  grafana-admin \
  --from-literal=GF_SECURITY_ADMIN_USER=${HOME_DASHBOARD_GRAFANA_ADMIN_USER:?} \
  --from-literal=GF_SECURITY_ADMIN_PASSWORD=${HOME_DASHBOARD_GRAFANA_ADMIN_PASS:?}
kubectl create secret generic \
  -n home-dashboard \
  grafana-smtp-relay \
  --from-literal=GF_SMTP_HOST=${MAIL_HOST:?}:${MAIL_PORT:?} \
  --from-literal=GF_SMTP_USER=${MAIL_USER:?} \
  --from-literal=GF_SMTP_PASSWORD=${MAIL_PASS:?}
kubectl create configmap \
  -n home-dashboard \
  grafana-smtp-from \
  --from-literal=GF_SMTP_FROM_ADDRESS=${HOME_DASHBOARD_GRAFANA_SMTP_FROM_ADDRESS:?} \
  --from-literal=GF_SMTP_FROM_NAME=${HOME_DASHBOARD_GRAFANA_SMTP_FROM_NAME:?}

# Deploy Home Dashboard
../../kube-apply-env ./40-influxdb.yml
../../kube-apply-env ./50-grafana.yml
../../kube-apply-env ./60-ingress-influxdb.yml
../../kube-apply-env ./61-ingress-grafana.yml
