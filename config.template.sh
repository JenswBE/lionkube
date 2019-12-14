# General
export USER=REPLACE_ME
export INT_IF=ens10
export EXT_IF=eth0
export DEFAULT_DOMAIN=REPLACE_ME # example.com
export CLUSTER_NAME=lionkube
export CLUSTER_DOMAIN=${CLUSTER_NAME}.${DEFAULT_DOMAIN}

# Hetzner
export HETZNER_API_TOKEN=REPLACE_ME
export HETZNER_NETWORK_NAME=kubernetes
export HETZNER_FLOATING_IP=REPLACE_ME

# Traefik
export TRAEFIK_ADMIN_MAIL=REPLACE_ME
export TRAEFIK_DASHBOARD_DOMAIN=traefik.${CLUSTER_DOMAIN}
export TRAEFIK_DASHBOARD_USER=REPLACE_ME
export TRAEFIK_DASHBOARD_PASSWORD=REPLACE_ME

# Longhorn
export LONGHORN_DOMAIN=longhorn.${CLUSTER_DOMAIN}