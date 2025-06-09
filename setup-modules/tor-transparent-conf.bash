# tor transparent transport setup module
set -Euo pipefail

@module logger.bash

logger::log "Configuring tor transparent transport"

#
# Defaults
#
TOR_TRANSPARENT_CONF_DNS_HOST="${TOR_TRANSPARENT_CONF_DNS_HOST:-127.0.5.3}"
TOR_TRANSPARENT_CONF_DNS_PORT="${TOR_TRANSPARENT_CONF_DNS_PORT:-53}"
TOR_TRANSPARENT_CONF_TRANS_HOST="${TOR_TRANSPARENT_CONF_TRANS_HOST:-127.0.0.1}"
TOR_TRANSPARENT_CONF_TRANS_PORT="${TOR_TRANSPARENT_CONF_TRANS_PORT:-9040}"
TOR_TRANSPARENT_CONF_TRANS_OPTS="${TOR_TRANSPARENT_CONF_TRANS_OPTS:-IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort}"
TOR_TRANSPARENT_CONF_VIRTUAL_NET="${TOR_TRANSPARENT_CONF_VIRTUAL_NET:-10.192.0.0/10}"
TOR_TRANSPARENT_CONF_HS_NAME="${TOR_TRANSPARENT_CONF_HS_NAME:=transparent}"
_TOR_TRANSPARENT_CONF_HS_DIR="/var/lib/tor-instances/${TOR_TRANSPARENT_CONF_HS_NAME}"
TOR_TRANSPARENT_CONF_HS_HOST="${TOR_TRANSPARENT_CONF_HS_HOST:=127.0.0.1}"
TOR_TRANSPARENT_CONF_HS_PORT="${TOR_TRANSPARENT_CONF_HS_PORT:=80}"
TOR_TRANSPARENT_CONF_HS_LISTEN="${TOR_TRANSPARENT_CONF_HS_LISTEN:=80}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Transparent transport tor configuration
#
logger::log "Transparent transport tor configuration"

#
# Creating new tor instance with a separate config, working directory and user
#
tor-instance-create ${TOR_TRANSPARENT_CONF_HS_NAME} || "failed to setup tor@${TOR_TRANSPARENT_CONF_HS_NAME}"

#
# DNS over tor
#
{
    echo "DNSPort ${TOR_TRANSPARENT_CONF_DNS_HOST}:${TOR_TRANSPARENT_CONF_DNS_PORT}"
    echo "TransPort ${TOR_TRANSPARENT_CONF_TRANS_HOST}:${TOR_TRANSPARENT_CONF_TRANS_PORT} ${TOR_TRANSPARENT_CONF_TRANS_OPTS}"
    echo "VirtualAddrNetworkIPv4 ${TOR_TRANSPARENT_CONF_VIRTUAL_NET}"
    echo "AutomapHostsOnResolve 1"
    echo ""
} >/etc/tor/instances/${TOR_TRANSPARENT_CONF_HS_NAME}/torrc

#
# Hidden Service
#
{
    echo "HiddenServiceDir ${_TOR_TRANSPARENT_CONF_HS_DIR}"
    echo "HiddenServicePort ${TOR_TRANSPARENT_CONF_HS_LISTEN} ${TOR_TRANSPARENT_CONF_HS_HOST}:${TOR_TRANSPARENT_CONF_HS_PORT}"
    echo ""
} >>/etc/tor/instances/${TOR_TRANSPARENT_CONF_HS_NAME}/torrc

# Disable systemd-resolved if enabled to prevent overwriting /etc/resolv.conf
if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    systemctl disable --now systemd-resolved || true
fi

# Set DNS servers
{
    echo "nameserver ${TOR_TRANSPARENT_CONF_DNS_HOST}"
    echo "nameserver 8.8.8.8"
} >/etc/resolv.conf

