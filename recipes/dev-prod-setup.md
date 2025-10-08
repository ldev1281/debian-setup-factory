# dev-prod-setup.recipe

This guide describes how to build and run the **Dev Prod Setup** script from the [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory) repository.  
The script is intended for setting up a production-ready environment that consists of **proxy-client**, **Authentik**, and other applications defined in the recipe.

The setup is performed using the **pre-built installer script** shipped with each project release.  
You don’t need to manually include `@module ...` files — they are already bundled into a single installer script available in the releases:  
<https://github.com/ldev1281/debian-setup-factory/releases>

---

### Required Secrets

You must run **`dev-proxy-setup.bash` first**, then run **`dev-prod-setup.bash`**.

- `dev-proxy-setup` **creates** (`upsert`) the following Bitwarden secrets:
  - `proxy-hostname` (Tor onion hostname)
  - `proxy-frp-token` (generated token)

Create the following secrets in **Bitwarden Secrets Manager** project **before** running `dev-prod-setup.recipe`:

| Secret Name                           | Required | Description                                                   | Example                          |
|---------------------------------------|----------|---------------------------------------------------------------|----------------------------------|
| `proxy-hostname`                      | yes      | External proxy hostname (used by client)                      | `proxy.stage.example.com`        |
| `proxy-socks5h-port`                  | yes      | Local SOCKS5h proxy port                                      | `1080`                           |
| `proxy-frp-port`                      | yes      | TCP port for FRP                                              | `7000`                           |
| `proxy-frp-token`                     | yes      | Authentication token for FRP                                  | `random32chars`                  |
| `app-authentik-hostname`              | yes      | Authentik app hostname behind proxy                           | `auth.stage.example.com`         |
| `app-outline-hostname`                | yes      | Outline app hostname behind proxy                             | `outline.stage.example.com`      |
| `app-outline-authentik-client-id`     | yes      | Authentik OAuth2 client ID for Outline                        | `outline-client-id`              |
| `app-outline-authentik-client-secret` | yes      | Authentik OAuth2 client secret for Outline                    | `supersecret`                    |
| `app-outline-authentik-url`           | yes      | Authentik OAuth2 base URL for Outline (with https, no `/`)    | `https://auth.stage.example.com` |
| `app-firefly-hostname`                | yes      | Firefly app hostname behind proxy                             | `firefly.stage.example.com`      |

> **BWS Access Reminder:**  
> If you have any questions about access to Bitwarden Secrets Manager (BWS), how to configure Machine Accounts or tokens — see the [Bitwarden Helpers Module documentation](https://github.com/ldev1281/debian-setup-factory/blob/dev/setup-modules/README.md#bitwarden-helpers-module-bitwardenbash).

---

### Quick Start Guide

To run **Dev Prod Setup**:

1. **Navigate to `/tmp`**:
   ```bash
   cd /tmp
   ```

2. **Download** the latest version:
   ```bash
   wget https://github.com/ldev1281/debian-setup-factory/releases/latest/download/dev-prod-setup.bash
   ```

3. **Make the script executable**:
   ```bash
   chmod +x dev-prod-setup.bash
   ```

4. **Run the script**:
   ```bash
   ./dev-prod-setup.bash
   ```
