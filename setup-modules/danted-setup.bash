# danted setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing danted"

#
# Defaults
#
DANTED_SETUP_INTERNAL_HOST="${DANTED_SETUP_INTERNAL_HOST:-127.0.0.1}"
DANTED_SETUP_INTERNAL_PORT="${DANTED_SETUP_INTERNAL_PORT:-1080}"
DANTED_SETUP_EXTERNAL_IFACE="${DANTED_SETUP_EXTERNAL_IFACE:-$(ip route | awk '/default/ {print $5}' | head -n1)}"


# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Installing dante-server package
#
apt update || logger::err "apt update failed"
apt install -y dante-server || logger::err "Failed to install danted package (dante-server)"

#
# Default dante-server configuration
#
logger::log "Default danted configuration"

# Listen and allow only localhost
{
    echo "logoutput: syslog"
    echo "internal: ${DANTED_SETUP_INTERNAL_HOST} port = ${DANTED_SETUP_INTERNAL_PORT}"
    echo "external: ${DANTED_SETUP_EXTERNAL_IFACE}"
    echo "method: none"
    echo "user.privileged: proxy"
    echo "user.unprivileged: nobody"
    echo "user.libwrap: nobody"
    echo "client pass {"
    echo "  from: 0.0.0.0/0 to: ${DANTED_SETUP_INTERNAL_HOST}/32"
    echo "  log: connect disconnect error"
    echo "}"
    echo ""
    echo "socks pass {"
    echo "  from: 0.0.0.0/0 to: 0.0.0.0/0"
    echo "  protocol: tcp udp"
    echo "  method: none"
    echo "  log: connect disconnect error"
    echo "}"
    echo ""
} >/etc/danted.conf

# Enable autorun
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable danted || logger::err "Failed to enable danted service"
systemctl restart danted || logger::err "Failed to start danted service"

#
# Done!
#
logger::log "danted server is up and running on ${DANTED_SETUP_INTERNAL_HOST}:${DANTED_SETUP_INTERNAL_PORT}! installation complete"
