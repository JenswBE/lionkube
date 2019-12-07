#!/bin/bash

# Settings
USER=<REPLACE_ME>
INT_IF=eth0
EXT_IF=ens10

# Setup user
adduser ${USER}
adduser ${USER} sudo

# Switch to new user
passwd -ld root

# Update system
apt update
apt dist-upgrade -y

# Add required hosts
echo "10.0.0.2   cluster-endpoint" >> /etc/hosts

# Setup firewall
ufw allow OpenSSH
ufw enable

# Kubernetes ports
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
ufw allow in on ${EXT_IF} to any port 10250 proto tcp
# https://help.replicated.com/community/t/managing-firewalls-with-ufw-on-kubernetes/230
ufw allow out on weave to 10.32.0.0/12
ufw allow in on weave from 10.32.0.0/12
ufw allow 6783/udp
ufw allow 6784/udp
ufw allow 6783/tcp

# Setup Docker
apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt install -y docker-ce=18.06.2~ce~3-0~ubuntu
apt-mark hold docker-ce

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker
adduser ${USER} docker

# Setup Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

apt update
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
