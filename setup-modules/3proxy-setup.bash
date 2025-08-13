# 3proxy setup module

set -Euo pipefail

@module logger.bash

logger::log "Installing 3proxy..."

#
# 3proxy version
#
THREEPROXY_VERSION="${THREEPROXY_VERSION:-0.9.5}"

#
# Defaults
#
THREEPROXY_SETUP_USER="${THREEPROXY_SETUP_USER:-3proxy-user-$(head -c 4 /dev/urandom | base64 | tr -dc 'a-z0-9')}"
THREEPROXY_SETUP_PASSWORD="${THREEPROXY_SETUP_PASSWORD:-$(openssl rand -hex 16)}"

THREEPROXY_SETUP_INTERNAL_HOST="${THREEPROXY_SETUP_INTERNAL_HOST:-127.0.0.1}"
THREEPROXY_SETUP_INTERNAL_PORT="${THREEPROXY_SETUP_INTERNAL_PORT:-1081}"
THREEPROXY_SETUP_HTTP_INTERNAL_PORT="${THREEPROXY_SETUP_HTTP_INTERNAL_PORT:-3128}"
THREEPROXY_SETUP_SMTP_INTERNAL_PORT="${THREEPROXY_SETUP_SMTP_INTERNAL_PORT:-587}"
THREEPROXY_SETUP_SMTP_RELAY_HOST="${THREEPROXY_SETUP_SMTP_RELAY_HOST:-smtp.mailgun.com}"
THREEPROXY_SETUP_SMTP_RELAY_PORT="${THREEPROXY_SETUP_SMTP_RELAY_PORT:-587}"

# Require root privileges
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Install required packages
#
apt update || logger::err "apt update failed"
apt install -y wget ca-certificates || logger::err "Failed to install dependencies"

#
# Download and install .deb package
#
TMP_DIR="/tmp/3proxy_setup.$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || logger::err "Failed to enter temporary directory"

DEB_URL="https://github.com/3proxy/3proxy/releases/download/${THREEPROXY_VERSION}/3proxy-${THREEPROXY_VERSION}.x86_64.deb"
DEB_FILE="${TMP_DIR}/3proxy-${THREEPROXY_VERSION}.x86_64.deb"

logger::log "Downloading 3proxy .deb package..."
wget -q --show-progress -O "$DEB_FILE" "$DEB_URL" || logger::err "Failed to download .deb package"

logger::log "Installing 3proxy .deb package..."
dpkg -i "$DEB_FILE" || {
  logger::log "dpkg reported issues, attempting to fix with apt..."
  apt-get install -f -y || logger::err "Failed to fix broken dependencies"
}

#
# Generate 3proxy configuration
#
logger::log "Generating 3proxy configuration..."

CONFIG_PATH="/etc/3proxy/conf/3proxy.cfg"

{
  echo "nscache 65536"
  echo "timeouts 1 5 30 60 180 1800 15 60"
  echo "rotate 30"
  echo "auth strong"
  echo "users ${THREEPROXY_SETUP_USER}:CL:${THREEPROXY_SETUP_PASSWORD}"
  echo "allow ${THREEPROXY_SETUP_USER}"
  echo ""
  echo "socks -i${THREEPROXY_SETUP_INTERNAL_HOST} -p${THREEPROXY_SETUP_INTERNAL_PORT}"
  echo "proxy -i${THREEPROXY_SETUP_INTERNAL_HOST} -p${THREEPROXY_SETUP_HTTP_INTERNAL_PORT}"
  echo "tcppm -i${THREEPROXY_SETUP_INTERNAL_HOST} ${THREEPROXY_SETUP_SMTP_INTERNAL_PORT} ${THREEPROXY_SETUP_SMTP_RELAY_HOST} ${THREEPROXY_SETUP_SMTP_RELAY_PORT}"
} > "$CONFIG_PATH"

#
# Create systemd unit
#
logger::log "Creating systemd service..."

cat > /etc/systemd/system/3proxy.service <<EOF
[Unit]
Description=3proxy full stack (SOCKS5, HTTP, SMTP relay)
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/3proxy $CONFIG_PATH
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

#
# Enable and start service
#
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable 3proxy || logger::err "Failed to enable 3proxy service"
systemctl restart 3proxy || logger::err "Failed to start 3proxy service"

#
# Done
#
logger::log "3proxy is up and running!"
