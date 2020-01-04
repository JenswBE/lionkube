#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Add Loki helm repo
helm repo add loki https://grafana.github.io/loki/charts
helm repo update

# Install Loki
helm install loki --namespace=logging loki/loki-stack

# Add Loki to Grafana as Datasource
