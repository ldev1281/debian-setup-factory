# tor transparent transport setup module
set -Euo pipefail

@module logger.bash

logger::log "Configuring tor transparent transport"

#
# Defaults
#
TOR_TRANSPARENT_SETUP_DNS_HOST="${TOR_TRANSPARENT_SETUP_DNS_HOST:-127.0.5.3}"
TOR_TRANSPARENT_SETUP_DNS_PORT="${TOR_TRANSPARENT_SETUP_DNS_PORT:-53}"
TOR_TRANSPARENT_SETUP_TRANS_HOST="${TOR_TRANSPARENT_SETUP_TRANS_HOST:-127.0.0.1}"
TOR_TRANSPARENT_SETUP_TRANS_PORT="${TOR_TRANSPARENT_SETUP_TRANS_PORT:-9040}"
TOR_TRANSPARENT_SETUP_TRANS_OPTS="${TOR_TRANSPARENT_SETUP_TRANS_OPTS:-IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort}"
TOR_TRANSPARENT_SETUP_VIRTUAL_NET="${TOR_TRANSPARENT_SETUP_VIRTUAL_NET:-10.192.0.0/10}"
TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_NAME="${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_NAME:=caddy}"
TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_HOST="${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_HOST:=127.0.0.1}"
TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_PORT="${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_PORT:=80}"
TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_LISTEN="${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_LISTEN:=80}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Transparent transport tor configuration
#
logger::log "Transparent transport tor configuration"

#
# DNS over tor
#
{
    echo "DNSPort ${TOR_TRANSPARENT_SETUP_DNS_HOST}:${TOR_TRANSPARENT_SETUP_DNS_PORT}"
    echo "TransPort ${TOR_TRANSPARENT_SETUP_TRANS_HOST}:${TOR_TRANSPARENT_SETUP_TRANS_PORT} ${TOR_TRANSPARENT_SETUP_TRANS_OPTS}"
    echo "VirtualAddrNetworkIPv4 ${TOR_TRANSPARENT_SETUP_VIRTUAL_NET}"
    echo "AutomapHostsOnResolve 1"
    echo ""
} >>/etc/tor/torrc

#
# Hidden Service
#
{
    echo "HiddenServiceDir /var/lib/tor/${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_NAME}_service"
    echo "HiddenServicePort ${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_LISTEN} ${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_HOST}:${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_PORT}"
    echo ""
} >>/etc/tor/torrc

# Disable systemd-resolved if enabled
if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    systemctl disable --now systemd-resolved || true
fi

# Set DNS servers
{
    echo "nameserver ${TOR_TRANSPARENT_SETUP_DNS_HOST}"
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
    echo "        ip daddr ${TOR_TRANSPARENT_SETUP_VIRTUAL_NET} tcp dport != ${TOR_TRANSPARENT_SETUP_TRANS_PORT} redirect to ${TOR_TRANSPARENT_SETUP_TRANS_PORT}"
    echo "    }"
    echo "}"
} >/etc/nftables.conf

# Enable and start the services
nft -f /etc/nftables.conf || logger::err "Failed to load nftables rules"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable nftables || logger::err "Failed to enable nftables service"
systemctl restart nftables || logger::err "Failed to start nftables service"
systemctl restart tor || logger::err "Failed to start tor service"

#
# waiting tor
#
logger::log "waiting tor up"
while ! curl --silent --fail http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion >/dev/null; do
    sleep 5
    logger::log "still waiting tor up..."
done

#
# waiting hidden service
#
logger::log "waiting hidden service up"
TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_URL=$(cat /var/lib/tor/${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_NAME}_service/hostname)
while ! curl --silent --fail ${TOR_TRANSPARENT_SETUP_HIDDEN_SERVICE_URL} >/dev/null; do
    sleep 5
    logger::log "still waiting hidden service up..."
done

#
# Done!
#
logger::log "tor transparent transport up! installation complete"
