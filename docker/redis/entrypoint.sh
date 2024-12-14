#!/bin/bash

set -e

configure_redis() {
    # Get all redis nodes
    REDIS_NODES=$(curl -s "http://${CONSUL_HOST}/v1/catalog/service/redis" | jq -r '.[].ServiceAddress' | sort)

    # Get our own IP
    OWN_IP=$(hostname --ip-address)

    # Determine master based on lexicographically first IP
    MASTER_NODE=$(echo "$REDIS_NODES" | head -n1)

    if [ -z "$MASTER_NODE" ]; then
        echo "No master node found. Waiting..."
        return
    fi

    if [ "$OWN_IP" = "$MASTER_NODE" ]; then
        echo "This node has the lowest IP. Configuring as master..."
        redis-cli -a mypassword --no-auth-warning SLAVEOF NO ONE
        CONSUL_ROLE="master"
    else
        echo "Node $MASTER_NODE should be master. Configuring as slave..."
        redis-cli -a mypassword --no-auth-warning SLAVEOF $MASTER_NODE 6379
        CONSUL_ROLE="slave"
    fi
}

register() {
    while true; do
        # Проверяем и настраиваем роль Redis перед регистрацией
        if [ "${CONSUL_SERVICE_NAME}" = "redis" ]; then
            configure_redis
        fi

        CONSUL_SERVICE_ID="${CONSUL_SERVICE_NAME}/$(hostname)"

        CONSUL_SERVICE_CHECK='
          {
            "TCP": "'$(hostname --ip-address)':'${CONSUL_SERVICE_PORT}'",
            "Interval": "10s",
            "Timeout": "1s",
            "DeregisterCriticalServiceAfter": "30s"
          }
        '

        PAYLOAD='
          {
            "ID": "'${CONSUL_SERVICE_ID}'",
            "Name": "'${CONSUL_SERVICE_NAME}'",
            "Address": "'$(hostname --ip-address)'",
            "Port": '${CONSUL_SERVICE_PORT}',
            "Check": '${CONSUL_SERVICE_CHECK}',
            "EnableTagOverride": true,
            "Tags": []
          }
        '

        if [ "${CONSUL_SERVICE_NAME}" = "sentinel" ]; then
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["traefik.tcp.routers.sentinel.rule=HostSNI(`*`)"]')
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["traefik.tcp.routers.sentinel.entrypoints=sentinel"]')
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["traefik.tcp.services.sentinel.loadbalancer.server.port=26379"]')
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["master"]')
        elif [ "${CONSUL_SERVICE_NAME}" = "redis" ]; then
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["traefik.tcp.routers.redis.rule=HostSNI(`*`)"]')
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["traefik.tcp.routers.redis.entrypoints=redis"]')
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["traefik.tcp.services.redis.loadbalancer.server.port=6379"]')
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags += ["'${CONSUL_ROLE}'"]')
        fi

        curl -s -X PUT -d "${PAYLOAD}" "http://${CONSUL_HOST}/v1/agent/service/register"

        sleep 30
    done
}

deregister() {
    CONSUL_SERVICE_ID=$(hostname)

    echo "Deregistering ${CONSUL_SERVICE_ID} from Consul..."
    curl -s -X PUT "http://${CONSUL_HOST}/v1/agent/service/deregister/${CONSUL_SERVICE_ID}" > /dev/null
    exit 0
}

# Start registration process in background
(
    # Wait for Consul to be ready
    until curl -s "http://${CONSUL_HOST}/v1/status/leader" > /dev/null; do
        echo "Waiting for Consul to be ready..."
        sleep 1
    done

    echo "Starting service registration daemon..."
    register &
) &

trap deregister SIGTERM

exec "$@"