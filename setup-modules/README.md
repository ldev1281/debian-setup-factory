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
