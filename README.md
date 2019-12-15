# LionKube
Reference to install and configure a Kubernetes cluster

1. Copy `config.template.sh` to `config.sh` and update accordingly to your needs.
2. Set strict permissions with `chmod 700 config.sh`.

## Components
- [Hetzner Cloud Controller Manager (Hetzner Cloud API integration)](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Hetzner CSI driver (Storage)](https://github.com/hetznercloud/csi-driver)
- [Hetzner Cloud floating IP controller](https://github.com/cbeneke/hcloud-fip-controller/)
- [Canal (Pod Networking)](https://docs.projectcalico.org/v3.10/getting-started/kubernetes/installation/flannel)
- [Metal LB (Bare metal load-balancer)](https://github.com/danderson/metallb)
- [Traefik (Ingress Controller)](https://docs.traefik.io/)
- [Longhorn (Storage provider)](https://github.com/longhorn/longhorn)
- [Weave Scope (Cluster overview)](https://www.weave.works/oss/scope/)

## Big thanks to
- https://community.hetzner.com/tutorials/install-kubernetes-cluster
