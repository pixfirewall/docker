#!/bin/sh
# Starts Stalwart. On the very first start (no /etc/stalwart/config.json yet) it completes the
# setup wizard through the JMAP API and creates a mailbox, so the server is usable right away:
#   1. start in bootstrap mode, POST the Bootstrap settings (hostname, domain), stop
#   2. start normally, create the user with the recovery admin, stop
#   3. exec the server in the foreground
set -eu

CONFIG=/etc/stalwart/config.json
API=http://127.0.0.1:8080
RECOVERY_USER="${STALWART_RECOVERY_ADMIN%%:*}"
RECOVERY_PASSWORD="${STALWART_RECOVERY_ADMIN#*:}"

wait_for_http() {
    i=0
    until curl -fs -o /dev/null "$API/healthz/live"; do
        i=$((i + 1))
        [ "$i" -gt 120 ] && { echo "setup: stalwart did not start" >&2; exit 1; }
        sleep 1
    done
}

jmap() {
    curl -fsS -u "$RECOVERY_USER:$RECOVERY_PASSWORD" -H 'content-type: application/json' "$API/jmap/" -d "$1"
}

account_id() {
    # the account of the recovery admin that holds the stalwart management objects
    curl -fsSL -u "$RECOVERY_USER:$RECOVERY_PASSWORD" "$API/.well-known/jmap" |
        sed -n 's/.*"urn:stalwart:jmap":"\([^"]*\)".*/\1/p'
}

run_in_background() {
    /usr/local/bin/stalwart --config "$CONFIG" &
    PID=$!
    wait_for_http
}

stop_background() {
    kill "$PID"
    wait "$PID" || true
}

if [ ! -f "$CONFIG" ]; then
    echo "setup: first start, configuring ${MAIL_HOSTNAME} / ${MAIL_DOMAIN}"

    run_in_background
    jmap "{\"using\":[\"urn:ietf:params:jmap:core\",\"urn:stalwart:jmap\"],\"methodCalls\":[[\"x:Bootstrap/set\",{\"accountId\":\"$(account_id)\",\"update\":{\"singleton\":{
        \"serverHostname\":\"${MAIL_HOSTNAME}\",\"defaultDomain\":\"${MAIL_DOMAIN}\",\"requestTlsCertificate\":false,
        \"tracer\":{\"@type\":\"Stdout\",\"level\":\"info\",\"ansi\":false,\"multiline\":false,\"lossy\":false,\"events\":{},\"eventsPolicy\":\"exclude\",\"enable\":true}}}},\"0\"]]}" > /dev/null
    stop_background

    run_in_background
    ACCOUNT=$(account_id)
    DOMAIN_ID=$(jmap "{\"using\":[\"urn:ietf:params:jmap:core\",\"urn:stalwart:jmap\"],\"methodCalls\":[[\"x:Domain/get\",{\"accountId\":\"$ACCOUNT\",\"ids\":null,\"properties\":[\"name\"]},\"0\"]]}" |
        sed -n "s/.*{\"name\":\"${MAIL_DOMAIN}\",\"id\":\"\([^\"]*\)\"}.*/\1/p")
    jmap "{\"using\":[\"urn:ietf:params:jmap:core\",\"urn:stalwart:jmap\"],\"methodCalls\":[[\"x:Account/set\",{\"accountId\":\"$ACCOUNT\",\"create\":{\"dev\":{
        \"@type\":\"User\",\"name\":\"${MAIL_USER}\",\"domainId\":\"${DOMAIN_ID}\",\"description\":\"Development mailbox\",
        \"roles\":{\"@type\":\"User\"},\"credentials\":{\"0\":{\"@type\":\"Password\",\"secret\":\"${MAIL_USER_PASSWORD}\"}}}}},\"0\"]]}" > /dev/null
    stop_background
    echo "setup: done, mailbox ${MAIL_USER}@${MAIL_DOMAIN} created"
fi

exec /usr/local/bin/stalwart --config "$CONFIG"
