# debian-setup-factory

**debian-setup-factory** is a modular Bash setup script assembler for Debian-based systems.  
It allows you to define reusable shell modules and compose them with additional configuration steps using flexible recipe files.

---

## Features

- **Modular**: Reuse setup modules like `tor.bash`, `veracrypt.bash`, etc.
- **Customizable**: Recipes can include additional inline shell commands.
- **Simple CLI**: Compose scripts with a single command.
- **CI-Ready**: Integrate easily into GitHub Actions or your CI system.

## Project Structure

```
debian-setup-factory/
├── builder/
│   └── build.bash              # Script builder
├── setup-modules/
│   ├── tor.bash                # Reusable setup modules
│   └── veracrypt.bash
├── recipes/
│   └── debian-proxy-setup.recipe  # Composition file
├── dist/
│   └── (output scripts go here)
└── .github/workflows/
    └── build.yml              # Optional GitHub Actions CI
```

## Recipe File Format

A **recipe** is a plain-text file that defines a setup script by combining reusable modules and inline shell commands.

Each recipe is parsed line by line and can contain:

* Module references via `@module <filename>`
* Inline shell commands
* Comments starting with `#`
* Empty lines (ignored)

Modules are resolved from the `setup-modules/` directory. Only lines starting with `@module` are interpreted specially; all other non-comment lines are treated as literal shell code.

### Recipe Example: `recipes/test.recipe`

```bash
# Test recipe

@module logger.bash
@module test-hello.bash
@module test-failing.bash
```

This recipe:

* Includes the `logger.bash` module (which defines logging functions)
* Runs a hello message
* Then triggers a simulated failure

## Module File Format

Each module in `setup-modules/` is a reusable Bash fragment. Modules:

* Can include other modules using `@module`
* May define functions, install packages, or perform configuration steps
* Are parsed recursively with the same logic as recipes
* Are only included once, even if referenced multiple times

Modules should **not** include a shebang (`#!/bin/bash`) and should avoid calls to `exit`, unless explicitly designed to abort the entire script.

## Usage

```bash
./builder/build.bash recipes/debian-proxy-setup.recipe > dist/debian-proxy-setup.bash
chmod +x dist/debian-proxy-setup.bash
```

This will create a standalone Bash script combining all modules and inline steps.

---

## Available modules

<details>

<summary>`setup-modules/logger.bash` — Logger Module</summary>

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


<details>

<summary>`setup-modules/shadowsocks.bash` — install and configure Shadowsocks</summary>

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
@module shadowsocks.bash
```

You can override configuration by setting environment variables beforehand:

```bash
export SHADOWSOCKS_METHOD="chacha20-ietf-poly1305"
export SHADOWSOCKS_PORT=8388
@module shadowsocks.bash
```

### Notes

* The generated password is only stored in `/etc/shadowsocks-libev/config.json`. Make sure to back it up if needed.
* All errors are logged using `logger::err`, which halts execution.
* This module is intended for localhost-bound server setup (`127.0.0.1`) — suitable for proxying via Tor or similar.

</details>


<details>

<summary>`setup-modules/frp-server.bash` — install and configure frp server (frps)</summary>

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


---

## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.