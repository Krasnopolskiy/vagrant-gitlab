#!/bin/sh

readonly CONTAINER_IP=$(hostname --ip-address)
readonly POSTGRES_ADDR="${CONTAINER_IP}:5432"
readonly API_PORT="${PATRONI_API_PORT:-8091}"
readonly API_ADDR="${CONTAINER_IP}:${API_PORT}"

export PATRONI_NAME="${PATRONI_NAME:-$(hostname)}"
export PATRONI_RESTAPI_LISTEN="$API_ADDR"
export PATRONI_RESTAPI_CONNECT_ADDRESS="$API_ADDR"
export PATRONI_RESTAPI_USERNAME="${PATRONI_RESTAPI_USERNAME:-patroni}"
export PATRONI_RESTAPI_PASSWORD="${PATRONI_RESTAPI_PASSWORD:-patroni}"

export PATRONI_POSTGRESQL_CONNECT_ADDRESS="$POSTGRES_ADDR"
export PATRONI_POSTGRESQL_LISTEN="$POSTGRES_ADDR"

export PATRONI_REPLICATION_USERNAME="${REPLICATION_USERNAME:-replicator}"
export PATRONI_REPLICATION_PASSWORD="${REPLICATION_PASSWORD:-replicator}"

export PATRONI_SUPERUSER_USERNAME="${SUPERUSER_USERNAME:-postgres}"
export PATRONI_SUPERUSER_PASSWORD="${SUPERUSER_PASSWORD:-postgres}"

exec /usr/local/bin/patroni /etc/patroni.yml
