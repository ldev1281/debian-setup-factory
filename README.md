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
<summary>setup-modules/logger.bash — Logger Module</summary>

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
<summary>setup-modules/shadowsocks.bash — install and configure Shadowsocks</summary>

This module installs and configures a basic [Shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev) server.

### Description

- Depends on: `logger.bash`
- Installs `openssl`, `jq`, and `shadowsocks-libev`
- Randomly generates a secure password
- Writes JSON config to `/etc/shadowsocks-libev/config.json`
- Starts and enables the systemd service

### Environment variables

You must define the following variables before running this module:

- `SS_METHOD` — encryption method (e.g., `"chacha20-ietf-poly1305"`, `"aes-256-gcm"`)
- `SS_PORT` — integer port number (e.g., `8388`)

These are used by the config generator via `jq`.

### Generated config example

```json
{
  "server": "127.0.0.1",
  "password": "auto-generated-hex",
  "method": "chacha20-ietf-poly1305",
  "mode": "tcp_and_udp",
  "server_port": 8388,
  "timeout": 300
}
```

### Example usage in a recipe

```bash
@module logger.bash
@module shadowsocks.bash
```

Make sure `SS_METHOD` and `SS_PORT` are defined either in the environment or set explicitly in your recipe.

### Notes

- The generated password is stored only in `/etc/shadowsocks-libev/config.json` — save it if you need it elsewhere.
- Fails with `logger::err` if any step cannot be completed.

</details>

---

## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.