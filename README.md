# LionKube
Reference to install and configure a Kubernetes cluster

1. Clone this repo to your intended master node machine
2. Copy `xx-<CONFIG>.template.sh` to `xx-<CONFIG>.sh` and update accordingly to your needs.
3. Set strict permissions with `chmod 700 -R config/`.

## Components
Below components are basic building blocks to provide a fully functional cluster.

- [Hetzner Cloud Controller Manager (Hetzner Cloud API integration)](https://github.com/hetznercloud/hcloud-cloud-controller-manager)
- [Hetzner CSI driver (Storage)](https://github.com/hetznercloud/csi-driver)
- [Hetzner Cloud floating IP controller](https://github.com/cbeneke/hcloud-fip-controller/)
- [Canal (Pod Networking)](https://docs.projectcalico.org/v3.10/getting-started/kubernetes/installation/flannel)
- [Metal LB (Bare metal load-balancer)](https://github.com/danderson/metallb)
- [Traefik (Ingress Controller)](https://docs.traefik.io/)
- [Longhorn (Storage provider)](https://github.com/longhorn/longhorn)

## Services
Following services are the actual services I want to host on the cluster.

- [Grafana](https://grafana.com/): Dashboard for cluster monitoring and home temperature monitoring
- [Guacamole](https://guacamole.apache.org/): Remote desktop gateway for SSH hosts
- [IMAP Alerter](https://github.com/JenswBE/imap-alerter): Sends a notification to my main account, in case there is a mail
  on a secondary account
- [IMAP Save attachments (ISA)](https://github.com/JenswBE/docker-save-attachments): Save all attachments which are sent to a mailbox
  to Nextcloud (or any other Rsync supported storage)
- [Monitor Temp](https://github.com/JenswBE/flash): InfluxDB to store my temperature at home. Temperature is measured with ESP32's and broadcasted over MQTT. Telegraf consumes the data and inserts it into this InfluxDB. Results are shown on a Grafana dashboard.
- [Monitoring](https://hub.helm.sh/charts/stable/prometheus): Prometheus deployment to monitor the cluster
- [Nextcloud](https://nextcloud.com/): Private cloud to store files, contacts, calendars and tasks
- [OpenVPN](https://openvpn.net/): Protects internet traffic on insecure networks
- [Passit](https://passit.io/): Shared password manager

## Scheduled jobs

### Continuous
- Every 5 mins: Nextcloud cron.php (services/Nextcloud/50-nextcloud.yml: cron)
- Every 10 mins: Nextcloud generate previews (services/Nextcloud/50-nextcloud.yml: cron)

### 01:00 Daily application jobs
- None

### 02:00 Prepare backup
- 02:00 Dump Nextcloud DB (services/Nextcloud/70-backup-mariadb.yml)
- 02:05 Dump Nextcloud calendars and contacts (services/Nextcloud/50-nextcloud.yml: backup-calcard)
- 02:15 Dump Passit DB (services/Passit/71-backup-postgresql.yml)

### 03:00 Perform backup
- 03:00 Run global Borgmatic (services/Borgmatic/30-borgmatic.yml)
- 03:30 Run Borgmatic for Nextcloud (services/Nextcloud/80-borgmatic.yml)

### 04:00 Perform application updates
- 04:30 Update all Nextcloud apps (services/Nextcloud/50-nextcloud.yml)

### System tasks
- None

## Big thanks to
- https://community.hetzner.com/tutorials/install-kubernetes-cluster
- https://github.com/chepurko/k8s-ovpn
