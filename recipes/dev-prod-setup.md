# dev-prod-setup.recipe
This guide describes how to build and run the **Dev Prod Setup** script from the [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory) repository.

The script is generated from a predefined recipe and can be executed directly after building.  
It is intended for setting up a production-ready environment that consists of **proxy-client**, **Authentik**, and other applications defined in the recipe.

---

### Quick Start Guide

To build and run **Dev Prod Setup**:

1. **Navigate to `/tmp`**:
   ```bash
   cd /tmp
   ```

2. **Download** the latest repository archive:
   ```bash
   wget https://github.com/ldev1281/debian-setup-factory/archive/refs/heads/main.zip
   ```

3. **Install `unzip`** (if not already installed):
   ```bash
   apt install unzip
   ```

4. **Extract** the downloaded archive:
   ```bash
   unzip main.zip
   ```

5. **Go to the extracted folder**:
   ```bash
   cd debian-setup-factory-main
   ```

6. **Create the `dist` directory**:
   ```bash
   mkdir ./dist
   ```

7. **Build** the `dev-prod-setup` script from the recipe:
   ```bash
   ./builder/build.bash recipes/dev-prod-setup.recipe > dist/dev-prod-setup.bash
   ```

8. **Make the script executable**:
   ```bash
   chmod +x dist/dev-prod-setup.bash
   ```

9. **Run the script**:
   ```bash
   ./dist/dev-prod-setup.bash
   ```

> **Note:**  
> Steps 7–9 can be repeated whenever you update the recipe or want to rebuild the script.

> **BWS Access Reminder:**  
> If you have any questions about access to Bitwarden Secrets Manager (BWS), how to configure Machine Accounts or tokens — see the [Bitwarden Helpers Module documentation](https://github.com/ldev1281/debian-setup-factory/blob/dev/setup-modules/README.md#bitwarden-helpers-module-bitwardenbash).
