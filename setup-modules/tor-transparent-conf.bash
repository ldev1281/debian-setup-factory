# tor transparent transport setup module
set -Euo pipefail

@module logger.bash

logger::log "Configuring tor transparent transport"

#
# Defaults
#
TOR_TRANSPARENT_CONF_INSTANCE_NAME="${TOR_TRANSPARENT_CONF_INSTANCE_NAME:=transparent}"
TOR_TRANSPARENT_CONF_DNS_HOST="${TOR_TRANSPARENT_CONF_DNS_HOST:-127.0.5.3}"
TOR_TRANSPARENT_CONF_DNS_PORT="${TOR_TRANSPARENT_CONF_DNS_PORT:-53}"
TOR_TRANSPARENT_CONF_TRANS_HOST="${TOR_TRANSPARENT_CONF_TRANS_HOST:-127.0.0.1}"
TOR_TRANSPARENT_CONF_TRANS_PORT="${TOR_TRANSPARENT_CONF_TRANS_PORT:-9040}"
TOR_TRANSPARENT_CONF_TRANS_OPTS="${TOR_TRANSPARENT_CONF_TRANS_OPTS:-IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort}"
TOR_TRANSPARENT_CONF_VIRTUAL_NET="${TOR_TRANSPARENT_CONF_VIRTUAL_NET:-10.192.0.0/10}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Transparent transport tor configuration
#
logger::log "Transparent transport tor configuration"

#
# Creating new tor instance with a separate config, working directory and user
#
tor-instance-create ${TOR_TRANSPARENT_CONF_INSTANCE_NAME} || "failed to setup tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME}"

#
# DNS over tor and Transparent Proxy
#
{
    echo "DNSPort ${TOR_TRANSPARENT_CONF_DNS_HOST}:${TOR_TRANSPARENT_CONF_DNS_PORT}"
    echo "TransPort ${TOR_TRANSPARENT_CONF_TRANS_HOST}:${TOR_TRANSPARENT_CONF_TRANS_PORT} ${TOR_TRANSPARENT_CONF_TRANS_OPTS}"
    echo "VirtualAddrNetworkIPv4 ${TOR_TRANSPARENT_CONF_VIRTUAL_NET}"
    echo "AutomapHostsOnResolve 1"
    echo ""
} >/etc/tor/instances/${TOR_TRANSPARENT_CONF_INSTANCE_NAME}/torrc

# Disable systemd-resolved if enabled to prevent overwriting /etc/resolv.conf
if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    systemctl disable --now systemd-resolved || true
fi

# Set DNS servers
{
    echo "nameserver ${TOR_TRANSPARENT_CONF_DNS_HOST}"
} >/etc/resolv.conf

# nftables rules
{
    echo "#!/usr/sbin/nft -f"
    echo ""
    echo "# Create chains if not exist"
    echo "table ip nat {"
    echo "      chain prerouting_tor {"
    echo "          type nat hook prerouting priority dstnat -1;"
    echo "      }"
    echo "      chain output_tor {"
    echo "          type nat hook output priority filter -1;"
    echo "      }"
    echo "}"
    echo ""
    echo "table ip filter {"
    echo "      chain input_tor {"
    echo "                type filter hook input priority filter -1;"
    echo "        }"
    echo "}"
    echo ""
    echo "# Flush chains if already exist"
    echo "flush chain ip nat prerouting_tor"
    echo "flush chain ip nat output_tor"
    echo "flush chain ip filter input_tor"
    echo ""
    echo "# Redirect to Tor from containers"
    echo "add rule ip nat prerouting_tor ip daddr ${TOR_TRANSPARENT_CONF_VIRTUAL_NET} tcp dport != ${TOR_TRANSPARENT_CONF_TRANS_PORT} counter dnat to ${TOR_TRANSPARENT_CONF_TRANS_HOST}:${TOR_TRANSPARENT_CONF_TRANS_PORT}"
    echo "# Redirect to Tor from host"
    echo "add rule ip nat output_tor ip daddr ${TOR_TRANSPARENT_CONF_VIRTUAL_NET} tcp dport != ${TOR_TRANSPARENT_CONF_TRANS_PORT} counter dnat to ${TOR_TRANSPARENT_CONF_TRANS_HOST}:${TOR_TRANSPARENT_CONF_TRANS_PORT}"
    echo "# Protect from spoofing loopback network from local network"
    echo "add rule ip filter input_tor ip daddr 127.0.0.0/8 iifname "$(ip route | awk '/default/ {print $5}' | head -n1)" counter drop"
} >/etc/nftables.conf

# Allow routing to loopback interfaces (to make dnat work).
{
    echo "net.ipv4.conf.all.route_localnet=1"
} >/etc/sysctl.d/90-tor.conf

# Enable and start the services
nft -f /etc/nftables.conf || logger::err "Failed to load nftables rules"
systemctl daemon-reexec
systemctl daemon-reload
systemctl force-reload procps || logger::err "Failed to reload procps service"
systemctl enable nftables || logger::err "Failed to enable nftables service"
systemctl restart nftables || logger::err "Failed to start nftables service"
systemctl enable tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME} || logger::err "Failed to enable tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME} service"
systemctl restart tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME} || logger::err "Failed to start tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME} service"

#
# testing tor setup
#
logger::log "Testing tor setup"
_TOR_TRANSPARENT_CONF_DNS_TEST_ATTEMPTS=0
_TOR_TRANSPARENT_CONF_DNS_TEST_RESTARTS=0
while ! wget --quiet --spider --tries=1 http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion; do
    ((_TOR_TRANSPARENT_CONF_DNS_TEST_ATTEMPTS++))
    logger::log "still waiting tor up..."

    if ((_TOR_TRANSPARENT_CONF_DNS_TEST_ATTEMPTS % 6 == 0)); then
        ((_TOR_TRANSPARENT_CONF_DNS_TEST_RESTARTS++))
        if ((_TOR_TRANSPARENT_CONF_DNS_TEST_RESTARTS <= 1)); then
            logger::log "restarting tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME}..."
            systemctl restart tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME} || logger::err "Failed to start tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME} service"
        else
            logger::log "failed to setup tor@${TOR_TRANSPARENT_CONF_INSTANCE_NAME}"
        fi
    fi

    sleep 5
done

#
# Done!
#
logger::log "tor transparent transport up! installation complete"
