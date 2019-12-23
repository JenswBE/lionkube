#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init IMAP Save attachments
kubectl apply -f ./20-namespace.yml

# Create config
# https://github.com/jenswbe/docker-save-attachments
kubectl create secret generic \
  -n isa \
  isa-fetchmailrc \
  --from-literal=.fetchmailrc=$(base64 --wrap=0 <<EOF
poll ${ISA_MAIL_HOST:?} protocol IMAP
        user "${ISA_MAIL_USER:?}" password "${ISA_MAIL_PASS:?}" is root here
no keep
mimedecode
ssl
sslcertck
sslproto TLS1
EOF
)

kubectl create secret generic \
  -n isa \
  isa-rclone \
  --from-literal=.rclone.conf=$(base64 --wrap=0 <<EOF
[nextcloud]
type = webdav
url = https://${ISA_NEXTCLOUD_HOST:?}/remote.php/webdav
vendor = nextcloud
user = ${ISA_NEXTCLOUD_USER:?}
pass = ${ISA_NEXTCLOUD_PASS:?}
EOF
)

# Deploy IMAP Save attachments
../../kube-apply-env ./30-deploy.yml
