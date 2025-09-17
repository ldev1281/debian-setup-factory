# dev-prod-init.recipe

Build and run the **Dev Prod Init** script from [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory).
Generates the script from a recipe and runs it.
It is intended for setting up a server that consists of **Docker**, **Tor**, **Tor Transparent**, **VeraCrypt**, **Backup Tool**, and **Bitwarden CLI**.

Optionally, the script can also configure the **backup-tool**
for using **S3 storage** and **GPG encryption** for backups.

---

### Quick Start Guide

To build and run **Dev Prod Init**:

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

7. **Build** the `dev-prod-init` script from the recipe:
   ```bash
   ./builder/build.bash recipes/dev-prod-init.recipe >dist/dev-prod-init.bash
   ```

8. **Make the script executable**:
   ```bash
   chmod +x dist/dev-prod-init.bash
   ```

9. **Run the script**:
   ```bash
   ./dist/dev-prod-init.bash
   ```

> **Note:**  
> This script should only be executed after running **dev-proxy-setup**,  
> as it relies on the server environment prepared by that recipe.  
>
> During execution, the script can optionally use private GPG key to decrypt the backup  
> and import your public GPG key for later use (backup encryption).

> **BWS Access Reminder:**  
> If you have any questions about access to Bitwarden Secrets Manager (BWS), how to configure Machine Accounts or tokens — see the [Bitwarden Helpers Module documentation](https://github.com/ldev1281/debian-setup-factory/blob/dev/setup-modules/README.md#bitwarden-helpers-module-bitwardenbash).
