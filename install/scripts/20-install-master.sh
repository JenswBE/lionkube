#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
sudo ufw allow in on ${INT_IF:?} to any port 6443 proto tcp # Kube-api
sudo ufw allow in on ${INT_IF:?} to any port 8472 proto udp # Canal
sudo ufw allow in on ${INT_IF:?} to any port 7472 proto tcp # MetalLB

# Create Kubernete cluster
sudo kubeadm init --config ./21-kubeadm-conf.yml

# Copy kubectl config (with regular user)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable kubectl bash completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
source <(kubectl completion bash)

# =============================
# = EXECUTE ON WORKER NODE(S) =
# =============================
# See 22-install-workers.sh

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Setup Hetzner secrets and namespaces
../../kube-apply-env ../components/Hetzner.yml

# Deploy Hetzner Cloud Controller Manager
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/master/deploy/v1.5.0-networks.yaml

# Canal (Pod Networking)
kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/canal.yaml
kubectl edit configmaps --namespace=kube-system canal-config
# ==> Set under "data" canal_iface: ens10

# Deploy Hetzner CSI driver
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.2.2/deploy/kubernetes/hcloud-csi.yml

# Deploy Hetzner Cloud floating IP controller
kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/daemonset.yaml

# Deploy Metal LB
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
../../kube-apply-env ../components/MetalLB.yml

# Deploy Cert-manager
kubectl create namespace cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.12.0/cert-manager.yaml
../../kube-apply-env ../components/Cert-manager.yml

# Deploy Traefik
echo "Please, make sure domain \"${TRAEFIK_API_DOMAIN:?}\" is configured in DNS"
sudo apt install -y apache2-utils
kubectl apply -f ../components/Traefik/00-crd.yml
kubectl apply -f ../components/Traefik/01-config.yml
kubectl create secret generic --namespace=traefik traefik-users-api \
    --from-literal=users="$(htpasswd -bnBC 10 "${TRAEFIK_API_USER:?}" ${TRAEFIK_API_PASSWORD:?} | tr -d '\n')"
kubectl apply -f ../components/Traefik/02-services.yml
kubectl apply -f ../components/Traefik/03-deployment.yml
../../kube-apply-env ../components/Traefik/04-api.yml
../../kube-apply-env ../components/Traefik/05-ping.yml

# Deploy Longhorn (Storage provider)
echo "Please, make sure domain \"${LONGHORN_DOMAIN:?}\" is configured in DNS"
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
kubectl delete --namespace=longhorn-system svc longhorn-frontend
kubectl create secret generic --namespace=longhorn-system traefik-users-longhorn \
    --from-literal=users="$(htpasswd -bnBC 10 "${LONGHORN_USER:?}" ${LONGHORN_PASSWORD:?} | tr -d '\n')"
../../kube-apply-env ../components/Longhorn.yml

# Set backup credentials
kubectl create secret generic minio-secret \
    --namespace=longhorn-system \
    --from-literal=AWS_ENDPOINTS="${LONGHORN_BACKUP_S3_ENDPOINT:?}" \
    --from-literal=AWS_ACCESS_KEY_ID="${LONGHORN_BACKUP_S3_ACCESS_KEY:?}" \
    --from-literal=AWS_SECRET_ACCESS_KEY="${LONGHORN_BACKUP_S3_SECRET_KEY:?}"

# Action Required
# In Longhorn Settings => General, set following values:
# Backup Target: s3://<BUCKET_NAME>@minio/
# Backup Target Credential Secret: minio-secret

# Set Longhorn as default storage class
kubectl patch storageclass hcloud-volumes -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Get latest version of Helm
HELM_PLATFORM=linux-amd64
HELM_VERSION=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/helm/helm/releases/latest" | grep -oE "[^/]+$" )
curl "https://get.helm.sh/helm-${HELM_VERSION}-${HELM_PLATFORM}.tar.gz" | sudo tar -xz --overwrite --strip-components 1 -C /usr/local/bin/ linux-amd64/helm
