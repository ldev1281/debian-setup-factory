# authentik setup module
set -Euo pipefail

@module logger.bash

###############################################################################
# CONFIGURATION (ALL VARIABLES MUST BE HERE)
###############################################################################

# Application Identity
AUTHENTIK_SETUP_APP_NAME="${AUTHENTIK_SETUP_APP_NAME:-authentik}"

# GitHub Repository (owner/repo)
AUTHENTIK_SETUP_GITHUB_REPO="${AUTHENTIK_SETUP_GITHUB_REPO:-ldev1281/docker-compose-authentik}"

# Install target directories
AUTHENTIK_SETUP_TARGET_PARENT_DIR="${AUTHENTIK_SETUP_TARGET_PARENT_DIR:-/docker}"
AUTHENTIK_SETUP_TARGET_DIR="${AUTHENTIK_SETUP_TARGET_DIR:-${AUTHENTIK_SETUP_TARGET_PARENT_DIR}/${AUTHENTIK_SETUP_APP_NAME}}"

# Release version (empty → latest)
AUTHENTIK_SETUP_VERSION="${AUTHENTIK_SETUP_VERSION:-}"

# Init script path
AUTHENTIK_SETUP_INIT_PATH="${AUTHENTIK_SETUP_INIT_PATH:-./tools/init.bash}"

# Tmp directory for archive extraction
AUTHENTIK_SETUP_TMP_DIR="${AUTHENTIK_SETUP_TMP_DIR:-$(mktemp -d)}"

# Archive filename inside tmp
AUTHENTIK_SETUP_ARCHIVE_FILE="${AUTHENTIK_SETUP_ARCHIVE_FILE:-${AUTHENTIK_SETUP_TMP_DIR}/${AUTHENTIK_SETUP_APP_NAME}-release.tar.gz}"

# Backup root directory
AUTHENTIK_SETUP_BACKUP_ROOT="${AUTHENTIK_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
AUTHENTIK_SETUP_BACKUP_DIR="${AUTHENTIK_SETUP_BACKUP_DIR:-${AUTHENTIK_SETUP_BACKUP_ROOT}/${AUTHENTIK_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"

###############################################################################
# START
###############################################################################

logger::log "Setting up ${AUTHENTIK_SETUP_APP_NAME} via docker-compose (release mode)"

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
logger::log "Ensuring target directory exists: ${AUTHENTIK_SETUP_TARGET_DIR}"
mkdir -p "${AUTHENTIK_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${AUTHENTIK_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE VERSION
###############################################################################
if [ -z "${AUTHENTIK_SETUP_VERSION}" ]; then
  AUTHENTIK_SETUP_API_URL="https://api.github.com/repos/${AUTHENTIK_SETUP_GITHUB_REPO}/releases/latest"
  logger::log "Determining latest release tag from ${AUTHENTIK_SETUP_API_URL}"

  AUTHENTIK_SETUP_VERSION="$(
    curl -fsSL "${AUTHENTIK_SETUP_API_URL}" | jq -r '.tag_name' 2>/dev/null || echo ""
  )"

  [ -n "${AUTHENTIK_SETUP_VERSION}" ] || logger::err "Failed to detect latest tag"
  logger::log "Latest release tag: ${AUTHENTIK_SETUP_VERSION}"
else
  logger::log "Using user-provided release tag: ${AUTHENTIK_SETUP_VERSION}"
fi

AUTHENTIK_SETUP_ARCHIVE_URL="https://github.com/${AUTHENTIK_SETUP_GITHUB_REPO}/archive/refs/tags/${AUTHENTIK_SETUP_VERSION}.tar.gz"
logger::log "Archive URL: ${AUTHENTIK_SETUP_ARCHIVE_URL}"


###############################################################################
# DOWNLOAD & EXTRACT RELEASE
###############################################################################
logger::log "Downloading: ${AUTHENTIK_SETUP_ARCHIVE_URL}"
curl -fsSL "${AUTHENTIK_SETUP_ARCHIVE_URL}" -o "${AUTHENTIK_SETUP_ARCHIVE_FILE}" \
  || logger::err "Failed to download archive"

logger::log "Extracting archive into: ${AUTHENTIK_SETUP_TMP_DIR}"
tar -xzf "${AUTHENTIK_SETUP_ARCHIVE_FILE}" -C "${AUTHENTIK_SETUP_TMP_DIR}" \
  || logger::err "Failed to extract archive"

AUTHENTIK_SETUP_EXTRACTED_SUBDIR="$(find "${AUTHENTIK_SETUP_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[ -n "${AUTHENTIK_SETUP_EXTRACTED_SUBDIR}" ] || logger::err "Extracted directory not found"

logger::log "Extracted directory: ${AUTHENTIK_SETUP_EXTRACTED_SUBDIR}"


###############################################################################
# BACKUP REMOVED/OVERWRITTEN FILES
###############################################################################
logger::log "Preparing backup directory: ${AUTHENTIK_SETUP_BACKUP_DIR}"
mkdir -p "${AUTHENTIK_SETUP_BACKUP_DIR}" \
  || logger::err "Failed to create backup directory"


###############################################################################
# SYNC WITH RSYNC (PRESERVE .env & vol)
###############################################################################
logger::log "Syncing release → ${AUTHENTIK_SETUP_TARGET_DIR}"
logger::log "Backup of removed/overwritten files → ${AUTHENTIK_SETUP_BACKUP_DIR}"

rsync -a \
  --delete \
  --backup \
  --backup-dir="${AUTHENTIK_SETUP_BACKUP_DIR}" \
  --suffix=".bak" \
  --exclude '.env' \
  --exclude 'vol' \
  "${AUTHENTIK_SETUP_EXTRACTED_SUBDIR}/" "./" \
  || logger::err "Failed to sync release files"


###############################################################################
# INIT SCRIPT
###############################################################################
if [ -x "${AUTHENTIK_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (exec): ${AUTHENTIK_SETUP_INIT_PATH}"
  "${AUTHENTIK_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${AUTHENTIK_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (bash): ${AUTHENTIK_SETUP_INIT_PATH}"
  bash "${AUTHENTIK_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found: ${AUTHENTIK_SETUP_INIT_PATH}"
fi