#!/usr/bin/env bash

# ==============================
# =    EXECUTE ON EACH NODE    =
# ==============================

# Load config
source ../../config/00-load-config.sh

# Firewall (Execute on each node)
sudo ufw allow in on ${INT_IF:?} to any port 9100 proto tcp # Node exporter

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Install Prometheus
kubectl apply -f ./20-namespace.yml
helm install prometheus stable/prometheus --version 10.3.1 -n monitoring -f ./30-values-prometheus.yml
