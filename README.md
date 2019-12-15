# LionKube
Reference to install and configure a Kubernetes cluster

1. Copy `xx-<CONFIG>.template.sh` to `xx-<CONFIG>.sh` and update accordingly to your needs.
2. Set strict permissions with `chmod 700 -R config/`.

## Components
Below components are basic building blocks to provide a fully functional cluster.

- [Hetzner Cloud Controller Manager (Hetzner Cloud API integration)](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Hetzner CSI driver (Storage)](https://github.com/hetznercloud/csi-driver)
- [Hetzner Cloud floating IP controller](https://github.com/cbeneke/hcloud-fip-controller/)
- [Canal (Pod Networking)](https://docs.projectcalico.org/v3.10/getting-started/kubernetes/installation/flannel)
- [Metal LB (Bare metal load-balancer)](https://github.com/danderson/metallb)
- [Traefik (Ingress Controller)](https://docs.traefik.io/)
- [Longhorn (Storage provider)](https://github.com/longhorn/longhorn)

## Services
Following services are the actual services I want to host on the cluster.

- OpenVPN

## Big thanks to
- https://community.hetzner.com/tutorials/install-kubernetes-cluster
- https://github.com/chepurko/k8s-ovpn
