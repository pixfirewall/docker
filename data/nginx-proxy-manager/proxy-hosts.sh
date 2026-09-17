#!/bin/sh
# Prepares Nginx Proxy Manager for this stack:
#   - creates the first administrator (a fresh installation has no user at all, NPM asks for it
#     in the UI; the API allows creating it without authentication while no user exists)
#   - creates a proxy host per service
# Runs again safely: an existing user and existing host names are left untouched.
#
# NPM_PROXY_HOSTS is a space separated list of <subdomain>:<target host>:<target port>,
# each becomes <subdomain>.localhost in NPM.
set -eu

api() {
    method="$1"
    path="$2"
    shift 2
    curl -fsS -X "$method" "${NPM_URL}${path}" -H 'content-type: application/json' \
        ${TOKEN:+-H "Authorization: Bearer ${TOKEN}"} "$@"
}

login() {
    api POST /api/tokens -d "{\"identity\":\"${NPM_EMAIL}\",\"secret\":\"${NPM_PASSWORD}\"}" 2>/dev/null |
        sed -n 's/.*"token":"\([^"]*\)".*/\1/p'
}

TOKEN=""
TOKEN=$(login)

if [ -z "$TOKEN" ]; then
    echo "creating the first administrator ${NPM_EMAIL}"
    api POST /api/users -d "{
        \"name\":\"Administrator\",\"nickname\":\"Admin\",\"email\":\"${NPM_EMAIL}\",
        \"roles\":[\"admin\"],\"is_disabled\":false,
        \"auth\":{\"type\":\"password\",\"secret\":\"${NPM_PASSWORD}\"}
    }" > /dev/null
    TOKEN=$(login)
fi

[ -n "$TOKEN" ] || { echo "could not log in to ${NPM_URL} as ${NPM_EMAIL}" >&2; exit 1; }

EXISTING=$(api GET /api/nginx/proxy-hosts)

for entry in ${NPM_PROXY_HOSTS}; do
    name=$(echo "$entry" | cut -d: -f1)
    target_host=$(echo "$entry" | cut -d: -f2)
    target_port=$(echo "$entry" | cut -d: -f3)
    domain="${name}.localhost"

    if echo "$EXISTING" | grep -q "\"${domain}\""; then
        echo "proxy host ${domain}: exists"
        continue
    fi

    api POST /api/nginx/proxy-hosts -d "{
        \"domain_names\":[\"${domain}\"],
        \"forward_scheme\":\"http\",
        \"forward_host\":\"${target_host}\",
        \"forward_port\":${target_port},
        \"access_list_id\":0,
        \"certificate_id\":0,
        \"ssl_forced\":false,
        \"http2_support\":false,
        \"hsts_enabled\":false,
        \"hsts_subdomains\":false,
        \"caching_enabled\":false,
        \"block_exploits\":true,
        \"allow_websocket_upgrade\":true,
        \"advanced_config\":\"\",
        \"locations\":[],
        \"meta\":{\"letsencrypt_agree\":false,\"dns_challenge\":false}
    }" > /dev/null
    echo "proxy host ${domain} -> ${target_host}:${target_port}: created"
done
