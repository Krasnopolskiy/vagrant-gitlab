#!/bin/bash
set -e

echo "Configuring master node..."

# Создание пользователя для репликации
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER repl_user WITH REPLICATION PASSWORD 'repl_password';
EOSQL

# Настройка конфигурации PostgreSQL
cat >> "$PGDATA/postgresql.conf" <<EOF
# Replication
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
hot_standby = on
synchronous_commit = off

# Performance
shared_buffers = 256MB
work_mem = 16MB
maintenance_work_mem = 256MB
effective_cache_size = 1GB
max_connections = 100

# Checkpoint
checkpoint_timeout = 1h
max_wal_size = 1GB
min_wal_size = 80MB

# Logging
log_statement = 'none'
log_min_duration_statement = 1000
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0
EOF

# Настройка доступа для репликации
cat >> "$PGDATA/pg_hba.conf" <<EOF
host replication repl_user all md5
host all all all md5
EOF

echo "Master node configuration completed"