# Modules manuals


## setup-modules/logger.bash — Logger Module

<details>

This module defines logging helpers for Bash scripts.

### Functions

- `logger::log "message"` — log info to stdout and syslog
- `logger::err "message"` — log error, print to stderr and exit

Example usage:

```bash
logger::log "Hello"
logger::err "Something went wrong"
```
</details>


## setup-modules/shadowsocks-server.bash — install and configure Shadowsocks

<details>

This module installs and configures a basic [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev) server.

### Dependencies

- setup-modules/logger.bash

### Description

- Installs `openssl`, `jq`, and `shadowsocks-libev`
- Sets sensible defaults for method and port
- Randomly generates a secure password (unless pre-defined)
- Writes JSON config to `/etc/shadowsocks-libev/config.json`
- Starts and enables the systemd service

### Environment variables

You **may** define the following variables before running this module:

- `SHADOWSOCKS_METHOD` — encryption method (default: `"aes-256-gcm"`)
- `SHADOWSOCKS_PORT` — integer port number (default: `9951`)
- `SHADOWSOCKS_PASSWORD` — password for encryption (default: random 16-byte hex string)

If not set, the module will fall back to the defaults above.

### Generated config example

```json
{
  "server": "127.0.0.1",
  "password": "auto-generated-hex",
  "method": "aes-256-gcm",
  "mode": "tcp_and_udp",
  "server_port": 9951,
  "timeout": 300
}
```

### Example usage in a recipe

```bash
@module shadowsocks-server.bash
```

You can override configuration by setting environment variables beforehand:

```bash
export SHADOWSOCKS_METHOD="chacha20-ietf-poly1305"
export SHADOWSOCKS_PORT=8388
@module shadowsocks-server.bash
```

### Notes

* The generated password is only stored in `/etc/shadowsocks-libev/config.json`. Make sure to back it up if needed.
* All errors are logged using `logger::err`, which halts execution.
* This module is intended for localhost-bound server setup (`127.0.0.1`) — suitable for proxying via Tor or similar.

</details>


## setup-modules/frp-server.bash — install and configure frp server (frps)

<details>

This module installs and configures the [frp server](https://github.com/fatedier/frp) component (`frps`), which acts as a reverse proxy server for clients running `frpc`.

### Dependencies

* `setup-modules/logger.bash`

### Description

* Installs `curl`, `tar`, `openssl`, and `systemd` dependencies
* Downloads and installs `frps` from the official GitHub release
* Generates a secure random token if not explicitly provided
* Writes a minimal `frps.ini` configuration file to `/etc/frp/frps.ini`
* Registers and enables the `frps` systemd service

### Environment variables

You **may** define the following variables before running this module:

* `FRP_VERSION` — version of frp to install (default: `"0.62.1"`)
* `FRP_HOST` — bind address for frps (default: `"127.0.0.1"`)
* `FRP_PORT` — port to bind frps on (default: `7000`)
* `FRP_TOKEN` — shared authentication token (default: random 16-byte hex)
* `FRP_INSTALL_DIR` — location to install `frps` binary (default: `/usr/local/bin`)
* `FRP_CONF_DIR` — directory for frps config file (default: `/etc/frp`)

If not set, the module will fall back to the defaults above.

### Generated config example

```ini
# frps config (reverse proxy server)
[common]
bind_addr = 127.0.0.1
bind_port = 7000
token = auto-generated-hex
```

### Example usage in a recipe

```bash
@module frp-server.bash
```

You can override configuration by setting environment variables beforehand:

```bash
export FRP_PORT=9000
export FRP_TOKEN="custom_secure_token"
@module frp-server.bash
```

### Notes

* The generated token is only written to `/etc/frp/frps.ini`. Save it if you plan to configure a matching `frpc` client.
* All critical failures (download, install, configuration, systemd) are logged via `logger::err` and halt execution.
* This module sets up a **localhost-only** frps instance by default. For public access, override `FRP_HOST`.

</details>

