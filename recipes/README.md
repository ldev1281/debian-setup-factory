# Recipes manuals

## dev-proxy-setup.recipe
This guide describes how to build and run the **Dev Proxy Setup** script from the [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory) repository.

The script is generated from a predefined recipe and can be executed directly after building.
It is intended for setting up a proxy server that consists of **frp-server**, **dante-server**, and a **Tor singlehop** node.

---

### Quick Start Guide

To build and run **Dev Proxy Setup**:

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

7. **Build** the `dev-proxy-setup` script from the recipe:
   ```bash
   ./builder/build.bash recipes/dev-proxy-setup.recipe >dist/dev-proxy-setup.bash
   ```

8. **Make the script executable**:
   ```bash
   chmod +x dist/dev-proxy-setup.bash
   ```

9. **Run the script**:
   ```bash
   ./dist/dev-proxy-setup.bash
   ```

> **Note:**  
> Steps 7–9 can be repeated whenever you update the recipe or want to rebuild the script.


## dev-prod-init.recipe

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
9. **Optionally prepare ASCII-armored GPG public key** (see Notes):
   ```
   /tmp/privkey.asc
   ```
10. **Run the script**:
   ```bash
   ./dist/dev-prod-init.bash
   ```

> **Note (backup module):**
>
> During execution, the script can optionally install and configure the **backup-tool** module (SFTP/S3).
>
> If you want to use GPG encryption for backups, prepare your public GPG key and store it in a temporary folder.
>
> Configuration is saved to:
> ```
> /etc/limbo-backup/backup.conf.bash
> /etc/limbo-backup/restore.conf.bash
> ```
>
> You’ll be prompted interactively.s
> You can skip or preseed via environment variables if needed.


## dev-prod-backup-restore.recipe
This guide describes how to build and run the **Dev Prod Backup Restore** script from the [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory) repository.

The script is generated from a predefined recipe and can be executed directly after building.
It is intended for restoring a production server from a backup and must be run **after** executing the `dev-prod-init` recipe.

---

### Quick Start Guide

To build and run **Dev Prod Backup Restore**:

1. **Navigate to `/tmp`**:
   ```
   cd /tmp
   ```

2. **Download** the latest repository archive:
   ```
   wget https://github.com/ldev1281/debian-setup-factory/archive/refs/heads/main.zip
   ```

3. **Install `unzip`** (if not already installed):
   ```
   apt install unzip
   ```

4. **Extract** the downloaded archive:
   ```
   unzip main.zip
   ```

5. **Go to the extracted folder**:
   ```
   cd debian-setup-factory-main
   ```

6. **Create the `dist` directory**:
   ```
   mkdir ./dist
   ```

7. **Build** the `dev-prod-backup-restore` script from the recipe:
   ```
   ./builder/build.bash recipes/dev-prod-backup-restore.recipe >dist/dev-prod-backup-restore.bash
   ```

8. **Make the script executable**:
   ```
   chmod +x dist/dev-prod-backup-restore.bash
   ```

9. **Optionally prepare ASCII-armored GPG private and public keys** (see Notes):
   ```
   /tmp/privkey.asc
   /tmp/pubkey.asc
   ```

10. **Run the script**:
   ```
   ./dist/dev-prod-backup-restore.bash
   ```

> **Note:**
> This script should only be executed after running **dev-prod-init**,
> as it relies on the server environment prepared by that recipe.
>
> During execution, the script can optionally use private GPG key to decrypt the backup
> and import your public GPG key for later use (backup encryption).
>
> If you want to use GPG to decrypt the backup,
> prepare your private and public GPG keys
> and store them in a temporary folder.