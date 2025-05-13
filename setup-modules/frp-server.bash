# frp server setup module

@module logger.bash

# Inform about chosen settings
logger::log "Installing frp server (frps)"

# Install required dependencies
apt update && apt install -y curl openssl tar systemd || logger::err "Failed to install required packages"

# Defaults
FRP_VERSION="${FRP_VERSION:-0.62.1}"
FRP_HOST="${FRP_HOST:-127.0.0.1}"
FRP_PORT="${FRP_PORT:-7000}"
FRP_TOKEN="${FRP_TOKEN:-$(openssl rand -hex 16)}"
FRP_INSTALL_DIR="${FRP_INSTALL_DIR:-/usr/local/bin}"
FRP_CONF_DIR="${FRP_CONF_DIR:-/etc/frp}"


# Download and extract frp release
TMP_DIR="/tmp/frp_install.$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || logger::err "Failed to enter temporary directory"

ARCHIVE_URL="https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz"
logger::log "Downloading frp release from: $ARCHIVE_URL"
curl -fsSL -o frp.tar.gz "$ARCHIVE_URL" || logger::err "Failed to download frp archive"

tar -xzf frp.tar.gz || logger::err "Failed to extract frp archive"
cd "frp_${FRP_VERSION}_linux_amd64" || logger::err "Failed to enter extracted directory"

# Install frps binary
install -m 755 frps "$FRP_INSTALL_DIR/frps" || logger::err "Failed to install frps"

# Write configuration
logger::log "Writing frps.ini configuration..."
mkdir -p "$FRP_CONF_DIR" || logger::err "Failed to create config directory"
{
    echo ""
    echo "# frps config (reverse proxy server)"
    echo "[common]"
    echo "bind_addr = $FRP_HOST"
    echo "bind_port = $FRP_PORT"
    echo "token = $FRP_TOKEN"
} > "$FRP_CONF_DIR/frps.ini"


# Create systemd unit file
logger::log "Creating systemd service for frps..."
{
    echo ""
    echo "# systemd service for frps"
    echo "[Unit]"
    echo "Description=frp server"
    echo "After=network.target"
    echo ""
    echo "[Service]"
    echo "ExecStart=$FRP_INSTALL_DIR/frps -c $FRP_CONF_DIR/frps.ini"
    echo "Restart=on-failure"
    echo ""
    echo "[Install]"
    echo "WantedBy=multi-user.target"
} > /etc/systemd/system/frps.service

# Enable and start the service
logger::log "Enabling and starting frps service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable frps || logger::err "Failed to enable frps service"
systemctl restart frps || logger::err "Failed to start frps service"

logger::log "frps is now running on ${FRP_HOST}:${FRP_PORT}"
