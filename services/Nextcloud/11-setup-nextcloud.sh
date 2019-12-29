#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Label nodes (repeat for each node you executed above instructions on)
kubectl label nodes <NODE_NAME> mount.media.nextcloud=true

# Init Nextcloud
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Set initial passwords for MariaDB
kubectl create secret generic \
  -n nextcloud \
  mariadb-user-root \
  --from-literal=MYSQL_ROOT_PASSWORD=${NEXTCLOUD_MARIADB_ROOT_PASS:?}
kubectl create secret generic \
  -n nextcloud \
  mariadb-user-nextcloud \
  --from-literal=MYSQL_PASSWORD=${NEXTCLOUD_MARIADB_USER_PASS:?}

# Deploy Nextcloud
../../kube-apply-env ./40-mariadb.yml
../../kube-apply-env ./50-nextcloud.yml
../../kube-apply-env ./60-ingress.yml
