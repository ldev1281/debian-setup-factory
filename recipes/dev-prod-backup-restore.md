# dev-prod-backup-restore.recipe
This guide describes how to build and run the **Dev Prod Backup Restore** script from the [`debian-setup-factory`](https://github.com/ldev1281/debian-setup-factory) repository.

The script is generated from a predefined recipe and can be executed directly after building.
It is intended for restoring a production server from a backup and must be run **after** executing the `dev-prod-init` recipe.

---

### Quick Start Guide

To build and run **Dev Prod Backup Restore**:

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

7. **Build** the `dev-prod-backup-restore` script from the recipe:
   ```bash
   ./builder/build.bash recipes/dev-prod-backup-restore.recipe >dist/dev-prod-backup-restore.bash
   ```

8. **Make the script executable**:
   ```bash
   chmod +x dist/dev-prod-backup-restore.bash
   ```

9. **Run the script**:
   ```bash
   ./dist/dev-prod-backup-restore.bash
   ```

### 🔑 Required Secrets

Before running `dev-prod-backup-restore.recipe`, make sure the following secrets exist in **Bitwarden Secrets Manager** project.

| Secret Name             | Required            | Description                                     | Example |
|-------------------------|---------------------|-------------------------------------------------|---------|
| `backup-gpg-private-key`| if `GPG_ENABLE=yes` | GPG **private** key (ASCII-armored) to decrypt backups | `-----BEGIN PGP PRIVATE KEY----- ...` |
| `backup-gpg-public-key` | optional            | GPG **public** key (ASCII-armored); imported if present | `-----BEGIN PGP PUBLIC KEY----- ...` |


> **Note (backup module):**  
> During execution, the script can optionally install and configure the **backup-tool** module (SFTP/S3).  
> Configuration is saved to:  
> ```
> /etc/limbo-backup/backup.conf.bash
> /etc/limbo-backup/restore.conf.bash
> ```
> You’ll be prompted interactively. You can skip or preseed via environment variables if needed.

> **BWS Access Reminder:**  
> If you have any questions about access to Bitwarden Secrets Manager (BWS), how to configure Machine Accounts or tokens — see the [Bitwarden Helpers Module documentation](https://github.com/ldev1281/debian-setup-factory/blob/dev/setup-modules/README.md#bitwarden-helpers-module-bitwardenbash).
