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
helm install prometheus stable/prometheus --version 9.7.4 -n monitoring -f ./30-values-prometheus.yml
