#!/bin/bash

set -e

register() {
    while true; do
        CONSUL_ROLE=$(
          redis-cli -a mypassword --no-auth-warning info replication |
            grep "role:" |
            cut -d: -f2 |
            tr -d '[:space:]'
        )

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
            "Name": "'${CONSUL_SERVICE_NAME}'",
            "ID": "'${CONSUL_SERVICE_ID}'",
            "Port": '${CONSUL_SERVICE_PORT}',
            "Check": '${CONSUL_SERVICE_CHECK}',
            "EnableTagOverride": true
          }
        '

        if [ -n "${CONSUL_ROLE}" ]; then
            PAYLOAD=$(echo $PAYLOAD | jq '.Tags = ["'${CONSUL_ROLE}'"]')
        fi

        curl -s -X PUT -d "${PAYLOAD}" "http://${CONSUL_HOST}/v1/agent/service/register"

        # Sleep for 30 seconds before next registration attempt
        # This helps maintain registration and handles consul restarts
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