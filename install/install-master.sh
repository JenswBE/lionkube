#!/bin/bash

# Config
INT_IF=ens10
HETZNER_API_TOKEN=REPLACE_ME
HETZNER_NETWORK_NAME=REPLACE_ME

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
sudo ufw allow in on ${INT_IF} to any port 6443 proto tcp # Kube-api
sudo ufw allow in on ${INT_IF} to any port 8472 proto udp # Canal

# Create Kubernetes config
cat <<EOF > kubeadm-conf.yml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: "external"
  ignorePreflightErrors:
    - NumCPU
localAPIEndpoint:
  advertiseAddress: "10.0.0.2"
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
controlPlaneEndpoint: "cluster-endpoint:6443"
networking:
  podSubnet: 10.244.0.0/16
EOF

# Create Kubernete cluster
sudo kubeadm init --config kubeadm-conf.yml

# Copy kubectl config (with regular user)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Enable kubectl bash completion
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
source <(kubectl completion bash)

# Setup Hetzner secrets
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: hcloud
  namespace: kube-system
stringData:
  token: "${HETZNER_API_TOKEN}"
  network: "${HETZNER_NETWORK_NAME}"
---
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-csi
  namespace: kube-system
stringData:
  token: "${HETZNER_API_TOKEN}"
EOF

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
