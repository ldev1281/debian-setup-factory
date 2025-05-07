# shadowsocks setup module

@module logger.bash

apt install -y openssl jq

logger::log "Generating Shadowsocks password..."
_SS_PASSWORD=$(openssl rand -hex 16) || err "Password generation failed"

logger::log "Writing Shadowsocks config using jq..."
mkdir -p /etc/shadowsocks-libev

jq -n \
  --arg server "127.0.0.1" \
  --arg password "$_SS_PASSWORD" \
  --arg method "$SS_METHOD" \
  --arg mode "tcp_and_udp" \
  --argjson server_port "$SS_PORT" \
  --argjson timeout 300 \
  '$ARGS.named' > /etc/shadowsocks-libev/config.json

logger::log "Enabling and starting Shadowsocks..."
systemctl enable shadowsocks-libev || logger::err "Failed to enable shadowsocks"
systemctl restart shadowsocks-libev || logger::err "Failed to start shadowsocks"