# nftables rules
{
    echo "#!/usr/sbin/nft -f"
    echo ""
    echo "flush ruleset"
    echo ""
    echo "table ip nat {"
    echo "    chain output {"
    echo "        type nat hook output priority 0;"
    echo "        # Redirect to Tor"
    echo "        ip daddr ${TOR_TRANSPARENT_CONF_VIRTUAL_NET} tcp dport != ${TOR_TRANSPARENT_CONF_TRANS_PORT} redirect to ${TOR_TRANSPARENT_CONF_TRANS_PORT}"
    echo "    }"
    echo "}"
} >/etc/nftables.conf

# Enable and start the services
nft -f /etc/nftables.conf || logger::err "Failed to load nftables rules"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable nftables || logger::err "Failed to enable nftables service"
systemctl restart nftables || logger::err "Failed to start nftables service"
systemctl enable tor@${TOR_TRANSPARENT_CONF_HS_NAME} || logger::err "Failed to enable tor@${TOR_TRANSPARENT_CONF_HS_NAME} service"
systemctl restart tor@${TOR_TRANSPARENT_CONF_HS_NAME} || logger::err "Failed to start tor@${TOR_TRANSPARENT_CONF_HS_NAME} service"

#
# testing tor setup
#
logger::log "Testing tor setup"
_TOR_TRANSPARENT_CONF_DNS_TEST_ATTEMPTS=0
_TOR_TRANSPARENT_CONF_DNS_TEST_RESTARTS=0
while ! curl --silent --fail http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion >/dev/null; do
    ((_TOR_TRANSPARENT_CONF_DNS_TEST_ATTEMPTS++))
    logger::log "still waiting tor up..."

    if ((_TOR_TRANSPARENT_CONF_DNS_TEST_ATTEMPTS % 6 == 0)); then
        ((_TOR_TRANSPARENT_CONF_DNS_TEST_RESTARTS++))
        if ((_TOR_TRANSPARENT_CONF_DNS_TEST_RESTARTS <= 1)); then
            logger::log "restarting tor@${TOR_TRANSPARENT_CONF_HS_NAME}..."
            systemctl restart tor@${TOR_TRANSPARENT_CONF_HS_NAME} || logger::err "Failed to start tor@${TOR_TRANSPARENT_CONF_HS_NAME} service"
        else
            logger::log "failed to setup tor@${TOR_TRANSPARENT_CONF_HS_NAME}"
        fi
    fi

    sleep 5
done

#
# testing hidden service setup. first check for hostname file, then try to connect
#
logger::log "Testing hidden service setup"
_TOR_TRANSPARENT_CONF_HS_TEST_ATTEMPTS=0
_TOR_TRANSPARENT_CONF_HS_TEST_RESTARTS=0

while ! test -f "$_TOR_TRANSPARENT_CONF_HS_DIR/hostname" ||
    ! curl --silent --fail "$(cat ${_TOR_TRANSPARENT_CONF_HS_DIR}/hostname)" >/dev/null; do

    ((_TOR_TRANSPARENT_CONF_HS_TEST_ATTEMPTS++))
    logger::log "still waiting hidden service up..."

    if ((_TOR_TRANSPARENT_CONF_HS_TEST_ATTEMPTS % 6 == 0)); then
        ((_TOR_TRANSPARENT_CONF_HS_TEST_RESTARTS++))
        if ((_TOR_TRANSPARENT_CONF_HS_TEST_RESTARTS <= 1)); then
            logger::log "restarting tor@${TOR_TRANSPARENT_CONF_HS_NAME}..."
            systemctl restart tor@${TOR_TRANSPARENT_CONF_HS_NAME} || logger::err "Failed to start tor@${TOR_TRANSPARENT_CONF_HS_NAME} service"
        else
            logger::err "failed to setup tor@${TOR_TRANSPARENT_CONF_HS_NAME}"
        fi
    fi

    sleep 5
done

#
# Done!
#
logger::log "tor transparent transport up! installation complete"
