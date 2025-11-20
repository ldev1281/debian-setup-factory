# outline setup module
set -Euo pipefail

@module logger.bash

###############################################################################
# CONFIGURATION (ALL VARIABLES MUST BE HERE)
###############################################################################

# Application Identity
OUTLINE_SETUP_APP_NAME="${OUTLINE_SETUP_APP_NAME:-outline}"

# GitHub Repository (owner/repo)
OUTLINE_SETUP_GITHUB_REPO="${OUTLINE_SETUP_GITHUB_REPO:-ldev1281/docker-compose-outline}"

# Install target directories
OUTLINE_SETUP_TARGET_PARENT_DIR="${OUTLINE_SETUP_TARGET_PARENT_DIR:-/docker}"
OUTLINE_SETUP_TARGET_DIR="${OUTLINE_SETUP_TARGET_DIR:-${OUTLINE_SETUP_TARGET_PARENT_DIR}/${OUTLINE_SETUP_APP_NAME}}"

# Release version (empty → latest)
OUTLINE_SETUP_VERSION="${OUTLINE_SETUP_VERSION:-}"

# Init script path
OUTLINE_SETUP_INIT_PATH="${OUTLINE_SETUP_INIT_PATH:-./tools/init.bash}"

# Tmp directory for archive extraction
OUTLINE_SETUP_TMP_DIR="${OUTLINE_SETUP_TMP_DIR:-$(mktemp -d)}"

# Archive filename inside tmp
OUTLINE_SETUP_ARCHIVE_FILE="${OUTLINE_SETUP_ARCHIVE_FILE:-${OUTLINE_SETUP_TMP_DIR}/${OUTLINE_SETUP_APP_NAME}-release.tar.gz}"

# Backup root directory
OUTLINE_SETUP_BACKUP_ROOT="${OUTLINE_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
OUTLINE_SETUP_BACKUP_DIR="${OUTLINE_SETUP_BACKUP_DIR:-${OUTLINE_SETUP_BACKUP_ROOT}/${OUTLINE_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"

###############################################################################
# START
###############################################################################

logger::log "Setting up ${OUTLINE_SETUP_APP_NAME} via docker-compose (release mode)"

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
logger::log "Ensuring target directory exists: ${OUTLINE_SETUP_TARGET_DIR}"
mkdir -p "${OUTLINE_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${OUTLINE_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE VERSION
###############################################################################
if [ -z "${OUTLINE_SETUP_VERSION}" ]; then
  OUTLINE_SETUP_API_URL="https://api.github.com/repos/${OUTLINE_SETUP_GITHUB_REPO}/releases/latest"
  logger::log "Determining latest release tag from ${OUTLINE_SETUP_API_URL}"

  OUTLINE_SETUP_VERSION="$(
    curl -fsSL "${OUTLINE_SETUP_API_URL}" | jq -r '.tag_name' 2>/dev/null || echo ""
  )"

  [ -n "${OUTLINE_SETUP_VERSION}" ] || logger::err "Failed to detect latest tag"
  logger::log "Latest release tag: ${OUTLINE_SETUP_VERSION}"
else
  logger::log "Using user-provided release tag: ${OUTLINE_SETUP_VERSION}"
fi

OUTLINE_SETUP_ARCHIVE_URL="https://github.com/${OUTLINE_SETUP_GITHUB_REPO}/archive/refs/tags/${OUTLINE_SETUP_VERSION}.tar.gz"
logger::log "Archive URL: ${OUTLINE_SETUP_ARCHIVE_URL}"


###############################################################################
# DOWNLOAD & EXTRACT RELEASE
###############################################################################
logger::log "Downloading: ${OUTLINE_SETUP_ARCHIVE_URL}"
curl -fsSL "${OUTLINE_SETUP_ARCHIVE_URL}" -o "${OUTLINE_SETUP_ARCHIVE_FILE}" \
  || logger::err "Failed to download archive"

logger::log "Extracting archive into: ${OUTLINE_SETUP_TMP_DIR}"
tar -xzf "${OUTLINE_SETUP_ARCHIVE_FILE}" -C "${OUTLINE_SETUP_TMP_DIR}" \
  || logger::err "Failed to extract archive"

OUTLINE_SETUP_EXTRACTED_SUBDIR="$(find "${OUTLINE_SETUP_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[ -n "${OUTLINE_SETUP_EXTRACTED_SUBDIR}" ] || logger::err "Extracted directory not found"

logger::log "Extracted directory: ${OUTLINE_SETUP_EXTRACTED_SUBDIR}"


###############################################################################
# BACKUP REMOVED/OVERWRITTEN FILES
###############################################################################
logger::log "Preparing backup directory: ${OUTLINE_SETUP_BACKUP_DIR}"
mkdir -p "${OUTLINE_SETUP_BACKUP_DIR}" \
  || logger::err "Failed to create backup directory"


###############################################################################
# SYNC WITH RSYNC (PRESERVE .env & vol)
###############################################################################
logger::log "Syncing release → ${OUTLINE_SETUP_TARGET_DIR}"
logger::log "Backup of removed/overwritten files → ${OUTLINE_SETUP_BACKUP_DIR}"

rsync -a \
  --delete \
  --backup \
  --backup-dir="${OUTLINE_SETUP_BACKUP_DIR}" \
  --suffix=".bak" \
  --exclude '.env' \
  --exclude 'vol' \
  "${OUTLINE_SETUP_EXTRACTED_SUBDIR}/" "./" \
  || logger::err "Failed to sync release files"


###############################################################################
# INIT SCRIPT
###############################################################################
if [ -x "${OUTLINE_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (exec): ${OUTLINE_SETUP_INIT_PATH}"
  "${OUTLINE_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${OUTLINE_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (bash): ${OUTLINE_SETUP_INIT_PATH}"
  bash "${OUTLINE_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found: ${OUTLINE_SETUP_INIT_PATH}"
fi