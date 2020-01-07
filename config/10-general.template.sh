# Load me with "source" command of Bash
export CONFIG_GENERAL_LOADED=1

# General
export USER=REPLACE_ME
export INT_IF=ens10
export EXT_IF=eth0
export DEFAULT_DOMAIN=REPLACE_ME # example.com
export CLUSTER_NAME=lionkube
export CLUSTER_DOMAIN=${CLUSTER_NAME}.${DEFAULT_DOMAIN}
export ADMIN_MAIL=REPLACE_ME
export CLUSTER_MAIL=${CLUSTER_NAME}@${DEFAULT_DOMAIN}
export TIMEZONE=Europe/Brussels

# Mail relay
export MAIL_HOST=in-v3.mailjet.com
export MAIL_PORT=587
export MAIL_USER=
export MAIL_PASS=

# Hetzner Storage box
export STORAGE_BOX_HOST=
export STORAGE_BOX_TMP_USER=
