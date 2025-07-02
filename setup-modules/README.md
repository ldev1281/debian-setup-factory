# Modules manuals

## logger.bash — Logger Module

### Description

The `logger.bash` module provides basic logging utilities for consistent script output and system log integration. It defines two functions:

* `logger::log` — prints informational messages to both stdout and the system logger.
* `logger::err` — prints error messages to stderr, logs them, and terminates the script.

This module ensures that log messages are visible both in the terminal and in syslog (via the `logger` command), using a unified log tag.

### Configuration Variables

* `LOG_TAG` — defines the syslog tag used in messages (default: `setup-script`).

Example:

```bash
LOG_TAG="custom-tag"
```

### Exported Functions

```bash
logger::log "Message to stdout and syslog"
logger::err "Fatal error message"
```

### Usage Example

```bash
@module logger.bash

logger::log "Starting service setup"
# do something...
logger::err "Failed to install dependencies"
```

This module is lightweight and safe to include in any other module or script.

---

## danted-setup.bash — Danted Install Module

### Description

The `danted-setup` module installs and configures a minimal SOCKS5 proxy using the `dante-server` package. It is intended for local SOCKS proxy setups with PAM-based user authentication and is safe to include in system initialization or provisioning workflows.

This module is fully self-contained and creates a system user for SOCKS authentication, generates a default configuration, and ensures the service is enabled and running.

### Configuration Variables

| Variable                     | Description                                   | Default                        |
|-----------------------------|-----------------------------------------------|--------------------------------|
| `DANTED_SETUP_INTERNAL_HOST`| IP address to bind locally                    | `127.0.0.1`                    |
| `DANTED_SETUP_INTERNAL_PORT`| Port for SOCKS5 proxy                         | `1080`                         |
| `DANTED_SETUP_EXTERNAL_IFACE`| Outbound interface (auto-detected via route) | auto                           |
| `DANTED_SETUP_CLIENT_USER`  | Login user for proxy auth                     | `dante-client-<random>`        |
| `DANTED_SETUP_CLIENT_PASSWORD` | Login password                            | `openssl rand -hex 16`         |

### Exported Behavior

All logs are routed through the included `logger.bash` module.

### Usage Example

```bash

@module danted-setup.bash
```
After execution, the proxy is available at 127.0.0.1:1080. The created login and password are printed to stdout and valid for PAM-based SOCKS auth.

---

## docker-setup.bash — Docker Engine Install Module

### Description

The `docker-setup` module installs Docker Engine on a Debian-based system. It removes conflicting packages, configures the official Docker APT repository, installs required components, and enables the `docker` systemd service.

### Usage Example

```bash
@module docker-setup.bash
```
---

## frp-setup.bash — FRP Server Install Module

### Description

The `frp-setup.bash` module installs and configures the **frp server (`frps`)** on a Debian-based system.  
It handles downloading the release, creating a config, installing a systemd unit, and starting the service.

All actions are logged through the `logger.bash` module.  
This script is safe to include in provisioning and automation flows.

### Configuration Variables

| Variable            | Description                             | Default                            |
|---------------------|-----------------------------------------|------------------------------------|
| `FRP_VERSION`       | Version of frp to install               | `0.62.1`                           |
| `FRP_HOST`          | Address to bind the frps service        | `127.0.0.1`                        |
| `FRP_PORT`          | Port to bind the frps service           | `7000`                             |
| `FRP_TOKEN`         | Authentication token for clients        | `openssl rand -hex 16`             |
| `FRP_INSTALL_DIR`   | Target directory for `frps` binary      | `/usr/local/bin`                   |
| `FRP_CONF_DIR`      | Directory to place `frps.ini` config    | `/etc/frp`                         |

### Usage Example

```bash
@module frp-setup.bash
```
After execution, the frp server will be running and available at ${FRP_HOST}:${FRP_PORT}.
Generated credentials and systemd setup make it ready for immediate use.

---

## shadowsocks-setup.bash — Shadowsocks Server Install Module

### Description

The `shadowsocks-setup.bash` module installs and configures a minimal **Shadowsocks** server using `shadowsocks-libev`.  
It generates a secure configuration with `jq`, sets up the system service, and starts it automatically.

All output is routed through the `logger.bash` module, and the script is designed for unattended execution.

### Configuration Variables

| Variable               | Description                              | Default                          |
|------------------------|------------------------------------------|----------------------------------|
| `SHADOWSOCKS_METHOD`   | Encryption cipher                        | `aes-256-gcm`                    |
| `SHADOWSOCKS_PORT`     | Port to bind the Shadowsocks service     | `9951`                           |
| `SHADOWSOCKS_PASSWORD` | Password for encryption/authentication   | `openssl rand -hex 16`           |

### Usage Example

```bash
@module shadowsocks-setup.bash
```

After execution, the Shadowsocks server will be running at 127.0.0.1:$SHADOWSOCKS_PORT using the specified encryption method and password.

---

## tor-setup.bash — Tor Client Install Module

### Description

The `tor-setup.bash` module installs and configures the **Tor client** on a Debian-based system.  
It adds the official Tor Project APT repository, installs `tor`, writes a minimal `torrc` config, and ensures the client is running with SOCKS5 enabled.

