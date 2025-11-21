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

# Init script path (absolute, по умолчанию tools/init.bash в целевой директории)
YOUTRACK_SETUP_INIT_PATH="${YOUTRACK_SETUP_INIT_PATH:-${YOUTRACK_SETUP_TARGET_DIR}/tools/init.bash}"

# Release version (empty → latest)
YOUTRACK_SETUP_VERSION="${YOUTRACK_SETUP_VERSION:-}"

# Tmp directory for archive extraction (content goes directly here)
YOUTRACK_SETUP_TMP_DIR="${YOUTRACK_SETUP_TMP_DIR:-$(mktemp -d)}"

# Release asset name (GitHub release file)
YOUTRACK_SETUP_ARCHIVE_NAME="${YOUTRACK_SETUP_ARCHIVE_NAME:-docker-compose-${YOUTRACK_SETUP_APP_NAME}.tar.gz}"

# Backup root directory
YOUTRACK_SETUP_BACKUP_ROOT="${YOUTRACK_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
YOUTRACK_SETUP_BACKUP_DIR="${YOUTRACK_SETUP_BACKUP_DIR:-${YOUTRACK_SETUP_BACKUP_ROOT}/${YOUTRACK_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"


###############################################################################
# START
###############################################################################

logger::log "Setting up ${YOUTRACK_SETUP_APP_NAME} via docker-compose (release mode)"
logger::log "Target directory: ${YOUTRACK_SETUP_TARGET_DIR}"

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
logger::log "Ensuring target directory exists: ${YOUTRACK_SETUP_TARGET_DIR}"
mkdir -p "${YOUTRACK_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${YOUTRACK_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE ASSET URL
###############################################################################
if [ -z "${YOUTRACK_SETUP_VERSION}" ]; then
  # latest release
  YOUTRACK_SETUP_ARCHIVE_URL="https://github.com/${YOUTRACK_SETUP_GITHUB_REPO}/releases/latest/download/${YOUTRACK_SETUP_ARCHIVE_NAME}"
  logger::log "Using latest release asset: ${YOUTRACK_SETUP_ARCHIVE_URL}"
else
  # specific tag
  logger::log "Using user-provided release tag: ${YOUTRACK_SETUP_VERSION}"
  YOUTRACK_SETUP_ARCHIVE_URL="https://github.com/${YOUTRACK_SETUP_GITHUB_REPO}/releases/download/${YOUTRACK_SETUP_VERSION}/${YOUTRACK_SETUP_ARCHIVE_NAME}"
  logger::log "Release asset URL: ${YOUTRACK_SETUP_ARCHIVE_URL}"
fi


###############################################################################
# DOWNLOAD & EXTRACT RELEASE (DIRECTLY INTO TMP)
###############################################################################
logger::log "Downloading and extracting to tmp dir: ${YOUTRACK_SETUP_TMP_DIR}"
mkdir -p "${YOUTRACK_SETUP_TMP_DIR}" || logger::err "Cannot create tmp dir"

curl -fsSL "${YOUTRACK_SETUP_ARCHIVE_URL}" \
  | tar -xz -C "${YOUTRACK_SETUP_TMP_DIR}" \
  || logger::err "Failed to download/extract archive"


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
  "${YOUTRACK_SETUP_TMP_DIR}/" "./" \
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
