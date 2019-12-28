# Load me with "source" command of Bash
export CONFIG_SERVICES_LOADED=1

# Guacamole: LionKube
export GUACAMOLE_DOMAIN=guacamole.${DEFAULT_DOMAIN:?}
export GUACAMOLE_DB_PASS=

# Guacamole: Remote guacd
export GUACAMOLE_GUACD_FLASH_HOST=flash.${DEFAULT_DOMAIN}
export GUACAMOLE_GUACD_FLASH_PORT=
export GUACAMOLE_GUACD_FLASH_USER=

# Home Dashboard
export HOME_DASHBOARD_INFLUXDB_DOMAIN=influxdb.${DEFAULT_DOMAIN}
export HOME_DASHBOARD_INFLUXDB_ADMIN_USER=
export HOME_DASHBOARD_INFLUXDB_ADMIN_PASS=
export HOME_DASHBOARD_GRAFANA_DOMAIN=grafana.${DEFAULT_DOMAIN}
export HOME_DASHBOARD_GRAFANA_ADMIN_USER=
export HOME_DASHBOARD_GRAFANA_ADMIN_PASS=
export HOME_DASHBOARD_GRAFANA_SMTP_FROM_ADDRESS=grafana-${CLUSTER_MAIL}
export HOME_DASHBOARD_GRAFANA_SMTP_FROM_NAME=Grafana

# IMAP Save attachments (ISA)
export ISA_MAIL_HOST=   # IMAP host to watch
export ISA_MAIL_USER=
export ISA_MAIL_PASS=
export ISA_NEXTCLOUD_HOST=
export ISA_NEXTCLOUD_USER=
export ISA_NEXTCLOUD_PASS=
export ISA_SYNC_SUBPATH=Tuinfeest/Inbox  # Path on Nextcloud to sync to. No starting or trailing slash.

# OpenVPN
export OPENVPN_DOMAIN=openvpn-${CLUSTER_DOMAIN}
export OPENVPN_PORT=1194
