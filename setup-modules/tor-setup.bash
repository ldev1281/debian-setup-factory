# tor client setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing tor"

#
# Defaults
#
TOR_SETUP_SOCKS_HOST="${TOR_SETUP_SOCKS_HOST:-127.0.0.1}"
TOR_SETUP_SOCKS_PORT="${TOR_SETUP_SOCKS_PORT:-9050}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Install required dependencies
#
logger::log "Installing dependencies"

apt update || logger::err "apt update failed"
apt install -y apt-transport-https gnupg lsb-release curl || logger::err "Failed to install required packages"

#
# Configuring apt & installing tor
#
logger::log "Configuring apt and installing tor"

# GPG signature
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc |
    gpg --dearmor --yes --output /etc/apt/keyrings/deb.torproject.org-keyring.gpg || logger::err "Failed to download Tor GPG signature"

# apt sources list
{
    echo "deb     [signed-by=/etc/apt/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -cs 2>/dev/null) main"
    echo "deb-src [signed-by=/etc/apt/keyrings/deb.torproject.org-keyring.gpg] https://deb.torproject.org/torproject.org $(lsb_release -cs 2>/dev/null) main"
    echo ""
} >/etc/apt/sources.list.d/tor.list

apt update || logger::err "apt update failed"
apt install -y tor deb.torproject.org-keyring || logger::err "Failed to install Tor packages"

#
# Default tor configuration
#
logger::log "Default tor configuration"

# torrc - socks5 only by default
{
    echo "SOCKSPort ${TOR_SETUP_SOCKS_HOST}:${TOR_SETUP_SOCKS_PORT}"
    echo ""
} >/etc/tor/torrc

# Enable autorun
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable tor || logger::err "Failed to enable tor service"
systemctl restart tor@default || logger::err "Failed to start tor service"

#
# testing tor setup
#
logger::log "Testing tor setup"
_TOR_SETUP_TEST_ATTEMPTS=0
_TOR_SETUP_TEST_RESTARTS=0
while ! curl --silent --fail -x socks5h://${TOR_SETUP_SOCKS_HOST}:${TOR_SETUP_SOCKS_PORT} http://2gzyxa5ihm7nsggfxnu52rck2vv4rvmdlkiu3zzui5du4xyclen53wid.onion >/dev/null; do
    ((_TOR_SETUP_TEST_ATTEMPTS++))
    logger::log "still waiting tor up..."

    if ((_TOR_SETUP_TEST_ATTEMPTS % 6 == 0)); then
        ((_TOR_SETUP_TEST_RESTARTS++))
        if ((_TOR_SETUP_TEST_RESTARTS <= 1)); then
            logger::log "restarting tor@default..."
            systemctl restart tor@default || logger::err "Failed to start tor@default service"
        else
            logger::log "failed to setup tor@default"
        fi
    fi

    sleep 5
done

#
# Done!
#
logger::log "tor up! installation complete"
