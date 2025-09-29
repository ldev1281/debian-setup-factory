# dev-proxy-setup.recipe

This guide describes how to build and run the **Dev Proxy Setup** script from the [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory) repository.
The script intended for setting up a proxy server that consists of **frp-server**, **dante-server**, and a **Tor singlehop** node.

---

### Quick Start Guide

To run **Dev Proxy Setup**:

1. **Navigate to `/tmp`**:
   ```bash
   cd /tmp
   ```

2. **Download** the latest version:
   ```bash
   wget https://github.com/ldev1281/debian-setup-factory/releases/latest/download/dev-proxy-setup.bash
   ```

3. **Make the script executable**:
   ```bash
   chmod +x dev-proxy-setup.bash
   ```

4. **Run the script**:
   ```bash
   .dev-proxy-setup.bash
   ```

### Required Secrets

Ensure these exist in **Bitwarden Secrets Manager** project **before** running `dev-proxy-setup.bash`:

| Secret Name          | Required | Description              | Example |
|----------------------|----------|--------------------------|---------|
| `proxy-socks5h-port` | yes      | Dante (SOCKS) port       | `1080` |
| `proxy-frp-port`     | yes      | FRP server port          | `7000` |

**Will be created by the recipe (upsert):**
| Secret Name        | Source (created by)          |
|--------------------|------------------------------|
| `proxy-hostname`   | `tor-singlehop` (Onion host) |
| `proxy-frp-token`  | `frp-server.bash` (generated)|

> **Note Secrets:** The recipe writes the generated hostname/token back to Bitwarden.

> **BWS Access Reminder:**  
> If you have any questions about access to Bitwarden Secrets Manager (BWS), how to configure Machine Accounts or tokens — see the [Bitwarden Helpers Module documentation](https://github.com/ldev1281/debian-setup-factory/blob/dev/setup-modules/README.md#bitwarden-helpers-module-bitwardenbash).

> **Note:**  
> Steps 7–9 can be repeated whenever you update the recipe or want to rebuild the script.