#!/bin/sh
# Creates the databases required by Kong and Keycloak.
# Runs only on first start, when ./data/postgres/data is empty.
set -e

for db in kong keycloak; do
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
	EOSQL
done
