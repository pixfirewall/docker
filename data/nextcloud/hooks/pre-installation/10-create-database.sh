#!/bin/sh
# Nextcloud's installer expects the database to exist. The shared postgres service does not
# create it, so create it here (idempotent) before the automatic installation runs.
set -eu

# shellcheck disable=SC2016 # PHP code, the variables are PHP variables
php -r '
$host = getenv("POSTGRES_HOST");
$db   = getenv("POSTGRES_DB");
$pdo  = new PDO("pgsql:host=$host;dbname=postgres", getenv("POSTGRES_USER"), getenv("POSTGRES_PASSWORD"));
$exists = $pdo->query("SELECT 1 FROM pg_database WHERE datname = " . $pdo->quote($db))->fetchColumn();
if (!$exists) {
    $pdo->exec("CREATE DATABASE \"" . str_replace("\"", "\"\"", $db) . "\"");
    echo "created database $db\n";
} else {
    echo "database $db already exists\n";
}
'
