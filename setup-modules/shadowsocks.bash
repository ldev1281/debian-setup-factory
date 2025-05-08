# shadowsocks setup module

@module logger.bash

apt install -y openssl jq || logger::err "Failed to install required packages (openssl, jq)"

# Defaults
SHADOWSOCKS_METHOD="${SHADOWSOCKS_METHOD:-aes-256-gcm}"
SHADOWSOCKS_PORT="${SHADOWSOCKS_PORT:-9951}"
SHADOWSOCKS_PASSWORD="${SHADOWSOCKS_PASSWORD:-$(openssl rand -hex 16)}"

logger::log "Using Shadowsocks method: $SHADOWSOCKS_METHOD"
logger::log "Using Shadowsocks port: $SHADOWSOCKS_PORT"
logger::log "Using Shadowsocks password: ${SHADOWSOCKS_PASSWORD:0:4}***"

logger::log "Writing Shadowsocks config using jq..."
mkdir -p /etc/shadowsocks-libev || logger::err "Failed to create config directory"

jq -n \
    --arg server "127.0.0.1" \
    --arg password "$SHADOWSOCKS_PASSWORD" \
    --arg method "$SHADOWSOCKS_METHOD" \
    --arg mode "tcp_and_udp" \
    --argjson server_port "$SHADOWSOCKS_PORT" \
    --argjson timeout 300 \
    '$ARGS.named' > /etc/shadowsocks-libev/config.json || logger::err "Failed to write config file"

logger::log "Enabling and starting Shadowsocks service..."
systemctl enable shadowsocks-libev || logger::err "Failed to enable shadowsocks-libev"
systemctl restart shadowsocks-libev || logger::err "Failed to start shadowsocks-libev"
