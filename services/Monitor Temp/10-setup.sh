#!/usr/bin/env bash

# =============================
# = EXECUTE ON MASTER NODE(S) =
# =============================

# Load config
source ../../config/00-load-config.sh

# Init Monitor Temp
kubectl apply -f ./20-namespace.yml
kubectl apply -f ./30-storage.yml

# Create config
kubectl create secret generic \
  -n monitor-temp \
  influxdb-admin \
  --from-literal=INFLUXDB_ADMIN_USER=${HOME_DASHBOARD_INFLUXDB_ADMIN_USER:?} \
  --from-literal=INFLUXDB_ADMIN_PASSWORD=${HOME_DASHBOARD_INFLUXDB_ADMIN_PASS:?}

# Deploy Monitor Temp
../../kube-apply-env ./40-influxdb.yml
../../kube-apply-env ./50-ingress-influxdb.yml

# Configure InfluxDB
set +o history # Disable history
TELEGRAF_PASS=REPLACE_ME
GRAFANA_PASS=REPLACE_ME
set +o history # Enable history

cat <<EOF | kubectl exec -n monitor-temp -i deploy/influxdb -- \
  influx -username "${HOME_DASHBOARD_INFLUXDB_ADMIN_USER:?}" -password "${HOME_DASHBOARD_INFLUXDB_ADMIN_PASS:?}"
-- Create database
CREATE DATABASE "monitor_temp" WITH DURATION 1w NAME "one_week";

-- Create retention period for downsampled data
CREATE RETENTION POLICY "infinite" ON "monitor_temp" DURATION INF REPLICATION 1;

-- Create a continuous query to downsample the data
CREATE CONTINUOUS QUERY "aggr_5min" ON "monitor_temp" BEGIN \
  SELECT mean("temperature") AS "mean_temperature",mean("humidity") AS "mean_humidity", mean("heat-index") AS "mean_heat-index" \
  INTO "infinite"."downsampled_temp" \
  FROM "monitor-temp" \
  GROUP BY time(5m) \
END;

-- Create a user for Telegraf to feed the data
CREATE USER "telegraf_monitor_temp" WITH PASSWORD '${TELEGRAF_PASS}';

-- Grant write rights to Telegraf
GRANT WRITE ON "monitor_temp" TO "telegraf_monitor_temp";

-- Create a user for Grafana to display the data
CREATE USER "grafana" WITH PASSWORD '${GRAFANA_PASS}';

-- Grant read rights to Grafana
GRANT READ ON "monitor_temp" TO "grafana";

EOF
