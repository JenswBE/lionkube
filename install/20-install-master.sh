#!/bin/bash

# Load config
source ../config.sh

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
sudo ufw allow in on ${INT_IF:?} to any port 6443 proto tcp # Kube-api
sudo ufw allow in on ${INT_IF:?} to any port 8472 proto udp # Canal

# Create Kubernete cluster
sudo kubeadm init --config ./21-kubeadm-conf.yml

# Copy kubectl config (with regular user)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable kubectl bash completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
source <(kubectl completion bash)

# Setup Hetzner secrets
envsubst < ../components/Hetzner.yml | kubectl apply -f -

# Deploy Hetzner Cloud Controller Manager
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/hcloud-cloud-controller-manager/master/deploy/v1.5.0-networks.yaml

# Canal (Pod Networking)
kubectl apply -f https://docs.projectcalico.org/v3.8/manifests/canal.yaml
kubectl edit configmaps --namespace=kube-system canal-config
# ==> Set under "data" canal_iface: ens10

# Make CoreDNS and Canal tolerate uninitialized nodes
kubectl -n kube-system patch deployment coredns --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'
kubectl -n kube-system patch daemonset canal --type json -p '[{"op":"add","path":"/spec/template/spec/tolerations/-","value":{"key":"node.cloudprovider.kubernetes.io/uninitialized","value":"true","effect":"NoSchedule"}}]'

# Deploy Hetzner CSI driver
kubectl apply -f https://raw.githubusercontent.com/hetznercloud/csi-driver/v1.2.2/deploy/kubernetes/hcloud-csi.yml

# Deploy Metal LB
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
envsubst < ../components/MetalLB.yml | kubectl apply -f -

# Deploy Hetzner Cloud floating IP controller
kubectl create namespace fip-controller
kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/deployment.yaml

# Deploy Traefik
sudo apt install -y apache2-utils
kubectl apply -f ../components/Traefik/00-definitions.yml
envsubst < ../components/Traefik/01-config.yml | kubectl apply -f -
kubectl create secret generic traefik-users-dashboard --from-literal=users=$(htpasswd -bnBC 10 "${TRAEFIK_DASHBOARD_USER:?}" ${TRAEFIK_DASHBOARD_PASSWORD:?})
kubectl apply -f ../components/Traefik/02-services.yml
kubectl apply -f ../components/Traefik/03-deployment.yml

# Deploy Longhorn (Storage provider)
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
kubectl delete --namespace=longhorn-system svc longhorn-frontend
envsubst < ../components/Longhorn.yml | kubectl apply -f -

# Get latest version of Helm
HELM_PLATFORM=linux-amd64
HELM_VERSION=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/helm/helm/releases/latest" | grep -oE "[^/]+$" )
curl "https://get.helm.sh/helm-${HELM_VERSION}-${HELM_PLATFORM}.tar.gz" | sudo tar -xz --overwrite --strip-components 1 -C /usr/local/bin/ linux-amd64/helm