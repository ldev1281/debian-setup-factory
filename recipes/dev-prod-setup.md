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

| Secret Name                                   | Required                                  | Description                                                     | Example                         |
|-----------------------------------------------|-------------------------------------------|-----------------------------------------------------------------|----------------------------------|
| `proxy-hostname`                              | yes                                       | External proxy hostname (used by client)                       | `proxy.stage.example.com`       |
| `proxy-socks5h-port`                          | yes                                       | Local SOCKS5h proxy port                                       | `1080`                          |
| `proxy-frp-port`                              | yes                                       | TCP port for FRP                                               | `7000`                          |
| `proxy-frp-token`                             | yes                                       | Authentication token for FRP                                   | `random32chars`                 |
| `app-authentik-hostname`                      | yes (if installing Authentik, GitLab)     | Authentik app hostname behind proxy                            | `auth.stage.example.com`        |
| `app-firefly-hostname`                        | yes (if installing Firefly)               | Firefly app hostname behind proxy                              | `firefly.stage.example.com`     |
| `app-youtrack-hostname`                      | yes (if installing YouTrack)              | YouTrack app hostname behind proxy                             | `youtrack.stage.example.com`    |
| `app-gitlab-hostname`                         | yes (if installing GitLab)                | GitLab app hostname behind proxy                               | `gitlab.stage.example.com`      |
| `app-registry-hostname`                       | yes (if installing GitLab)                | Docker Registry hostname behind proxy                          | `registry.stage.example.com`    |
| `app-gitlab-authentik-client-id`              | yes (if installing GitLab)                | OIDC client ID for GitLab (from Authentik)                     | `gitlab-oidc-client-id`         |
| `app-gitlab-authentik-client-secret`          | yes (if installing GitLab)                | OIDC client secret for GitLab (from Authentik)                 | `supersecret123`                |
| `app-gitlab-smtp-username`                    | yes (if installing GitLab)                | SMTP username for GitLab                                       | `gitlab@stage.example.com`      |
| `app-gitlab-smtp-password`                    | yes (if installing GitLab)                | SMTP password for GitLab                                       | `strong-password`               |
| `app-authentik-email-username`                | yes (if installing Authentik)             | SMTP username for Authentik                                    | `authentik@stage.example.com`   |
| `app-authentik-email-password`                | yes (if installing Authentik)             | SMTP password for Authentik                                    | `another-strong-password`       |
| `app-authentik-email-from`                    | yes (if installing Authentik)             | Default “from” email for Authentik                             | `authentik@stage.example.com`   |
| `app-gitlab-s3-region`                        | yes (if installing GitLab)                | S3 region for GitLab object storage                            | `ap-southeast-1`                |
| `app-gitlab-s3-uploads-bucket`                | yes (if installing GitLab)                | S3 bucket for GitLab uploads                                   | `gitlab-uploads`                |
| `app-gitlab-s3-artifacts-bucket`              | yes (if installing GitLab)                | S3 bucket for GitLab CI artifacts                              | `gitlab-artifacts`              |
| `app-gitlab-s3-packages-bucket`               | yes (if installing GitLab)                | S3 bucket for GitLab packages                                  | `gitlab-packages`               |
| `app-gitlab-s3-lfs-bucket`                    | yes (if installing GitLab)                | S3 bucket for GitLab LFS (Large File Storage)                  | `gitlab-lfs`                    |
| `app-gitlab-s3-uploads-access-key`            | yes (if installing GitLab)                | S3 access key for uploads bucket                               | `AKIA...UPLOADS`                |
| `app-gitlab-s3-uploads-secret-key`            | yes (if installing GitLab)                | S3 secret key for uploads bucket                               | `secretkeyuploads`              |
| `app-gitlab-s3-artifacts-access-key`          | yes (if installing GitLab)                | S3 access key for artifacts bucket                             | `AKIA...ARTIFACTS`              |
| `app-gitlab-s3-artifacts-secret-key`          | yes (if installing GitLab)                | S3 secret key for artifacts bucket                             | `secretkeyartifacts`            |
| `app-gitlab-s3-packages-access-key`           | yes (if installing GitLab)                | S3 access key for packages bucket                              | `AKIA...PACKAGES`               |
| `app-gitlab-s3-packages-secret-key`           | yes (if installing GitLab)                | S3 secret key for packages bucket                              | `secretkeypackages`             |
| `app-gitlab-s3-lfs-access-key`                | yes (if installing GitLab)                | S3 access key for GitLab LFS bucket                            | `AKIA...LFS`                    |
| `app-gitlab-s3-lfs-secret-key`                | yes (if installing GitLab)                | S3 secret key for GitLab LFS bucket                            | `secretkeylfs`                  |
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
