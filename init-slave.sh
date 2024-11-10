#!/bin/bash
set -e

echo "Configuring slave node..."

# Ожидание доступности мастера (с таймаутом)
max_attempts=30
attempt=0
until pg_isready -h "$PRIMARY_HOST" -U "$PGUSER"; do
    attempt=$((attempt + 1))
    if [ $attempt -gt $max_attempts ]; then
        echo "Master node not available after $max_attempts attempts, exiting"
        exit 1
    fi
    echo "Waiting for master to be ready... (attempt $attempt/$max_attempts)"
    sleep 5
done

if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initializing replica from master..."

    # Очистка данных
    rm -rf "$PGDATA"/*

    # Создание базовой копии с мастера
    pg_basebackup -h "$PRIMARY_HOST" -D "$PGDATA" -U "$PGUSER" -P -v -R -X stream

    # Дополнительные настройки реплики
    cat >> "$PGDATA/postgresql.conf" <<EOF
hot_standby = on
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s
hot_standby_feedback = on

# Performance
shared_buffers = 256MB
work_mem = 16MB
maintenance_work_mem = 256MB
effective_cache_size = 1GB
max_connections = 100

# Logging
log_statement = 'none'
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
EOF

else
    echo "Data directory is not empty, skipping initialization"
fi

echo "Slave node configuration completed"