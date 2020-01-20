#!/usr/bin/env bash

# Load config
source ../../config/00-load-config.sh

# =====================================
# =     EXECUTE ON MASTER NODE(S)     =
# =====================================

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
../../kube-apply-env ./40-mariadb.kae.yml
../../kube-apply-env ./50-nextcloud.kae.yml
../../kube-apply-env ./60-ingress.kae.yml

# Check which host is running the Nextcloud pod
kubectl get pod -n nextcloud --selector=app=nextcloud -o wide

# =====================================
# = EXECUTE ON NODE RUNNING NEXTCLOUD =
# =====================================
# Currently kubectl doesn't support running exec as another user.
# Therefore, you have to execute below commands directly on the
# worker node.
# See https://github.com/kubernetes/kubernetes/issues/30656 for more info

# Get container name
NC_CONTAINER=$(docker ps | grep nextcloud_nextcloud | cut -f1 -d" ")

# Set trusted domains
docker exec -u www-data ${NC_CONTAINER} php occ config:system:set trusted_domains 0 --value="${NEXTCLOUD_DOMAIN:?}"
docker exec -u www-data ${NC_CONTAINER} php occ config:system:set trusted_domains 1 --value="${NEXTCLOUD_DOMAIN_TF:?}"

# Fix reverse proxy handling
docker exec -u www-data ${NC_CONTAINER} php occ config:system:set overwriteprotocol --value="https"
docker exec -u www-data ${NC_CONTAINER} php occ config:system:set trusted_proxies 0 --value="172.16.0.0/12"

# =====================================
# =        CONFIGURE NEXTCLOUD        =
# =====================================
# Disable following apps:
# - First run wizard
#
# Install and configure following apps:
# - Contacts
# - Calendar
# - Tasks
# - Notes
# - Group folders
# - Quota warning
# - Preview generator
# - AppOrder