The script verifies successful routing through `.onion` test and logs all operations via the `logger.bash` module.

### Configuration Variables

| Variable                | Description                         | Default       |
|-------------------------|-------------------------------------|---------------|
| `TOR_SETUP_SOCKS_HOST` | IP address to bind SOCKS proxy      | `127.0.0.1`   |
| `TOR_SETUP_SOCKS_PORT` | Port for Tor SOCKS proxy            | `9050`        |

### Usage Example

```bash
@module tor-setup.bash
```
After execution, the Tor client will be running in the background with a SOCKS5 proxy exposed at ${TOR_SETUP_SOCKS_HOST}:${TOR_SETUP_SOCKS_PORT}.
Connection is verified against a .onion endpoint to ensure working routing.

---

## tor-singlehop-setup.bash — Tor Hidden Service (Single Hop) Module

### Description

The `tor-singlehop-setup.bash` module sets up a **Tor Hidden Service in Single Hop Mode** using a dedicated Tor instance.  
It is specifically tailored to expose **Dante SOCKS5** and **FRP (frps)** services through `.onion` addresses, without anonymity guarantees — intended for low-latency, internal routing over Tor.

This setup is ideal for building controlled, hidden-access backends where privacy is not the priority, but `.onion` transport is needed.

### Configuration Variables

| Variable                                | Description                                     | Default          |
|-----------------------------------------|-------------------------------------------------|------------------|
| `TOR_SINGLEHOP_CONF_HS_NAME`            | Name of the tor instance                        | `singlehop`      |
| `TOR_SINGLEHOP_CONF_HS_FRP_HOST`        | Internal FRP service address                    | `127.0.0.1`      |
| `TOR_SINGLEHOP_CONF_HS_FRP_PORT`        | Internal FRP port                               | `7000`           |
| `TOR_SINGLEHOP_CONF_HS_FRP_LISTEN`      | External (Tor) port for FRP                     | `7000`           |
| `TOR_SINGLEHOP_CONF_HS_DANTE_HOST`      | Internal Dante address                          | `127.0.0.1`      |
| `TOR_SINGLEHOP_CONF_HS_DANTE_PORT`      | Internal Dante port                             | `1080`           |
| `TOR_SINGLEHOP_CONF_HS_DANTE_LISTEN`    | External (Tor) port for Dante                   | `1080`           |

### Usage Example

```bash
@module tor-singlehop-setup.bash
```

After execution, both FRP and Dante services are reachable via Tor using a single .onion domain
(located at /var/lib/tor-instances/<name>/hostname), suitable for secure entrypoints or routing setups.

---

## tor-transparent-setup.bash — Tor Transparent Transport Module

### Description

The `tor-transparent-setup.bash` module configures a dedicated **Tor instance for transparent proxying and DNS routing**.  
It enables **TransPort** and **DNSPort**, sets up system routing rules via `nftables`, and rewrites `/etc/resolv.conf` to route DNS requests through Tor.

This is a complete module to enable network-wide Tor redirection, typically for containerized or host-bound traffic.

### Configuration Variables

| Variable                             | Description                                           | Default             |
|--------------------------------------|-------------------------------------------------------|---------------------|
| `TOR_TRANSPARENT_CONF_INSTANCE_NAME`| Name of the Tor instance                              | `transparent`       |
| `TOR_TRANSPARENT_CONF_DNS_HOST`     | DNSPort bind address                                  | `127.0.5.3`         |
| `TOR_TRANSPARENT_CONF_DNS_PORT`     | DNSPort bind port                                     | `53`                |
| `TOR_TRANSPARENT_CONF_TRANS_HOST`   | TransPort bind address                                | `127.0.0.1`         |
| `TOR_TRANSPARENT_CONF_TRANS_PORT`   | TransPort bind port                                   | `9040`              |
| `TOR_TRANSPARENT_CONF_TRANS_OPTS`   | Isolation options for TransPort                       | `Isolate*` flags    |
| `TOR_TRANSPARENT_CONF_VIRTUAL_NET`  | Virtual address space routed through Tor              | `10.192.0.0/10`     |

### Usage Example

```bash
@module tor-transparent-setup.bash
```

After execution, all DNS and TCP traffic to virtual IPs in the VirtualAddrNetworkIPv4 range will be transparently routed through Tor.
This setup is ideal for redirecting traffic from containers, isolating specific applications, or enforcing system-wide Tor tunneling without needing per-app proxy settings.

---

## veracrypt-setup.bash — VeraCrypt Console Installer Module

### Description

The `veracrypt-setup.bash` module installs the **console version of VeraCrypt** on a Debian 12 system.  
It downloads the official `.deb` package from Launchpad, installs it via `apt`, and logs progress using `logger.bash`.

This module is intended for headless environments, automation, or encrypted volume provisioning workflows.

### Configuration Variables

| Variable                  | Description                              | Default         |
|---------------------------|------------------------------------------|-----------------|
| `VERACRYPT_SETUP_VERSION`| VeraCrypt version to install             | `1.26.20`       |

### Usage Example

```bash
@module veracrypt-setup.bash
```

After execution, veracrypt will be available as a CLI utility for managing encrypted volumes in console environments.
