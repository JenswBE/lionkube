#!/bin/bash

# Load config
source ../../config/00-load-config.sh

# Setup user
adduser ${USER:?}
adduser ${USER:?} sudo

# Switch to new user
passwd -ld root

# Update system
sudo apt update
sudo apt dist-upgrade -y

# Add required hosts
echo "10.0.0.2 cluster-endpoint simba
10.0.0.3 timon
10.0.0.4 pumbaa" | sudo tee -a /etc/hosts

# Setup firewall
sudo ufw allow OpenSSH
sudo ufw enable

# Setup Docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install -y docker-ce=18.06.2~ce~3-0~ubuntu
sudo apt-mark hold docker-ce

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
