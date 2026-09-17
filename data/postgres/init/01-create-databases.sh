#!/bin/sh
# Creates databases in the shared postgres (idempotent).
# - on the first start of postgres (docker-entrypoint-initdb.d): the databases of Kong and Keycloak
# - as the `postgres-databases` one-shot (PGHOST/PGPASSWORD set): the databases listed in DATABASES
set -e

for db in ${DATABASES:-kong keycloak}; do
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	SELECT 'CREATE DATABASE "$db"' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
	EOSQL
done
echo "databases ready: ${DATABASES:-kong keycloak}"
