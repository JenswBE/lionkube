# Load me with "source" command of Bash
export CONFIG_SERVICES_LOADED=1

# Borgmatic
export BORGMATIC_SSH_HOST=${STORAGE_BOX_HOST:?}
export BORGMATIC_SSH_PORT=23
export BORGMATIC_SSH_USER=
export BORGMATIC_PASSPHRASE=

# Grafana
export GRAFANA_DOMAIN=grafana.${DEFAULT_DOMAIN}
export GRAFANA_ADMIN_USER=
export GRAFANA_ADMIN_PASS=
export GRAFANA_SMTP_FROM_ADDRESS=grafana-${CLUSTER_MAIL}
export GRAFANA_SMTP_FROM_NAME=Grafana

# Guacamole: LionKube
export GUACAMOLE_DOMAIN=guacamole.${DEFAULT_DOMAIN:?}
export GUACAMOLE_DB_PASS=

# Guacamole: Remote guacd
export GUACAMOLE_GUACD_FLASH_HOST=flash.${DEFAULT_DOMAIN}
export GUACAMOLE_GUACD_FLASH_PORT=
export GUACAMOLE_GUACD_FLASH_USER=

# IMAP Save attachments (ISA)
export ISA_MAIL_HOST=   # IMAP host to watch
export ISA_MAIL_USER=
export ISA_MAIL_PASS=
export ISA_NEXTCLOUD_HOST=
export ISA_NEXTCLOUD_USER=
export ISA_NEXTCLOUD_PASS=
export ISA_SYNC_SUBPATH=Tuinfeest/Inbox  # Path on Nextcloud to sync to. No starting or trailing slash.

# Monitor Temp
export MONITOR_TEMP_INFLUXDB_DOMAIN=influxdb.${DEFAULT_DOMAIN}
export MONITOR_TEMP_INFLUXDB_ADMIN_USER=
export MONITOR_TEMP_INFLUXDB_ADMIN_PASS=

# Nextcloud
export NEXTCLOUD_DOMAIN=nextcloud.${DEFAULT_DOMAIN}
export NEXTCLOUD_DOMAIN_TF=   # Alternative Nextcloud domain
export NEXTCLOUD_STORAGE_BOX_USER=
export NEXTCLOUD_MARIADB_ROOT_PASS=
export NEXTCLOUD_MARIADB_USER_PASS=
export NEXTCLOUD_BORG_SSH_HOST=
export NEXTCLOUD_BORG_SSH_PORT=
export NEXTCLOUD_BORG_PASSPHRASE=

# OpenVPN
export OPENVPN_DOMAIN=openvpn-${CLUSTER_DOMAIN}
export OPENVPN_PORT=1194

# Passit
export PASSIT_BASE_DOMAIN=   # Don't merge with sub domain. Passit needs it separately
export PASSIT_SUB_DOMAIN=
export PASSIT_DOMAIN=${PASSIT_SUB_DOMAIN}.${PASSIT_BASE_DOMAIN}
export PASSIT_DB_PASS=
export PASSIT_SECRET_KEY=
export PASSIT_MAIL_HOST=in-v3.mailjet.com
export PASSIT_MAIL_USER=
export PASSIT_MAIL_PASS=
