# tor client setup module

@module logger.bash

# Fail on errors
set -Euo pipefail

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Inform about chosen settings
logger::log "Installing tor client (tor)"

# Install required dependencies
apt update || logger::err "Failed to install required packages"
apt install -y apt-transport-https gnupg wget lsb-release nftables netcat-traditional xxd || logger::err "Failed to install required packages"

# Defaults
TOR_CONF_DIR="${TOR_CONF_DIR:-/etc/tor}"
TOR_CONF_FILE="${TOR_CONF_DIR}/torrc"
TOR_CTRL_HOST="127.0.0.1"
TOR_CTRL_PORT="9051"
TOR_SOCKS_HOST="127.0.0.1"
TOR_SOCKS_PORT="9050"
TOR_DNS_HOST="127.0.5.3"
TOR_DNS_PORT="53"
TOR_TRANS_HOST="127.0.0.1"
TOR_TRANS_PORT="9040"
TOR_TRANS_OPTS="IsolateClientAddr IsolateClientProtocol IsolateDestAddr IsolateDestPort"
TOR_VIRTUAL_NET="10.192.0.0/10"
TOR_SOURCES_LIST="/etc/apt/sources.list.d/tor.list"
TOR_DIST="${TOR_DIST:-$(lsb_release -cs 2>/dev/null)}"
TOR_MIRROR="https://deb.torproject.org/torproject.org"
TOR_PACKAGES="tor deb.torproject.org-keyring"
RESOLV_CONF="/etc/resolv.conf"
NFTABLES_CONF="/etc/nftables.conf"

# Add apt sources list and install tor packages
logger::log "Generating $TOR_SOURCES_LIST..."
cat <<-EOF >"$TOR_SOURCES_LIST" || logger::err "Failed to generate $TOR_SOURCES_LIST"
deb     [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] $TOR_MIRROR $TOR_DIST main
deb-src [signed-by=/usr/share/keyrings/deb.torproject.org-keyring.gpg] $TOR_MIRROR $TOR_DIST main
EOF

logger::log "Downloading Tor GPG signature..."
wget -qO- https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc |
    gpg --dearmor --yes --output /usr/share/keyrings/deb.torproject.org-keyring.gpg || logger::err "Failed to download Tor GPG signature"

logger::log "Installing Tor packages..."
apt update || logger::err "Failed to install Tor packages"
apt install -y $TOR_PACKAGES || logger::err "Failed to install Tor packages"

# Write configuration
logger::log "Writing $TOR_CONF_FILE configuration..."
mkdir -p "$TOR_CONF_DIR" || logger::err "Failed to create config directory"
cat >"$TOR_CONF_FILE" <<EOF || logger::err "Failed to write config $TOR_CONF_FILE"
ControlPort ${TOR_CTRL_HOST}:${TOR_CTRL_PORT}
CookieAuthentication 1
SOCKSPort ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}
DNSPort ${TOR_DNS_HOST}:${TOR_DNS_PORT}
TransPort ${TOR_TRANS_HOST}:${TOR_TRANS_PORT} ${TOR_TRANS_OPTS}
VirtualAddrNetworkIPv4 ${TOR_VIRTUAL_NET}
AutomapHostsOnResolve 1
EOF

# Set DNS servers
if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    logger::log "Disabling systemd-resolved..."
    systemctl disable --now systemd-resolved || true
fi

logger::log "Adding DNS servers to $RESOLV_CONF..."
cat >"$RESOLV_CONF" <<-EOF || logger::err "Failed to set DNS servers"
nameserver ${TOR_DNS_HOST}
nameserver 8.8.8.8
EOF

#logger::log "Protecting $RESOLV_CONF from changing..."
#chattr +i "$RESOLV_CONF" || true

# Creating nftables rules
logger::log "Creating nftables table and rules..."

cat >"$NFTABLES_CONF" <<-EOF || logger::err "Failed to write nftables config"
#!/usr/sbin/nft -f

flush ruleset

table ip nat {
    chain output {
        type nat hook output priority 0;
        # Redirect to Tor
        ip daddr ${TOR_VIRTUAL_NET} tcp dport != ${TOR_TRANS_PORT} redirect to ${TOR_TRANS_PORT}
    }
}
EOF

# Enable and start the services
logger::log "Enabling and starting nftables and tor services..."
nft -f /etc/nftables.conf || logger::err "Failed to load nftables rules"
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable nftables || logger::err "Failed to enable nftables service"
systemctl restart nftables || logger::err "Failed to start nftables service"
systemctl enable tor || logger::err "Failed to enable tor service"
systemctl restart tor || logger::err "Failed to start tor service"

# Checking if tor works
logger::log "Checking tor is working..."
# Wait for a minute
timeout 60 bash -c '
  until echo -e "AUTHENTICATE $(xxd -p /run/tor/control.authcookie | tr -d "\n")\r\nGETINFO status/bootstrap-phase\r\nQUIT\r\n" | nc 127.0.0.1 9051 | grep -q "PROGRESS=100"; do
    sleep 2
  done
'  || logger::err "Tor is not working correctly, check settings"
wget -O /dev/null --quiet http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion/ 2>&1 || logger::err "Tor is not working correctly, check settings"

logger::log "Tor is working correctly"
logger::log "Tor transparent proxy is now running on ${TOR_TRANS_HOST}:${TOR_TRANS_PORT}"
logger::log "Tor socks5 proxy is now running on ${TOR_SOCKS_HOST}:${TOR_SOCKS_PORT}"
