# proxy-client setup module
set -Euo pipefail

@module logger.bash

###############################################################################
# CONFIGURATION (ALL VARIABLES MUST BE HERE)
###############################################################################

# Application Identity
PROXY_CLIENT_SETUP_APP_NAME="${PROXY_CLIENT_SETUP_APP_NAME:-proxy-client}"

# GitHub Repository (owner/repo)
PROXY_CLIENT_SETUP_GITHUB_REPO="${PROXY_CLIENT_SETUP_GITHUB_REPO:-ldev1281/docker-compose-proxy-client}"

# Install target directories
PROXY_CLIENT_SETUP_TARGET_PARENT_DIR="${PROXY_CLIENT_SETUP_TARGET_PARENT_DIR:-/docker}"
PROXY_CLIENT_SETUP_TARGET_DIR="${PROXY_CLIENT_SETUP_TARGET_DIR:-${PROXY_CLIENT_SETUP_TARGET_PARENT_DIR}/${PROXY_CLIENT_SETUP_APP_NAME}}"

# Init script path (absolute, по умолчанию tools/init.bash в целевой директории)
PROXY_CLIENT_SETUP_INIT_PATH="${PROXY_CLIENT_SETUP_INIT_PATH:-${PROXY_CLIENT_SETUP_TARGET_DIR}/tools/init.bash}"

# Release version (empty → latest)
PROXY_CLIENT_SETUP_VERSION="${PROXY_CLIENT_SETUP_VERSION:-}"

# Tmp directory for archive extraction (content goes directly here)
PROXY_CLIENT_SETUP_TMP_DIR="${PROXY_CLIENT_SETUP_TMP_DIR:-$(mktemp -d)}"

# Release asset name (GitHub release file)
PROXY_CLIENT_SETUP_ARCHIVE_NAME="${PROXY_CLIENT_SETUP_ARCHIVE_NAME:-docker-compose-${PROXY_CLIENT_SETUP_APP_NAME}.tar.gz}"

# Backup root directory
PROXY_CLIENT_SETUP_BACKUP_ROOT="${PROXY_CLIENT_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
PROXY_CLIENT_SETUP_BACKUP_DIR="${PROXY_CLIENT_SETUP_BACKUP_DIR:-${PROXY_CLIENT_SETUP_BACKUP_ROOT}/${PROXY_CLIENT_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"


###############################################################################
# START
###############################################################################

logger::log "Setting up ${PROXY_CLIENT_SETUP_APP_NAME} via docker-compose (release mode)"
logger::log "Target directory: ${PROXY_CLIENT_SETUP_TARGET_DIR}"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"


###############################################################################
# DEPENDENCIES
###############################################################################
logger::log "Installing dependencies (ca-certificates, curl, tar, gzip, rsync)"
apt update || logger::err "apt update failed"
apt install -y ca-certificates curl tar gzip rsync || logger::err "Failed to install required packages"


###############################################################################
# PREPARE TARGET DIRECTORY
###############################################################################
logger::log "Ensuring target directory exists: ${PROXY_CLIENT_SETUP_TARGET_DIR}"
mkdir -p "${PROXY_CLIENT_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${PROXY_CLIENT_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE ASSET URL
###############################################################################
if [ -z "${PROXY_CLIENT_SETUP_VERSION}" ]; then
  # latest release
  PROXY_CLIENT_SETUP_ARCHIVE_URL="https://github.com/${PROXY_CLIENT_SETUP_GITHUB_REPO}/releases/latest/download/${PROXY_CLIENT_SETUP_ARCHIVE_NAME}"
  logger::log "Using latest release asset: ${PROXY_CLIENT_SETUP_ARCHIVE_URL}"
else
  # specific tag
  logger::log "Using user-provided release tag: ${PROXY_CLIENT_SETUP_VERSION}"
  PROXY_CLIENT_SETUP_ARCHIVE_URL="https://github.com/${PROXY_CLIENT_SETUP_GITHUB_REPO}/releases/download/${PROXY_CLIENT_SETUP_VERSION}/${PROXY_CLIENT_SETUP_ARCHIVE_NAME}"
  logger::log "Release asset URL: ${PROXY_CLIENT_SETUP_ARCHIVE_URL}"
fi


###############################################################################
# DOWNLOAD & EXTRACT RELEASE (DIRECTLY INTO TMP)
###############################################################################
logger::log "Downloading and extracting to tmp dir: ${PROXY_CLIENT_SETUP_TMP_DIR}"
mkdir -p "${PROXY_CLIENT_SETUP_TMP_DIR}" || logger::err "Cannot create tmp dir"

curl -fsSL "${PROXY_CLIENT_SETUP_ARCHIVE_URL}" \
  | tar -xz -C "${PROXY_CLIENT_SETUP_TMP_DIR}" \
  || logger::err "Failed to download/extract archive"


###############################################################################
# BACKUP REMOVED/OVERWRITTEN FILES
###############################################################################
logger::log "Preparing backup directory: ${PROXY_CLIENT_SETUP_BACKUP_DIR}"
mkdir -p "${PROXY_CLIENT_SETUP_BACKUP_DIR}" \
  || logger::err "Failed to create backup directory"


###############################################################################
# SYNC WITH RSYNC (PRESERVE .env & vol)
###############################################################################
logger::log "Syncing release → ${PROXY_CLIENT_SETUP_TARGET_DIR}"
logger::log "Backup of removed/overwritten files → ${PROXY_CLIENT_SETUP_BACKUP_DIR}"

rsync -a \
  --delete \
  --backup \
  --backup-dir="${PROXY_CLIENT_SETUP_BACKUP_DIR}" \
  --suffix=".bak" \
  --exclude '.env' \
  --exclude 'vol' \
  "${PROXY_CLIENT_SETUP_TMP_DIR}/" "./" \
  || logger::err "Failed to sync release files"


###############################################################################
# INIT SCRIPT
###############################################################################
if [ -x "${PROXY_CLIENT_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (exec): ${PROXY_CLIENT_SETUP_INIT_PATH}"
  "${PROXY_CLIENT_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${PROXY_CLIENT_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (bash): ${PROXY_CLIENT_SETUP_INIT_PATH}"
  bash "${PROXY_CLIENT_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found: ${PROXY_CLIENT_SETUP_INIT_PATH}"
fi
