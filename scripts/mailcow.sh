#!/usr/bin/env bash
# Runs mailcow-dockerized (https://github.com/mailcow/mailcow-dockerized) next to this stack.
#
# mailcow ships its own compose project of ~18 containers and a generator for its configuration,
# so it is not part of docker-compose.yml. This script clones it into data/mailcow, generates the
# configuration non-interactively (inside a Linux container, the generator needs GNU tools),
# moves all host ports out of the way of the other services and starts it.
#
#   scripts/mailcow.sh install   clone + generate mailcow.conf (once)
#   scripts/mailcow.sh up        start mailcow
#   scripts/mailcow.sh down      stop mailcow (data is kept in docker volumes)
#   scripts/mailcow.sh status    show the containers
#   scripts/mailcow.sh logs      follow the logs
#   scripts/mailcow.sh destroy   stop and remove all mailcow volumes and data/mailcow
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAILCOW_DIR="${ROOT}/data/mailcow/mailcow-dockerized"
MAILCOW_HOSTNAME="${MAILCOW_HOSTNAME:-mail.example.test}"
MAILCOW_TZ="${MAILCOW_TZ:-UTC}"
MAILCOW_BRANCH="${MAILCOW_BRANCH:-master}"
# mailcow's default 172.22.1.0/24 often overlaps with networks Docker assigns to other projects
MAILCOW_IPV4_NETWORK="${MAILCOW_IPV4_NETWORK:-192.168.204}"

# host ports (KEY=value as in mailcow.conf), override with environment variables.
# A plain list instead of an associative array: macOS still ships bash 3.2.
MAILCOW_HTTPS_PORT="${MAILCOW_HTTPS_PORT:-8486}"
PORTS=(
    "HTTP_PORT=${MAILCOW_HTTP_PORT:-8485}"
    "HTTPS_PORT=${MAILCOW_HTTPS_PORT}"
    "SMTP_PORT=${MAILCOW_SMTP_PORT:-7025}"
    "SMTPS_PORT=${MAILCOW_SMTPS_PORT:-7465}"
    "SUBMISSION_PORT=${MAILCOW_SUBMISSION_PORT:-7587}"
    "IMAP_PORT=${MAILCOW_IMAP_PORT:-7143}"
    "IMAPS_PORT=${MAILCOW_IMAPS_PORT:-7993}"
    "POP_PORT=${MAILCOW_POP_PORT:-7110}"
    "POPS_PORT=${MAILCOW_POPS_PORT:-7995}"
    "SIEVE_PORT=${MAILCOW_SIEVE_PORT:-7190}"
)

compose() {
    (cd "${MAILCOW_DIR}" && docker compose "$@")
}

set_conf() {
    local key="$1" value="$2" conf="${MAILCOW_DIR}/mailcow.conf"
    if grep -q "^${key}=" "${conf}"; then
        sed -i.bak "s|^${key}=.*|${key}=${value}|" "${conf}" && rm -f "${conf}.bak"
    else
        echo "${key}=${value}" >> "${conf}"
    fi
}

install() {
    if [ ! -d "${MAILCOW_DIR}/.git" ]; then
        git clone --branch "${MAILCOW_BRANCH}" https://github.com/mailcow/mailcow-dockerized.git "${MAILCOW_DIR}"
    fi

    if [ ! -f "${MAILCOW_DIR}/mailcow.conf" ]; then
        # generate_config.sh expects Linux (GNU sed/grep, /proc/meminfo) and asks questions unless
        # the answers are provided as environment variables
        docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v "${MAILCOW_DIR}:${MAILCOW_DIR}" -w "${MAILCOW_DIR}" \
            -e MAILCOW_HOSTNAME="${MAILCOW_HOSTNAME}" -e MAILCOW_TZ="${MAILCOW_TZ}" \
            -e MAILCOW_BRANCH="${MAILCOW_BRANCH}" -e SKIP_CLAMD=y \
            docker:cli sh -c '
                apk add --no-cache bash git openssl coreutils grep sed gawk jq curl iproute2 findutils >/dev/null &&
                git config --global --add safe.directory "$PWD" &&
                ln -sf mailcow.conf .env &&
                bash ./generate_config.sh --dev'
    fi

    for entry in "${PORTS[@]}"; do
        set_conf "${entry%%=*}" "${entry#*=}"
    done
    # no Let's Encrypt for a local hostname, no IPv6 inside the Docker VM
    set_conf SKIP_LETS_ENCRYPT y
    set_conf SKIP_CLAMD y
    set_conf ENABLE_IPV6 false
    set_conf IPV4_NETWORK "${MAILCOW_IPV4_NETWORK}"

    echo "mailcow configured in ${MAILCOW_DIR}/mailcow.conf"
}

case "${1:-}" in
    install) install ;;
    up)
        [ -f "${MAILCOW_DIR}/mailcow.conf" ] || install
        compose pull --quiet
        compose up -d
        echo "mailcow UI: https://localhost:${MAILCOW_HTTPS_PORT} (admin / moohoo, change it on first login)"
        ;;
    down) compose down ;;
    status) compose ps ;;
    logs) compose logs -f --tail 100 ;;
    destroy)
        compose down -v
        rm -rf "${MAILCOW_DIR}"
        ;;
    *)
        sed -n '2,17p' "$0"
        exit 1
        ;;
esac
