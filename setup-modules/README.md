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

---

## threeproxy-setup.bash — 3proxy Install Module

### Description

The `threeproxy-setup` module installs and configures a full-featured proxy stack using the official [3proxy](https://3proxy.org) package. It includes SOCKS5, HTTP proxy, and SMTP relay support. The module is designed for local proxy deployments with strong password-based authentication and minimal system dependencies.

This setup script is self-contained and suitable for use in initialization workflows. It creates a user for proxy authentication, generates a secure configuration, and ensures the service is enabled and started via systemd.

### Configuration Variables

| Variable                               | Description                                                                 | Default                          |
|----------------------------------------|-----------------------------------------------------------------------------|----------------------------------|
| `THREEPROXY_SETUP_USER`                | Login user for proxy authentication                                         | `3proxy-user-<random>`           |
| `THREEPROXY_SETUP_PASSWORD`            | Password for the proxy user                                                 | `openssl rand -hex 16`           |
| `PROXY_SETUP_INTERNAL_HOST`            | IP address to bind proxy interfaces                                         | `127.0.0.1`                       |
| `THREEPROXY_SETUP_INTERNAL_PORT`       | SOCKS5 proxy port                                                           | `1081`                            |
| `THREEPROXY_SETUP_HTTP_INTERNAL_PORT`  | HTTP proxy port                                                             | `3128`                            |
| `THREEPROXY_SETUP_SMTP_INTERNAL_PORT`  | Local SMTP relay port                                                       | `587`                             |
| `THREEPROXY_SETUP_SMTP_RELAY_HOST`     | Remote SMTP relay host                                                      | `smtp.mailgun.org`                |
| `THREEPROXY_SETUP_SMTP_RELAY_PORT`     | Remote SMTP relay port                                                      | `587`                             |

### Exported Behavior

All logs are routed through the included `logger.bash` module.  
The module installs the latest `.deb` release of 3proxy, configures multi-protocol support, and sets up a systemd unit at `/etc/systemd/system/3proxy.service`.

### Usage Example

```bash
@module threeproxy-setup.bash
```

After execution, the following endpoints are available (all bound to `127.0.0.1` by default):

- **SOCKS5 proxy**: `127.0.0.1:${THREEPROXY_SETUP_INTERNAL_PORT}`
- **HTTP proxy**: `127.0.0.1:${THREEPROXY_SETUP_HTTP_INTERNAL_PORT}`
- **SMTP relay**: `127.0.0.1:${THREEPROXY_SETUP_SMTP_INTERNAL_PORT}`  

---

## bitwarden-bw-setup.bash — Bitwarden CLI Install Module

### Description

The `bitwarden-bw-setup.bash` module installs the **Bitwarden CLI** on a Debian-based system.  
It handles downloading the official release archive, extracting it, and installing the `bw` binary into the system path.  
All actions are logged via the `logger.bash` module, and the script ensures required dependencies are present.  

This module is intended for automation flows or provisioning steps where command-line access to Bitwarden secrets is required.

### Configuration Variables

| Variable           | Description                                      | Default          |
|--------------------|--------------------------------------------------|------------------|
| `BW_VERSION`       | Version of Bitwarden CLI to install              | `1.22.1`         |
| `BW_INSTALL_DIR`   | Directory to place the `bw` binary               | `/usr/local/bin` |

### Usage Example

```bash
@module bitwarden-bw-setup.bash
```

After execution, the `bw` command is available globally and can be used to authenticate, manage, and retrieve secrets from a Bitwarden vault.

---

## bitwarden-bws-setup.bash — Bitwarden Secrets Manager CLI Install Module

### Description

The `bitwarden-bws-setup.bash` module installs the **Bitwarden Secrets Manager CLI (bws)** on a Debian-based system.  
It handles downloading the official release archive, extracting it, and installing the `bws` binary into the system path.  
All actions are logged via the `logger.bash` module, and the script ensures required dependencies are present.  

This module is intended for automation flows or provisioning steps where command-line access to Bitwarden Secrets Manager is required.

### Configuration Variables

| Variable           | Description                                            | Default          |
|--------------------|--------------------------------------------------------|------------------|
| `BWS_VERSION`      | Version of Bitwarden Secrets Manager CLI to install    | `1.0.0`          |
| `BWS_INSTALL_DIR`  | Directory to place the `bws` binary                    | `/usr/local/bin` |

### Usage Example

```bash
@module bitwarden-bws-setup.bash
```

After execution, the `bws` command is available globally and can be used to authenticate and interact with Bitwarden Secrets Manager.

---

# Bitwarden Helpers Module (`bitwarden.bash`)

## Description

The `bitwarden.bash` module provides helper functions for working with **Bitwarden CLI (`bw`)** and **Bitwarden Secrets Manager CLI (`bws`)**.  
It simplifies listing projects and secrets, retrieving secret values by key or id, and creating/updating secrets.  
All operations are logged via `logger.bash`.

## Prerequisites

1. Access to **Bitwarden Secrets Manager**:  
   - Web Vault (US): [https://vault.bitwarden.com/](https://vault.bitwarden.com/)  
   - Web Vault (EU): [https://vault.bitwarden.eu/](https://vault.bitwarden.eu/)  

2. A **Project** in Secrets Manager to store the required secrets. This project is used as `BWS_PROJECT_NAME`.

3. One or more **Machine Accounts** with access to that Project:
   - `server-stage` — backend access.
   - `server-stage-proxy` — proxy access.

4. For each machine account, create an **Access Token**. This token is used as `BWS_ACCESS_TOKEN`.

5. The CLI tools `bw` and `bws` must be installed:
   - `bitwarden-bw-setup.bash` — installs Bitwarden CLI (`bw`).
   - `bitwarden-bws-setup.bash` — installs Bitwarden Secrets Manager CLI (`bws`).

## Configuration Variables

| Variable            | Description                                          | Where to obtain                                                                 |
|---------------------|------------------------------------------------------|---------------------------------------------------------------------------------|
| `BWS_ACCESS_TOKEN`  | Machine Account Access Token for Secrets Manager     | Web Vault → Organization → Secrets Manager → Machine Accounts → Access Tokens   |
| `BWS_PROJECT_NAME`  | Optional project name for scoping secrets            | Create the project in Web Vault and use its name                                |

When the module starts, it prompts for `BWS_ACCESS_TOKEN` and optionally `BWS_PROJECT_NAME`.

## Required secrets

The following secrets must be created inside the chosen Bitwarden Project. Keys are case sensitive.

| Key                      | Purpose / usage                                         | Example / format                                       |
|--------------------------|---------------------------------------------------------|--------------------------------------------------------|
| `backup-gpg-public-key`  | GPG public key (ASCII) used to encrypt backups          | ASCII-armored block (`-----BEGIN PGP PUBLIC KEY----- …`) |
| `backup-sftp-remote-path`| Destination path for SFTP uploads                        | `/backups/host1/`                                      |
| `backup-sftp-host`       | SFTP host                                               | `sftp.example.com`                                     |
| `backup-sftp-port`       | SFTP port                                               | `22`                                                   |
| `backup-sftp-user`       | SFTP username                                           | `backup`                                               |
| `backup-sftp-pass`       | SFTP password/secret                                    | opaque secret                                          |
| `backup-s3-remote-path`  | S3 path/prefix for uploads                              | `backups/host1/`                                       |
| `backup-s3-endpoint`     | S3 endpoint (for non-AWS/custom S3)                     | `https://s3.example.com`                               |
| `backup-s3-bucket`       | S3 bucket name                                          | `my-backups`                                           |
| `backup-s3-key`          | S3 Access Key ID                                        | `AKIA…`                                                |
| `backup-s3-secret`       | S3 Secret Access Key                                    | secret string                                          |
| `backup-s3-region`       | AWS S3 region (when provider is `AWS`)                  | `eu-central-1`                                         |


## Usage example

```bash
@module bitwarden.bash

# On start, the module prompts for:
# 1. BWS_ACCESS_TOKEN (required)
# 2. BWS_PROJECT_NAME (optional; resolves BWS_PROJECT_ID)

If access is denied, regenerate the **Access Token** for the Machine Account in Web Vault and set it as `BWS_ACCESS_TOKEN`.  

---

## outline-setup.bash — Outline Install Module

### Description

The `outline-setup` module automates installation and initialization of the [Outline](https://www.getoutline.com) knowledge base via Docker Compose.  
It ensures all required dependencies are installed, prepares the target directory, and manages repository cloning or updating.  
The module then executes the bundled `init.bash` script to finalize configuration and bring up the Outline service stack.

This module is designed for reproducible deployments in initialization workflows. It enforces root privileges, validates dependencies, and handles both fresh installs and updates from an existing Git repository.

### Configuration Variables

| Variable                         | Description                                                         | Default                                                           |
|----------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------|
| `OUTLINE_SETUP_REPO_URL`         | Git repository URL for Outline deployment                           | `https://github.com/ldev1281/docker-compose-outline.git`          |
| `OUTLINE_SETUP_TARGET_PARENT_DIR`| Parent directory for Outline installation                           | `/docker`                                                         |
| `OUTLINE_SETUP_TARGET_DIR`       | Target directory for Outline instance                               | `${OUTLINE_SETUP_TARGET_PARENT_DIR}/outline`                      |
| `OUTLINE_SETUP_GIT_BRANCH`       | Git branch to checkout (if specified)                               | *(empty → default branch)*                                        |
| `OUTLINE_SETUP_INIT_PATH`        | Path to initialization script executed after cloning/updating       | `./tools/init.bash`                                               |

### Exported Behavior

- All logs and errors are routed through the `logger.bash` module.  
- Validates root privileges before proceeding.  
- Installs system dependencies: **git**, **ca-certificates**, **curl**.  
- Creates or updates the target deployment directory and clones/updates the Outline Docker Compose repository.  
- Executes the initialization script (`init.bash`) to finalize service configuration.  
- Provides reproducible, idempotent setup suitable for automated provisioning.  

### Usage Example

```bash
@module outline-setup.bash
```

After execution, the Outline service stack is installed under the specified target directory and ready for further configuration and startup.  

---

## authentik-setup.bash — Authentik Install Module

### Description

The `authentik-setup` module automates the deployment of the [Authentik](https://goauthentik.io) identity provider using Docker Compose.  
It installs required dependencies, prepares the target directory, and manages cloning or updating the deployment repository.  
Finally, it executes the bundled `init.bash` script to generate environment configuration and bootstrap the Authentik service stack.

This module is intended for initialization workflows where secure, reproducible provisioning of Authentik is required. It enforces root privileges, validates dependencies, and supports both fresh installs and updates of existing deployments.

### Configuration Variables

| Variable                           | Description                                                         | Default                                                            |
|------------------------------------|---------------------------------------------------------------------|--------------------------------------------------------------------|
| `AUTHENTIK_SETUP_REPO_URL`         | Git repository URL for Authentik deployment                         | `https://github.com/ldev1281/docker-compose-authentik.git`         |
| `AUTHENTIK_SETUP_TARGET_PARENT_DIR`| Parent directory for Authentik installation                         | `/docker`                                                          |
| `AUTHENTIK_SETUP_TARGET_DIR`       | Target directory for Authentik instance                             | `${AUTHENTIK_SETUP_TARGET_PARENT_DIR}/authentik`                   |
| `AUTHENTIK_SETUP_GIT_BRANCH`       | Git branch to checkout (if specified)                               | *(empty → default branch)*                                         |
| `AUTHENTIK_SETUP_INIT_PATH`        | Path to initialization script executed after cloning/updating       | `./tools/init.bash`                                                |

### Exported Behavior

- All logs and errors are routed through the `logger.bash` module.  
- Validates root privileges before proceeding.  
- Installs system dependencies: **git**, **ca-certificates**, **curl**.  
- Creates or updates the target deployment directory and clones/updates the Authentik Docker Compose repository.  
- Executes the initialization script (`init.bash`) to generate `.env` files and initialize database, Redis, and service configuration.  
- Provides reproducible, idempotent setup for automated provisioning.  

### Usage Example

```bash
@module authentik-setup.bash
```

After execution, the Authentik service stack is installed under the specified target directory.  
The instance will be ready for configuration of authentication providers, flows, and single sign-on (SSO) integrations.  

---

## proxy-client-setup.bash — Proxy Client Install Module

### Description

The `proxy-client-setup` module automates the deployment of a proxy client stack using Docker Compose.  
It prepares the system environment, ensures required dependencies are installed, and manages cloning or updating of the proxy-client repository.  
Afterward, it executes the bundled `init.bash` script to configure and launch the proxy client containers.

This module is intended for reproducible deployments in initialization workflows. It enforces root privileges, validates dependencies, and supports both fresh installs and updates from an existing Git repository.

### Configuration Variables

| Variable                                | Description                                                         | Default                                                                 |
|-----------------------------------------|---------------------------------------------------------------------|-------------------------------------------------------------------------|
| `PROXY_CLIENT_SETUP_REPO_URL`           | Git repository URL for proxy client deployment                      | `https://github.com/ldev1281/docker-compose-proxy-client.git`           |
| `PROXY_CLIENT_SETUP_TARGET_PARENT_DIR`  | Parent directory for proxy client installation                      | `/docker`                                                               |
| `PROXY_CLIENT_SETUP_TARGET_DIR`         | Target directory for proxy client instance                          | `${PROXY_CLIENT_SETUP_TARGET_PARENT_DIR}/proxy-client`                  |
| `PROXY_CLIENT_SETUP_GIT_BRANCH`         | Git branch to checkout (if specified)                               | *(empty → default branch)*                                              |
| `PROXY_CLIENT_SETUP_INIT_PATH`          | Path to initialization script executed after cloning/updating       | `./tools/init.bash`                                                     |

### Exported Behavior

- All logs and errors are routed through the `logger.bash` module.  
- Validates root privileges before proceeding.  
- Installs system dependencies: **git**, **ca-certificates**, **curl**.  
- Creates or updates the target deployment directory and clones/updates the proxy client Docker Compose repository.  
- Executes the initialization script (`init.bash`) to configure proxy client services and generate environment files.  
- Provides reproducible, idempotent setup suitable for automated provisioning.  

### Usage Example

```bash
@module proxy-client-setup.bash
```

After execution, the proxy client stack is installed under the specified target directory and ready to connect to the configured proxy server(s).  

---