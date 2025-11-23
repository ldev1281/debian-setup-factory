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

# Init script path (absolute, по умолчанию tools/init.bash в целевой директории)
FIREFLY_SETUP_INIT_PATH="${FIREFLY_SETUP_INIT_PATH:-${FIREFLY_SETUP_TARGET_DIR}/tools/init.bash}"

# Release version (empty → latest)
FIREFLY_SETUP_VERSION="${FIREFLY_SETUP_VERSION:-}"

# Tmp directory for archive extraction (content goes directly here)
FIREFLY_SETUP_TMP_DIR="${FIREFLY_SETUP_TMP_DIR:-$(mktemp -d)}"

# Release asset name (GitHub release file)
FIREFLY_SETUP_ARCHIVE_NAME="${FIREFLY_SETUP_ARCHIVE_NAME:-docker-compose-${FIREFLY_SETUP_APP_NAME}.tar.gz}"

# Backup root directory
FIREFLY_SETUP_BACKUP_ROOT="${FIREFLY_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
FIREFLY_SETUP_BACKUP_DIR="${FIREFLY_SETUP_BACKUP_DIR:-${FIREFLY_SETUP_BACKUP_ROOT}/${FIREFLY_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"


###############################################################################
# START
###############################################################################

logger::log "Setting up ${FIREFLY_SETUP_APP_NAME} via docker-compose (release mode)"
logger::log "Target directory: ${FIREFLY_SETUP_TARGET_DIR}"

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
logger::log "Ensuring target directory exists: ${FIREFLY_SETUP_TARGET_DIR}"
mkdir -p "${FIREFLY_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${FIREFLY_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE ASSET URL
###############################################################################
if [ -z "${FIREFLY_SETUP_VERSION}" ]; then
  # latest release
  FIREFLY_SETUP_ARCHIVE_URL="https://github.com/${FIREFLY_SETUP_GITHUB_REPO}/releases/latest/download/${FIREFLY_SETUP_ARCHIVE_NAME}"
  logger::log "Using latest release asset: ${FIREFLY_SETUP_ARCHIVE_URL}"
else
  # specific tag
  logger::log "Using user-provided release tag: ${FIREFLY_SETUP_VERSION}"
  FIREFLY_SETUP_ARCHIVE_URL="https://github.com/${FIREFLY_SETUP_GITHUB_REPO}/releases/download/${FIREFLY_SETUP_VERSION}/${FIREFLY_SETUP_ARCHIVE_NAME}"
  logger::log "Release asset URL: ${FIREFLY_SETUP_ARCHIVE_URL}"
fi


###############################################################################
# DOWNLOAD & EXTRACT RELEASE (DIRECTLY INTO TMP)
###############################################################################
logger::log "Downloading and extracting to tmp dir: ${FIREFLY_SETUP_TMP_DIR}"
mkdir -p "${FIREFLY_SETUP_TMP_DIR}" || logger::err "Cannot create tmp dir"

curl -fsSL "${FIREFLY_SETUP_ARCHIVE_URL}" \
  | tar -xz -C "${FIREFLY_SETUP_TMP_DIR}" \
  || logger::err "Failed to download/extract archive"


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
  "${FIREFLY_SETUP_TMP_DIR}/" "./" \
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
