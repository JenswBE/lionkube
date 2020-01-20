#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init IMAP Alerter
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Create config
# https://github.com/JenswBE/imap-alerter
kubectl create secret generic \
  -n imap-alerter \
  imap-alerter-config \
  --from-file=config.yaml=${HOME:?}/imap-alerter.yml

# Deploy IMAP Alerter
../../kube-apply-env ./40-deploy.kae.yml
