#!/bin/bash

# Cluster worker join
kubeadm join cluster-endpoint:6443 --token ilcokw.423bkb8y4yll10c2 \
    --discovery-token-ca-cert-hash sha256:8dc950495ea73ed02bc79e1de53fefb8fcb035c6727577d679184df191632d3d
