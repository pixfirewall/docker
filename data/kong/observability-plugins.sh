#!/bin/sh
# Enables Kong's prometheus and opentelemetry plugins globally.
# PUT with fixed ids creates or updates the plugins, so running it again is safe.
set -eu

KONG_ADMIN_URL="${KONG_ADMIN_URL:-http://kong:8001}"

upsert_plugin() {
    id="$1"
    body="$2"
    status=$(curl -s -o /tmp/response -w '%{http_code}' -X PUT "${KONG_ADMIN_URL}/plugins/${id}" \
        -H 'content-type: application/json' -d "${body}")
    case "${status}" in
        200|201) echo "plugin ${id}: ok (${status})" ;;
        *) echo "plugin ${id}: failed (${status})" >&2; cat /tmp/response >&2; exit 1 ;;
    esac
}

upsert_plugin 0b4e3a2c-7d1f-4c55-9a8e-1f2d3c4b5a60 '{
  "name": "prometheus",
  "config": {
    "status_code_metrics": true,
    "latency_metrics": true,
    "bandwidth_metrics": true,
    "upstream_health_metrics": true
  }
}'

# Kong >= 3.8 renamed `endpoint` to `traces_endpoint`
upsert_plugin 6c1d9e8f-2a3b-4c5d-8e7f-9a0b1c2d3e40 '{
  "name": "opentelemetry",
  "config": {
    "endpoint": "http://jaeger:4318/v1/traces",
    "resource_attributes": { "service.name": "kong" }
  }
}'
