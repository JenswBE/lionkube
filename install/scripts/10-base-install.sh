#!/usr/bin/env bash

# ==============================
# =    EXECUTE ON EACH NODE    =
# ==============================

# Load config
source ../../config/00-load-config.sh

# Setup user
adduser ${USER:?}
adduser ${USER:?} sudo

# Switch to new user
sudo passwd -ld root

# Update system
sudo apt update
sudo apt dist-upgrade -y

# Add required hosts
sudo tee -a /etc/hosts <<EOF
10.0.0.2 cluster-endpoint simba
10.0.0.3 pumbaa
10.0.0.4 timon
10.0.0.5 nala
EOF

# Setup firewall
sudo ufw allow OpenSSH
sudo ufw enable

# Setup Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# Check latest docker version with `apt-cache madison docker-ce`
sudo apt install docker-ce=5:19.03.5~3-0~ubuntu-bionic docker-ce-cli=5:19.03.5~3-0~ubuntu-bionic containerd.io

# Pin docker version
sudo tee /etc/apt/preferences.d/docker <<EOF
Package: docker-ce
Pin: version 5:19.03.*
Pin-Priority: 1001

Package: docker-ce-cli
Pin: version 5:19.03.*
Pin-Priority: 1001
EOF

sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo adduser ${USER:?} docker

# Setup Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
