# firefly setup module
set -Euo pipefail

@module logger.bash

###############################################################################
# CONFIGURATION (ALL VARIABLES MUST BE HERE)
###############################################################################

# Application Identity
FIREFLY_SETUP_APP_NAME="${FIREFLY_SETUP_APP_NAME:-firefly}"

# GitHub Repository (owner/repo)
FIREFLY_SETUP_GITHUB_REPO="${FIREFLY_SETUP_GITHUB_REPO:-ldev1281/docker-compose-firefly}"

# Install target directories
FIREFLY_SETUP_TARGET_PARENT_DIR="${FIREFLY_SETUP_TARGET_PARENT_DIR:-/docker}"
FIREFLY_SETUP_TARGET_DIR="${FIREFLY_SETUP_TARGET_DIR:-${FIREFLY_SETUP_TARGET_PARENT_DIR}/${FIREFLY_SETUP_APP_NAME}}"

# Release version (empty → latest)
FIREFLY_SETUP_VERSION="${FIREFLY_SETUP_VERSION:-}"

# Init script path
FIREFLY_SETUP_INIT_PATH="${FIREFLY_SETUP_INIT_PATH:-./tools/init.bash}"

# Tmp directory for archive extraction
FIREFLY_SETUP_TMP_DIR="${FIREFLY_SETUP_TMP_DIR:-$(mktemp -d)}"

# Archive filename inside tmp
FIREFLY_SETUP_ARCHIVE_FILE="${FIREFLY_SETUP_ARCHIVE_FILE:-${FIREFLY_SETUP_TMP_DIR}/${FIREFLY_SETUP_APP_NAME}-release.tar.gz}"

# Backup root directory
FIREFLY_SETUP_BACKUP_ROOT="${FIREFLY_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
FIREFLY_SETUP_BACKUP_DIR="${FIREFLY_SETUP_BACKUP_DIR:-${FIREFLY_SETUP_BACKUP_ROOT}/${FIREFLY_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"

###############################################################################
# START
###############################################################################

logger::log "Setting up ${FIREFLY_SETUP_APP_NAME} via docker-compose (release mode)"

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
logger::log "Ensuring target directory exists: ${FIREFLY_SETUP_TARGET_DIR}"
mkdir -p "${FIREFLY_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${FIREFLY_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE VERSION
###############################################################################
if [ -z "${FIREFLY_SETUP_VERSION}" ]; then
  FIREFLY_SETUP_API_URL="https://api.github.com/repos/${FIREFLY_SETUP_GITHUB_REPO}/releases/latest"
  logger::log "Determining latest release tag from ${FIREFLY_SETUP_API_URL}"

  FIREFLY_SETUP_VERSION="$(
    curl -fsSL "${FIREFLY_SETUP_API_URL}" | jq -r '.tag_name' 2>/dev/null || echo ""
  )"

  [ -n "${FIREFLY_SETUP_VERSION}" ] || logger::err "Failed to detect latest tag"
  logger::log "Latest release tag: ${FIREFLY_SETUP_VERSION}"
else
  logger::log "Using user-provided release tag: ${FIREFLY_SETUP_VERSION}"
fi

FIREFLY_SETUP_ARCHIVE_URL="https://github.com/${FIREFLY_SETUP_GITHUB_REPO}/archive/refs/tags/${FIREFLY_SETUP_VERSION}.tar.gz"
logger::log "Archive URL: ${FIREFLY_SETUP_ARCHIVE_URL}"


###############################################################################
# DOWNLOAD & EXTRACT RELEASE
###############################################################################
logger::log "Downloading: ${FIREFLY_SETUP_ARCHIVE_URL}"
curl -fsSL "${FIREFLY_SETUP_ARCHIVE_URL}" -o "${FIREFLY_SETUP_ARCHIVE_FILE}" \
  || logger::err "Failed to download archive"

logger::log "Extracting archive into: ${FIREFLY_SETUP_TMP_DIR}"
tar -xzf "${FIREFLY_SETUP_ARCHIVE_FILE}" -C "${FIREFLY_SETUP_TMP_DIR}" \
  || logger::err "Failed to extract archive"

FIREFLY_SETUP_EXTRACTED_SUBDIR="$(find "${FIREFLY_SETUP_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[ -n "${FIREFLY_SETUP_EXTRACTED_SUBDIR}" ] || logger::err "Extracted directory not found"

logger::log "Extracted directory: ${FIREFLY_SETUP_EXTRACTED_SUBDIR}"


###############################################################################
# BACKUP REMOVED/OVERWRITTEN FILES
###############################################################################
logger::log "Preparing backup directory: ${FIREFLY_SETUP_BACKUP_DIR}"
mkdir -p "${FIREFLY_SETUP_BACKUP_DIR}" \
  || logger::err "Failed to create backup directory"


###############################################################################
# SYNC WITH RSYNC (PRESERVE .env & vol)
###############################################################################
logger::log "Syncing release → ${FIREFLY_SETUP_TARGET_DIR}"
logger::log "Backup of removed/overwritten files → ${FIREFLY_SETUP_BACKUP_DIR}"

rsync -a \
  --delete \
  --backup \
  --backup-dir="${FIREFLY_SETUP_BACKUP_DIR}" \
  --suffix=".bak" \
  --exclude '.env' \
  --exclude 'vol' \
  "${FIREFLY_SETUP_EXTRACTED_SUBDIR}/" "./" \
  || logger::err "Failed to sync release files"


###############################################################################
# INIT SCRIPT
###############################################################################
if [ -x "${FIREFLY_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (exec): ${FIREFLY_SETUP_INIT_PATH}"
  "${FIREFLY_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${FIREFLY_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (bash): ${FIREFLY_SETUP_INIT_PATH}"
  bash "${FIREFLY_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found: ${FIREFLY_SETUP_INIT_PATH}"
fi