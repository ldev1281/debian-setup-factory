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

### Module: `setup-modules/test-hello.bash`

```bash
@module logger.bash

logger::log "Hello from test-hello.bash"
echo "This is a simple test module."
```

### Module: `setup-modules/test-failing.bash`

```bash
@module logger.bash

logger::log "About to simulate a failure..."
logger::err "Intentional failure from test-failing.bash"
echo "This line should not be executed."
```

### Module: `setup-modules/logger.bash`

```bash
# logger module

# Set default log tag if not defined
LOG_TAG="${LOG_TAG:-setup-script}"

logger::log() {
  logger -t "$LOG_TAG" "$1"
  echo "[*] $1"
}

logger::err() {
  logger -t "$LOG_TAG" "[ERROR] $1"
  echo "[!] ERROR: $1" >&2
  exit 1
}
```

This module defines two logging functions:

* `logger::log "message"`: Logs informational messages.
* `logger::err "message"`: Logs and prints errors, then exits.

## Usage

```bash
./builder/build.bash recipes/debian-proxy-setup.recipe > dist/debian-proxy-setup.bash
chmod +x dist/debian-proxy-setup.bash
```

This will create a standalone Bash script combining all modules and inline steps.


## License

Licensed under the Prostokvashino License. See [LICENSE](LICENSE) for details.