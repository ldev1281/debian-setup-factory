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

# Init script path (absolute, по умолчанию tools/init.bash в целевой директории)
OUTLINE_SETUP_INIT_PATH="${OUTLINE_SETUP_INIT_PATH:-${OUTLINE_SETUP_TARGET_DIR}/tools/init.bash}"

# Release version (empty → latest)
OUTLINE_SETUP_VERSION="${OUTLINE_SETUP_VERSION:-}"

# Tmp directory for archive extraction (content goes directly here)
OUTLINE_SETUP_TMP_DIR="${OUTLINE_SETUP_TMP_DIR:-$(mktemp -d)}"

# Release asset name (GitHub release file)
OUTLINE_SETUP_ARCHIVE_NAME="${OUTLINE_SETUP_ARCHIVE_NAME:-docker-compose-${OUTLINE_SETUP_APP_NAME}.tar.gz}"

# Backup root directory
OUTLINE_SETUP_BACKUP_ROOT="${OUTLINE_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
OUTLINE_SETUP_BACKUP_DIR="${OUTLINE_SETUP_BACKUP_DIR:-${OUTLINE_SETUP_BACKUP_ROOT}/${OUTLINE_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"


###############################################################################
# START
###############################################################################

logger::log "Setting up ${OUTLINE_SETUP_APP_NAME} via docker-compose (release mode)"
logger::log "Target directory: ${OUTLINE_SETUP_TARGET_DIR}"

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
logger::log "Ensuring target directory exists: ${OUTLINE_SETUP_TARGET_DIR}"
mkdir -p "${OUTLINE_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${OUTLINE_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE ASSET URL
###############################################################################
if [ -z "${OUTLINE_SETUP_VERSION}" ]; then
  # latest release
  OUTLINE_SETUP_ARCHIVE_URL="https://github.com/${OUTLINE_SETUP_GITHUB_REPO}/releases/latest/download/${OUTLINE_SETUP_ARCHIVE_NAME}"
  logger::log "Using latest release asset: ${OUTLINE_SETUP_ARCHIVE_URL}"
else
  # specific tag
  logger::log "Using user-provided release tag: ${OUTLINE_SETUP_VERSION}"
  OUTLINE_SETUP_ARCHIVE_URL="https://github.com/${OUTLINE_SETUP_GITHUB_REPO}/releases/download/${OUTLINE_SETUP_VERSION}/${OUTLINE_SETUP_ARCHIVE_NAME}"
  logger::log "Release asset URL: ${OUTLINE_SETUP_ARCHIVE_URL}"
fi


###############################################################################
# DOWNLOAD & EXTRACT RELEASE (DIRECTLY INTO TMP)
###############################################################################
logger::log "Downloading and extracting to tmp dir: ${OUTLINE_SETUP_TMP_DIR}"
mkdir -p "${OUTLINE_SETUP_TMP_DIR}" || logger::err "Cannot create tmp dir"

curl -fsSL "${OUTLINE_SETUP_ARCHIVE_URL}" \
  | tar -xz -C "${OUTLINE_SETUP_TMP_DIR}" \
  || logger::err "Failed to download/extract archive"


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
  "${OUTLINE_SETUP_TMP_DIR}/" "./" \
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
