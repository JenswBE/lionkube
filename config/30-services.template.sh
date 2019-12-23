# Load me with "source" command of Bash
export CONFIG_SERVICES_LOADED=1

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
