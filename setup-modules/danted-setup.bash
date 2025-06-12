# danted setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing danted"

#
# Defaults
#
DANTED_SETUP_INTERNAL_HOST="${DANTED_SETUP_INTERNAL_HOST:-127.0.0.1}"
DANTED_SETUP_INTERNAL_PORT="${DANTED_SETUP_INTERNAL_PORT:-1080}"
DANTED_SETUP_EXTERNAL_IFACE="${DANTED_SETUP_EXTERNAL_IFACE:-eth0}"
DANTED_SETUP_CLIENT_USER="${DANTED_SETUP_CLIENT_USER:-dante-client-$(cat /dev/urandom | tr -dc 'a-z0-9' | head -c 4)}"
DANTED_SETUP_CLIENT_PASSWORD="${DANTED_SETUP_CLIENT_PASSWORD:-$(openssl rand -hex 16)}"

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

# Listen and allow only localhost and use login and password
{
    echo "logoutput: syslog"
    echo "internal: ${DANTED_SETUP_INTERNAL_HOST} port = ${DANTED_SETUP_INTERNAL_PORT}"
    echo "external: ${DANTED_SETUP_EXTERNAL_IFACE}"
    echo "socksmethod: pam.username"
    echo "user.privileged: proxy"
    echo "user.unprivileged: nobody"
    echo "user.libwrap: nobody"
    echo "client pass {"
    echo "  from: 0.0.0.0/0 to: ${DANTED_SETUP_INTERNAL_HOST}/32"
    echo "  log: connect disconnect error"
    echo "  }"
    echo ""
    echo "socks pass {"
    echo "  from: 0.0.0.0/0 to: 0.0.0.0/0"
    echo "  protocol: tcp udp"
    echo "  log: connect disconnect error"
    echo "}"
    echo ""
} >/etc/danted.conf

# danted uses system users. Add a new system user without login access and set a password
useradd --system --no-create-home --home /nonexistent --shell /usr/sbin/nologin ${DANTED_SETUP_CLIENT_USER} || logger::err "Failed to add user ${DANTED_SETUP_CLIENT_USER}"
_DANTED_SETUP_CLIENT_PASSWORD_HASH=$(openssl passwd -6 "${DANTED_SETUP_CLIENT_PASSWORD}")
echo "$DANTED_SETUP_CLIENT_USER:$_DANTED_SETUP_CLIENT_PASSWORD_HASH" | chpasswd -e || logger::err "Failed to set password for the user ${DANTED_SETUP_CLIENT_USER}"

# Enable autorun
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable danted || logger::err "Failed to enable danted service"
systemctl restart danted || logger::err "Failed to start danted service"

#
# Done!
#
logger::log "danted server is up and running on ${DANTED_SETUP_INTERNAL_HOST}:${DANTED_SETUP_INTERNAL_PORT}! installation complete"
