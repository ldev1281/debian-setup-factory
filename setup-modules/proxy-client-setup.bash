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

# Release version (empty → latest)
PROXY_CLIENT_SETUP_VERSION="${PROXY_CLIENT_SETUP_VERSION:-}"

# Init script path
PROXY_CLIENT_SETUP_INIT_PATH="${PROXY_CLIENT_SETUP_INIT_PATH:-./tools/init.bash}"

# Tmp directory for archive extraction
PROXY_CLIENT_SETUP_TMP_DIR="${PROXY_CLIENT_SETUP_TMP_DIR:-$(mktemp -d)}"

# Archive filename inside tmp
PROXY_CLIENT_SETUP_ARCHIVE_FILE="${PROXY_CLIENT_SETUP_ARCHIVE_FILE:-${PROXY_CLIENT_SETUP_TMP_DIR}/${PROXY_CLIENT_SETUP_APP_NAME}-release.tar.gz}"

# Backup root directory
PROXY_CLIENT_SETUP_BACKUP_ROOT="${PROXY_CLIENT_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
PROXY_CLIENT_SETUP_BACKUP_DIR="${PROXY_CLIENT_SETUP_BACKUP_DIR:-${PROXY_CLIENT_SETUP_BACKUP_ROOT}/${PROXY_CLIENT_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"

###############################################################################
# START
###############################################################################

logger::log "Setting up ${PROXY_CLIENT_SETUP_APP_NAME} via docker-compose (release mode)"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"


###############################################################################
# DEPENDENCIES
###############################################################################
logger::log "Installing dependencies (ca-certificates, curl, tar, gzip, rsync, jq)"
apt update || logger::err "apt update failed"
apt install -y ca-certificates curl tar gzip rsync jq || logger::err "Failed to install required packages"


###############################################################################
# PREPARE TARGET DIRECTORY
###############################################################################
logger::log "Ensuring target directory exists: ${PROXY_CLIENT_SETUP_TARGET_DIR}"
mkdir -p "${PROXY_CLIENT_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${PROXY_CLIENT_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE VERSION
###############################################################################
if [ -z "${PROXY_CLIENT_SETUP_VERSION}" ]; then
  PROXY_CLIENT_SETUP_API_URL="https://api.github.com/repos/${PROXY_CLIENT_SETUP_GITHUB_REPO}/releases/latest"
  logger::log "Determining latest release tag from ${PROXY_CLIENT_SETUP_API_URL}"

  PROXY_CLIENT_SETUP_VERSION="$(
    curl -fsSL "${PROXY_CLIENT_SETUP_API_URL}" | jq -r '.tag_name' 2>/dev/null || echo ""
  )"

  [ -n "${PROXY_CLIENT_SETUP_VERSION}" ] || logger::err "Failed to detect latest tag"
  logger::log "Latest release tag: ${PROXY_CLIENT_SETUP_VERSION}"
else
  logger::log "Using user-provided release tag: ${PROXY_CLIENT_SETUP_VERSION}"
fi

PROXY_CLIENT_SETUP_ARCHIVE_URL="https://github.com/${PROXY_CLIENT_SETUP_GITHUB_REPO}/archive/refs/tags/${PROXY_CLIENT_SETUP_VERSION}.tar.gz"
logger::log "Archive URL: ${PROXY_CLIENT_SETUP_ARCHIVE_URL}"


###############################################################################
# DOWNLOAD & EXTRACT RELEASE
###############################################################################
logger::log "Downloading: ${PROXY_CLIENT_SETUP_ARCHIVE_URL}"
curl -fsSL "${PROXY_CLIENT_SETUP_ARCHIVE_URL}" -o "${PROXY_CLIENT_SETUP_ARCHIVE_FILE}" \
  || logger::err "Failed to download archive"

logger::log "Extracting archive into: ${PROXY_CLIENT_SETUP_TMP_DIR}"
tar -xzf "${PROXY_CLIENT_SETUP_ARCHIVE_FILE}" -C "${PROXY_CLIENT_SETUP_TMP_DIR}" \
  || logger::err "Failed to extract archive"

PROXY_CLIENT_SETUP_EXTRACTED_SUBDIR="$(find "${PROXY_CLIENT_SETUP_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[ -n "${PROXY_CLIENT_SETUP_EXTRACTED_SUBDIR}" ] || logger::err "Extracted directory not found"

logger::log "Extracted directory: ${PROXY_CLIENT_SETUP_EXTRACTED_SUBDIR}"


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
  "${PROXY_CLIENT_SETUP_EXTRACTED_SUBDIR}/" "./" \
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