# Modules manuals

## 📑 Navigation

- [logger.bash — Logger Module](#loggerbash--logger-module)  
- [danted-setup.bash — Danted Install Module](#danted-setupbash--danted-install-module)  
- [docker-setup.bash — Docker Engine Install Module](#docker-setupbash--docker-engine-install-module)  
- [frp-setup.bash — FRP Server Install Module](#frp-setupbash--frp-server-install-module)  
- [shadowsocks-setup.bash — Shadowsocks Server Install Module](#shadowsocks-setupbash--shadowsocks-server-install-module)  
- [tor-setup.bash — Tor Client Install Module](#tor-setupbash--tor-client-install-module)  
- [tor-singlehop-setup.bash — Tor Hidden Service (Single Hop) Module](#tor-singlehop-setupbash--tor-hidden-service-single-hop-module)  
- [tor-transparent-setup.bash — Tor Transparent Transport Module](#tor-transparent-setupbash--tor-transparent-transport-module)  
- [veracrypt-setup.bash — VeraCrypt Console Installer Module](#veracrypt-setupbash--veracrypt-console-installer-module)  
- [threeproxy-setup.bash — 3proxy Install Module](#threeproxy-setupbash--3proxy-install-module)  
- [bitwarden-bw-setup.bash — Bitwarden CLI Install Module](#bitwarden-bw-setupbash--bitwarden-cli-install-module)  
- [bitwarden-bws-setup.bash — Bitwarden Secrets Manager CLI Install Module](#bitwarden-bws-setupbash--bitwarden-secrets-manager-cli-install-module)  
- [bitwarden.bash — Bitwarden Helpers Module](#bitwardenbash--bitwarden-helpers-module)  
- [outline-setup.bash — Outline Install Module](#outline-setupbash--outline-install-module)  
- [authentik-setup.bash — Authentik Install Module](#authentik-setupbash--authentik-install-module)  
- [proxy-client-setup.bash — Proxy Client Install Module](#proxy-client-setupbash--proxy-client-install-module)
- [firefly-setup.bash — Firefly Install Module](#firefly-setupbash--firefly-install-module)
- [youtrack-setup.bash — Youtrack Install Module](#youtrack-setupbash--youtrack-install-module)     

---

## logger.bash — Logger Module

### Description
The `logger.bash` module provides basic logging utilities for consistent script output and system log integration.  
It defines two functions:

- `logger::log` — prints informational messages to both stdout and syslog.  
- `logger::err` — prints error messages to stderr, logs them, and terminates the script.  

### Configuration Variables

- `LOG_TAG` — syslog tag for messages (default: `setup-script`).

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

---

## danted-setup.bash — Danted Install Module

### Description
The `danted-setup` module installs and configures a minimal SOCKS5 proxy using the `dante-server` package.  
It is intended for local SOCKS proxy setups with PAM-based user authentication.

This module creates a system user for SOCKS authentication, generates a default configuration, and ensures the service is enabled and running.

### Configuration Variables

| Variable                     | Description                                   | Default                        |
|------------------------------|-----------------------------------------------|--------------------------------|
| `DANTED_SETUP_INTERNAL_HOST` | IP address to bind locally                    | `127.0.0.1`                    |
| `DANTED_SETUP_INTERNAL_PORT` | Port for SOCKS5 proxy                         | `1080`                         |
| `DANTED_SETUP_EXTERNAL_IFACE`| Outbound interface (auto-detected via route)  | auto                           |

### Exported Behavior
All logs are routed through `logger.bash`.

### Usage Example

```bash
@module danted-setup.bash
```

After execution, the proxy is available at `127.0.0.1:1080`.  
The created login and password are valid for PAM-based SOCKS authentication.

---

## docker-setup.bash — Docker Engine Install Module

### Description
The `docker-setup` module installs Docker Engine on a Debian-based system.  
It removes conflicting packages, configures the official Docker APT repository, installs required components, and enables the `docker` systemd service.

### Usage Example

```bash
@module docker-setup.bash
```

---

## frp-setup.bash — FRP Server Install Module

### Description
The `frp-setup.bash` module installs and configures the **frp server (`frps`)** on a Debian-based system.  
It downloads the release, creates a config, installs a systemd unit, and starts the service.

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

After execution, the frp server will run and be available at `${FRP_HOST}:${FRP_PORT}`.

---

## shadowsocks-setup.bash — Shadowsocks Server Install Module

### Description
The `shadowsocks-setup.bash` module installs and configures a **Shadowsocks** server using `shadowsocks-libev`.  
It generates a secure configuration with `jq`, sets up the system service, and starts it automatically.

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

After execution, the server runs at `127.0.0.1:$SHADOWSOCKS_PORT`.

---

## tor-setup.bash — Tor Client Install Module

### Description
The `tor-setup.bash` module installs and configures the **Tor client** on a Debian-based system.  
It adds the official repo, installs `tor`, writes a minimal config, and ensures the client runs with SOCKS5 enabled.

### Configuration Variables

| Variable                | Description                         | Default       |
|-------------------------|-------------------------------------|---------------|
| `TOR_SETUP_SOCKS_HOST` | IP address to bind SOCKS proxy      | `127.0.0.1`   |
| `TOR_SETUP_SOCKS_PORT` | Port for Tor SOCKS proxy            | `9050`        |

### Usage Example

```bash
@module tor-setup.bash
```

After execution, the Tor client runs with a SOCKS5 proxy at `${TOR_SETUP_SOCKS_HOST}:${TOR_SETUP_SOCKS_PORT}`.

---

## tor-singlehop-setup.bash — Tor Hidden Service (Single Hop) Module

### Description
The `tor-singlehop-setup.bash` module sets up a **Tor Hidden Service in Single Hop Mode**.  
It exposes **Dante SOCKS5** and **FRP (frps)** through `.onion` addresses.

### Configuration Variables

| Variable                             | Description                                     | Default          |
|--------------------------------------|-------------------------------------------------|------------------|
| `TOR_SINGLEHOP_CONF_HS_NAME`         | Name of the tor instance                        | `singlehop`      |
| `TOR_SINGLEHOP_CONF_HS_FRP_HOST`     | Internal FRP service address                    | `127.0.0.1`      |
| `TOR_SINGLEHOP_CONF_HS_FRP_PORT`     | Internal FRP port                               | `7000`           |
| `TOR_SINGLEHOP_CONF_HS_FRP_LISTEN`   | External (Tor) port for FRP                     | `7000`           |
| `TOR_SINGLEHOP_CONF_HS_DANTE_HOST`   | Internal Dante address                          | `127.0.0.1`      |
| `TOR_SINGLEHOP_CONF_HS_DANTE_PORT`   | Internal Dante port                             | `1080`           |
| `TOR_SINGLEHOP_CONF_HS_DANTE_LISTEN` | External (Tor) port for Dante                   | `1080`           |

### Usage Example

```bash
@module tor-singlehop-setup.bash
```

After execution, both FRP and Dante services are reachable via a Tor `.onion` domain.

---

## tor-transparent-setup.bash — Tor Transparent Transport Module

### Description
The `tor-transparent-setup.bash` module configures a **Tor instance for transparent proxying and DNS routing**.  
It enables **TransPort** and **DNSPort**, sets up routing rules via `nftables`, and rewrites `/etc/resolv.conf`.

### Configuration Variables

| Variable                             | Description                                           | Default             |
|--------------------------------------|-------------------------------------------------------|---------------------|
| `TOR_TRANSPARENT_CONF_INSTANCE_NAME` | Name of the Tor instance                              | `transparent`       |
| `TOR_TRANSPARENT_CONF_DNS_HOST`      | DNSPort bind address                                  | `127.0.5.3`         |
| `TOR_TRANSPARENT_CONF_DNS_PORT`      | DNSPort bind port                                     | `53`                |
| `TOR_TRANSPARENT_CONF_TRANS_HOST`    | TransPort bind address                                | `127.0.0.1`         |
| `TOR_TRANSPARENT_CONF_TRANS_PORT`    | TransPort bind port                                   | `9040`              |
| `TOR_TRANSPARENT_CONF_TRANS_OPTS`    | Isolation options for TransPort                       | `Isolate*` flags    |
| `TOR_TRANSPARENT_CONF_VIRTUAL_NET`   | Virtual address space routed through Tor              | `10.192.0.0/10`     |

### Usage Example

```bash
@module tor-transparent-setup.bash
```

After execution, all DNS and TCP traffic in the virtual range is routed through Tor.

---

## veracrypt-setup.bash — VeraCrypt Console Installer Module

### Description
The `veracrypt-setup.bash` module installs the **console version of VeraCrypt** on Debian 12.  
It downloads the `.deb`, installs via apt, and logs progress.

### Configuration Variables

| Variable                  | Description                              | Default         |
|---------------------------|------------------------------------------|-----------------|
| `VERACRYPT_SETUP_VERSION` | VeraCrypt version to install             | `1.26.20`       |

### Usage Example

```bash
@module veracrypt-setup.bash
```

---

## threeproxy-setup.bash — 3proxy Install Module

### Description
The `threeproxy-setup` module installs and configures **3proxy** with SOCKS5, HTTP, and SMTP relay.  
It sets up a user, secure config, and systemd service.

### Configuration Variables

| Variable                               | Description                            | Default                          |
|----------------------------------------|----------------------------------------|----------------------------------|
| `THREEPROXY_SETUP_USER`                | Login user for proxy auth              | `3proxy-user-<random>`           |
| `THREEPROXY_SETUP_PASSWORD`            | Password for the proxy user            | `openssl rand -hex 16`           |
| `PROXY_SETUP_INTERNAL_HOST`            | IP address to bind proxy interfaces    | `127.0.0.1`                      |
| `THREEPROXY_SETUP_INTERNAL_PORT`       | SOCKS5 proxy port                      | `1081`                           |
| `THREEPROXY_SETUP_HTTP_INTERNAL_PORT`  | HTTP proxy port                        | `3128`                           |
| `THREEPROXY_SETUP_SMTP_INTERNAL_PORT`  | Local SMTP relay port                  | `587`                            |
| `THREEPROXY_SETUP_SMTP_RELAY_HOST`     | Remote SMTP relay host                 | `smtp.mailgun.org`                |
| `THREEPROXY_SETUP_SMTP_RELAY_PORT`     | Remote SMTP relay port                 | `587`                            |

### Usage Example

```bash
@module threeproxy-setup.bash
```

---

## bitwarden-bw-setup.bash — Bitwarden CLI Install Module

### Description
The `bitwarden-bw-setup.bash` module installs the **Bitwarden CLI (`bw`)**.  
It downloads the release, installs the binary into system path, and logs via `logger.bash`.

### Configuration Variables

| Variable         | Description                              | Default          |
|------------------|------------------------------------------|------------------|
| `BW_VERSION`     | Version of Bitwarden CLI                 | `1.22.1`         |
| `BW_INSTALL_DIR` | Directory to install `bw` binary         | `/usr/local/bin` |

### Usage Example

```bash
@module bitwarden-bw-setup.bash
```

---

## bitwarden-bws-setup.bash — Bitwarden Secrets Manager CLI Install Module

### Description
The `bitwarden-bws-setup.bash` module installs the **Bitwarden Secrets Manager CLI (`bws`)**.  
It downloads the release, installs the binary into system path, and logs via `logger.bash`.

### Configuration Variables

| Variable         | Description                              | Default          |
|------------------|------------------------------------------|------------------|
| `BWS_VERSION`    | Version of Bitwarden Secrets CLI         | `1.0.0`          |
| `BWS_INSTALL_DIR`| Directory to install `bws` binary        | `/usr/local/bin` |

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

| Variable                         | Description                             | Default                                                           |
|----------------------------------|-----------------------------------------|-------------------------------------------------------------------|
| `OUTLINE_SETUP_REPO_URL`         | Git repository URL for Outline          | `https://github.com/ldev1281/docker-compose-outline.git`          |
| `OUTLINE_SETUP_TARGET_PARENT_DIR`| Parent directory for Outline            | `/docker`                                                         |
| `OUTLINE_SETUP_TARGET_DIR`       | Target directory for Outline instance   | `${OUTLINE_SETUP_TARGET_PARENT_DIR}/outline`                      |

### Usage Example

```bash
@module outline-setup.bash
```

---

## authentik-setup.bash — Authentik Install Module

### Description
The `authentik-setup` module automates deployment of **Authentik** via Docker Compose.  
It prepares environment, clones repo, and executes `init.bash`.

### Configuration Variables

| Variable                           | Description                           | Default                                                           |
|------------------------------------|---------------------------------------|-------------------------------------------------------------------|
| `AUTHENTIK_SETUP_REPO_URL`         | Git repository URL for Authentik      | `https://github.com/ldev1281/docker-compose-authentik.git`        |
| `AUTHENTIK_SETUP_TARGET_PARENT_DIR`| Parent directory for Authentik        | `/docker`                                                         |
| `AUTHENTIK_SETUP_TARGET_DIR`       | Target directory for Authentik        | `${AUTHENTIK_SETUP_TARGET_PARENT_DIR}/authentik`                  |

### Usage Example

```bash
@module authentik-setup.bash
```

---

## proxy-client-setup.bash — Proxy Client Install Module

### Description
The `proxy-client-setup` module automates deployment of a proxy client stack via Docker Compose.  
It prepares environment, clones repo, and executes `init.bash`.

### Configuration Variables

| Variable                                | Description                           | Default                                                                 |
|-----------------------------------------|---------------------------------------|-------------------------------------------------------------------------|
| `PROXY_CLIENT_SETUP_REPO_URL`           | Git repository URL for proxy client   | `https://github.com/ldev1281/docker-compose-proxy-client.git`           |
| `PROXY_CLIENT_SETUP_TARGET_PARENT_DIR`  | Parent directory for proxy client     | `/docker`                                                               |
| `PROXY_CLIENT_SETUP_TARGET_DIR`         | Target directory for proxy client     | `${PROXY_CLIENT_SETUP_TARGET_PARENT_DIR}/proxy-client`                  |

### Usage Example

```bash
@module proxy-client-setup.bash
```

---

## youtrack-setup.bash — YouTrack Install Module

### Description
The `youtrack-setup` module automates deployment of **YouTrack** via Docker Compose.  
It prepares environment, clones repo, and executes `init.bash`.

### Configuration Variables

| Variable                           | Description                            | Default                                                           |
|------------------------------------|----------------------------------------|-------------------------------------------------------------------|
| `YOUTRACK_SETUP_REPO_URL`          | Git repository URL for YouTrack        | `https://github.com/ldev1281/docker-compose-youtrack.git`         |
| `YOUTRACK_SETUP_TARGET_PARENT_DIR` | Parent directory for YouTrack          | `/docker`                                                         |
| `YOUTRACK_SETUP_TARGET_DIR`        | Target directory for YouTrack instance | `${YOUTRACK_SETUP_TARGET_PARENT_DIR}/youtrack`                    |

### Usage Example

```bash
@module youtrack-setup.bash
```

---

## firefly-setup.bash — Firefly III Install Module

### Description
The `firefly-setup` module automates deployment of **Firefly III** via Docker Compose.  
It prepares environment, clones repo, and executes `init.bash`.

### Configuration Variables

| Variable                           | Description                            | Default                                                           |
|------------------------------------|----------------------------------------|-------------------------------------------------------------------|
| `FIREFLY_SETUP_REPO_URL`           | Git repository URL for Firefly III     | `https://github.com/ldev1281/docker-compose-firefly.git`          |
| `FIREFLY_SETUP_TARGET_PARENT_DIR`  | Parent directory for Firefly III       | `/docker`                                                         |
| `FIREFLY_SETUP_TARGET_DIR`         | Target directory for Firefly instance  | `${FIREFLY_SETUP_TARGET_PARENT_DIR}/firefly`                      |

### Usage Example

```bash
@module firefly-setup.bash
```