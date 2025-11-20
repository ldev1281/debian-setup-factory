# youtrack setup module
set -Euo pipefail

@module logger.bash

###############################################################################
# CONFIGURATION (ALL VARIABLES MUST BE HERE)
###############################################################################

# Application Identity
YOUTRACK_SETUP_APP_NAME="${YOUTRACK_SETUP_APP_NAME:-youtrack}"

# GitHub Repository (owner/repo)
YOUTRACK_SETUP_GITHUB_REPO="${YOUTRACK_SETUP_GITHUB_REPO:-ldev1281/docker-compose-youtrack}"

# Install target directories
YOUTRACK_SETUP_TARGET_PARENT_DIR="${YOUTRACK_SETUP_TARGET_PARENT_DIR:-/docker}"
YOUTRACK_SETUP_TARGET_DIR="${YOUTRACK_SETUP_TARGET_DIR:-${YOUTRACK_SETUP_TARGET_PARENT_DIR}/${YOUTRACK_SETUP_APP_NAME}}"

# Release version (empty → latest)
YOUTRACK_SETUP_VERSION="${YOUTRACK_SETUP_VERSION:-}"

# Init script path
YOUTRACK_SETUP_INIT_PATH="${YOUTRACK_SETUP_INIT_PATH:-./tools/init.bash}"

# Tmp directory for archive extraction
YOUTRACK_SETUP_TMP_DIR="${YOUTRACK_SETUP_TMP_DIR:-$(mktemp -d)}"

# Archive filename inside tmp
YOUTRACK_SETUP_ARCHIVE_FILE="${YOUTRACK_SETUP_ARCHIVE_FILE:-${YOUTRACK_SETUP_TMP_DIR}/${YOUTRACK_SETUP_APP_NAME}-release.tar.gz}"

# Backup root directory
YOUTRACK_SETUP_BACKUP_ROOT="${YOUTRACK_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
YOUTRACK_SETUP_BACKUP_DIR="${YOUTRACK_SETUP_BACKUP_DIR:-${YOUTRACK_SETUP_BACKUP_ROOT}/${YOUTRACK_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"

###############################################################################
# START
###############################################################################

logger::log "Setting up ${YOUTRACK_SETUP_APP_NAME} via docker-compose (release mode)"

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
logger::log "Ensuring target directory exists: ${YOUTRACK_SETUP_TARGET_DIR}"
mkdir -p "${YOUTRACK_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${YOUTRACK_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE VERSION
###############################################################################
if [ -z "${YOUTRACK_SETUP_VERSION}" ]; then
  YOUTRACK_SETUP_API_URL="https://api.github.com/repos/${YOUTRACK_SETUP_GITHUB_REPO}/releases/latest"
  logger::log "Determining latest release tag from ${YOUTRACK_SETUP_API_URL}"

  YOUTRACK_SETUP_VERSION="$(
    curl -fsSL "${YOUTRACK_SETUP_API_URL}" | jq -r '.tag_name' 2>/dev/null || echo ""
  )"

  [ -n "${YOUTRACK_SETUP_VERSION}" ] || logger::err "Failed to detect latest tag"
  logger::log "Latest release tag: ${YOUTRACK_SETUP_VERSION}"
else
  logger::log "Using user-provided release tag: ${YOUTRACK_SETUP_VERSION}"
fi

YOUTRACK_SETUP_ARCHIVE_URL="https://github.com/${YOUTRACK_SETUP_GITHUB_REPO}/archive/refs/tags/${YOUTRACK_SETUP_VERSION}.tar.gz"
logger::log "Archive URL: ${YOUTRACK_SETUP_ARCHIVE_URL}"


###############################################################################
# DOWNLOAD & EXTRACT RELEASE
###############################################################################
logger::log "Downloading: ${YOUTRACK_SETUP_ARCHIVE_URL}"
curl -fsSL "${YOUTRACK_SETUP_ARCHIVE_URL}" -o "${YOUTRACK_SETUP_ARCHIVE_FILE}" \
  || logger::err "Failed to download archive"

logger::log "Extracting archive into: ${YOUTRACK_SETUP_TMP_DIR}"
tar -xzf "${YOUTRACK_SETUP_ARCHIVE_FILE}" -C "${YOUTRACK_SETUP_TMP_DIR}" \
  || logger::err "Failed to extract archive"

YOUTRACK_SETUP_EXTRACTED_SUBDIR="$(find "${YOUTRACK_SETUP_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[ -n "${YOUTRACK_SETUP_EXTRACTED_SUBDIR}" ] || logger::err "Extracted directory not found"

logger::log "Extracted directory: ${YOUTRACK_SETUP_EXTRACTED_SUBDIR}"


###############################################################################
# BACKUP REMOVED/OVERWRITTEN FILES
###############################################################################
logger::log "Preparing backup directory: ${YOUTRACK_SETUP_BACKUP_DIR}"
mkdir -p "${YOUTRACK_SETUP_BACKUP_DIR}" \
  || logger::err "Failed to create backup directory"


###############################################################################
# SYNC WITH RSYNC (PRESERVE .env & vol)
###############################################################################
logger::log "Syncing release → ${YOUTRACK_SETUP_TARGET_DIR}"
logger::log "Backup of removed/overwritten files → ${YOUTRACK_SETUP_BACKUP_DIR}"

rsync -a \
  --delete \
  --backup \
  --backup-dir="${YOUTRACK_SETUP_BACKUP_DIR}" \
  --suffix=".bak" \
  --exclude '.env' \
  --exclude 'vol' \
  "${YOUTRACK_SETUP_EXTRACTED_SUBDIR}/" "./" \
  || logger::err "Failed to sync release files"


###############################################################################
# INIT SCRIPT
###############################################################################
if [ -x "${YOUTRACK_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (exec): ${YOUTRACK_SETUP_INIT_PATH}"
  "${YOUTRACK_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${YOUTRACK_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (bash): ${YOUTRACK_SETUP_INIT_PATH}"
  bash "${YOUTRACK_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found: ${YOUTRACK_SETUP_INIT_PATH}"
fi
