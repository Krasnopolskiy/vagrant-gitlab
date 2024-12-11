#!/bin/bash

set -e

wait_for_consul() {
  until curl -s http://${CONSUL_HOST}/v1/status/leader > /dev/null; do
    echo "Waiting for Consul to be ready..."
    sleep 1
  done
}

wait_for_config() {
  while [ ! -f /usr/local/etc/haproxy/haproxy.cfg ]; do
    echo "Waiting for Consul Template to generate haproxy config..."
    sleep 1
  done
}

monitor() {
  consul-template \
    -template "/usr/local/etc/haproxy/haproxy.cfg.ctmpl:/usr/local/etc/haproxy/haproxy.res" \
    -consul-addr ${CONSUL_HOST} \
    -log-level debug

  cat /usr/local/etc/haproxy/haproxy.cfg
}

wait_for_consul

monitor &

wait_for_config

exec "$@"
