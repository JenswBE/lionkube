#!/usr/bin/env bash
# Based on https://github.com/chepurko/k8s-ovpn

# =============================
# = EXECUTE ON WORKER NODE(S) =
# =============================

# Firewall
sudo ufw allow 1194/udp
sudo ufw route allow in on tun0 out on ${EXT_IF:?}

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Create config dir
DIR_OVPN="${HOME}/ovpn_config"
mkdir "${DIR_OVPN}"

# General arguments
ARG_OVPN="--net=none --log-driver=none --rm -it -v ${DIR_OVPN}:/etc/openvpn kylemanna/openvpn"
ARG_OVPN_ECC="-e EASYRSA_ALGO=ec -e EASYRSA_CURVE=secp384r1 ${ARG_OVPN}"

# Generate configs
# -n: DNS entries for DNS.Watch and CloudFlare
# -e: Extra server option
#    multihome: Required if server is reachable on multiple IP adresses
docker run ${ARG_OVPN} ovpn_genconfig \
    -u udp://${OPENVPN_DOMAIN}:${OPENVPN_PORT} \
    -C 'AES-256-GCM' -a 'SHA384' -T 'TLS-ECDHE-ECDSA-WITH-AES-256-GCM-SHA384' \
    -n 84.200.69.80 -n 84.200.70.40 -n 1.1.1.1 -n 1.0.0.1 \
    -e multihome

# Init PKI
# 1. Enter CA passphrase
# 2. Set CN to OPENVPN_DOMAIN value
docker run ${ARG_OVPN_ECC} ovpn_initpki

# Create client certs (Repeat for each client)
export CLIENTNAME="REPLACE_ME"
docker run ${ARG_OVPN_ECC} easyrsa build-client-full ${CLIENTNAME}
docker run ${ARG_OVPN} ovpn_getclient ${CLIENTNAME} > ~/${CLIENTNAME}.ovpn

# Init Kubernetes
kubectl apply -f ./20-init.yml

# Set owner for server config to self
sudo chown -R ${USER}:${USER} ${DIR_OVPN}/*

# Create secrets and configs
kubectl create secret generic -n openvpn openvpn-key --from-file=${DIR_OVPN}/pki/private/${OPENVPN_DOMAIN}.key
kubectl create secret generic -n openvpn openvpn-cert --from-file=${DIR_OVPN}/pki/issued/${OPENVPN_DOMAIN}.crt
kubectl create secret generic -n openvpn openvpn-pki --from-file=${DIR_OVPN}/pki/ca.crt \
                                                  --from-file=${DIR_OVPN}/pki/dh.pem \
                                                  --from-file=${DIR_OVPN}/pki/ta.key
kubectl create configmap -n openvpn openvpn-conf --from-file=${DIR_OVPN}/
kubectl create configmap -n openvpn openvpn-ccd --from-file=${DIR_OVPN}/ccd

# Deploy OpenVPN
echo "Please, make sure domain \"${OPENVPN_DOMAIN:?}\" is configured in DNS"
kubectl apply -f ./30-deploy.yml
