#!/bin/bash

# Load config
source ./00-configuration.sh

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
sudo ufw allow in on ${INT_IF:?} to any port 6443 proto tcp # Kube-api
sudo ufw allow in on ${INT_IF:?} to any port 8472 proto udp # Canal

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
  token: "${HETZNER_API_TOKEN:?}"
  network: "${HETZNER_NETWORK_NAME:?}"
---
apiVersion: v1
kind: Secret
metadata:
  name: hcloud-csi
  namespace: kube-system
stringData:
  token: "${HETZNER_API_TOKEN:?}"
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

# Deploy Metal LB
kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.8.3/manifests/metallb.yaml
cat <<EOF |kubectl apply -f-
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - ${HETZNER_FLOATING_IP:?}
EOF

# Deploy Hetzner Cloud floating IP controller
kubectl create namespace fip-controller
kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/cbeneke/hcloud-fip-controller/master/deploy/deployment.yaml
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: fip-controller-config
  namespace: fip-controller
data:
  config.json: |
    {
      "hcloud_floating_ips": [ "${HETZNER_FLOATING_IP:?}" ],
      "node_address_type": "external"
    }
---
apiVersion: v1
kind: Secret
metadata:
  name: fip-controller-secrets
  namespace: fip-controller
stringData:
  HCLOUD_API_TOKEN: ${HETZNER_API_TOKEN:?}
EOF

# Deploy Traefik
sudo apt install -y apache2-utils
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
data:
  config: |
    entryPoints:
      web:
        address: ":80"
      websecure:
        address: ":443"

    providers:
      file:
        directory: "/traefik/routes/"
        watch: true
      kubernetesIngress:
      kubernetesCRD:

    api:
      dashboard: true

    certificatesResolvers:
      default:
        acme:
          email: ${TRAEFIK_ADMIN_MAIL:?}
          tlschallenge: {}
          storage: acme.json
EOF

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-routers-dashboard
data:
  routers: |
    http:
      routers:
        api:
          rule: Host(\`${TRAEFIK_DASHBOARD_DOMAIN:?}\`)
          service: api@internal
          tls:
            certResolver: default
          middlewares:
            - dashboard-auth
      middlewares:
        dashboard-auth:
          basicAuth:
            usersFile: "/traefik/users/dashboard"
EOF

kubectl create secret generic traefik-users-dashboard --from-literal=users=$(htpasswd -bnBC 10 "${TRAEFIK_DASHBOARD_USER:?}" ${TRAEFIK_DASHBOARD_PASSWORD:?})
kubectl apply -f ../traefik/

# Deploy Longhorn (Storage provider)
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/master/deploy/longhorn.yaml
kubectl delete --namespace=longhorn-system svc longhorn-frontend
cat <<EOF | kubectl apply -f -
kind: Service
apiVersion: v1
metadata:
  labels:
    app: longhorn-ui
  name: longhorn-frontend
  namespace: longhorn-system
spec:
  selector:
    app: longhorn-ui
  ports:
  - port: 80

---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: ingressroutetls
  namespace: default
spec:
  entryPoints:
    - websecure
  routes:
  - match: Host(`your.domain.com`) && PathPrefix(`/tls`)
    kind: Rule
    services:
    - name: whoami
      port: 80
  tls:
    certResolver: default
EOF

# Get latest version of Helm
HELM_PLATFORM=linux-amd64
HELM_VERSION=$(curl -Ls -o /dev/null -w %{url_effective} "https://github.com/helm/helm/releases/latest" | grep -oE "[^/]+$" )
curl "https://get.helm.sh/helm-${HELM_VERSION}-${HELM_PLATFORM}.tar.gz" | sudo tar -xz --overwrite --strip-components 1 -C /usr/local/bin/ linux-amd64/helm
