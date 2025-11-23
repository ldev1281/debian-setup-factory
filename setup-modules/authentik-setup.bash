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

# Init script path (absolute, но по умолчанию tools/init.bash внутри TARGET)
AUTHENTIK_SETUP_INIT_PATH="${AUTHENTIK_SETUP_INIT_PATH:-${AUTHENTIK_SETUP_TARGET_DIR}/tools/init.bash}"

# Release version (empty → latest)
AUTHENTIK_SETUP_VERSION="${AUTHENTIK_SETUP_VERSION:-}"

# Tmp directory for archive extraction (content goes directly here)
AUTHENTIK_SETUP_TMP_DIR="${AUTHENTIK_SETUP_TMP_DIR:-$(mktemp -d)}"

# Release asset name (GitHub release file)
AUTHENTIK_SETUP_ARCHIVE_NAME="${AUTHENTIK_SETUP_ARCHIVE_NAME:-docker-compose-${AUTHENTIK_SETUP_APP_NAME}.tar.gz}"

# Backup root directory
AUTHENTIK_SETUP_BACKUP_ROOT="${AUTHENTIK_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
AUTHENTIK_SETUP_BACKUP_DIR="${AUTHENTIK_SETUP_BACKUP_DIR:-${AUTHENTIK_SETUP_BACKUP_ROOT}/${AUTHENTIK_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"


###############################################################################
# START
###############################################################################

logger::log "Setting up ${AUTHENTIK_SETUP_APP_NAME} via docker-compose (release mode)"
logger::log "Target directory: ${AUTHENTIK_SETUP_TARGET_DIR}"

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
logger::log "Ensuring target directory exists: ${AUTHENTIK_SETUP_TARGET_DIR}"
mkdir -p "${AUTHENTIK_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${AUTHENTIK_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE ASSET URL
###############################################################################
if [ -z "${AUTHENTIK_SETUP_VERSION}" ]; then
  # latest release
  AUTHENTIK_SETUP_ARCHIVE_URL="https://github.com/${AUTHENTIK_SETUP_GITHUB_REPO}/releases/latest/download/${AUTHENTIK_SETUP_ARCHIVE_NAME}"
  logger::log "Using latest release asset: ${AUTHENTIK_SETUP_ARCHIVE_URL}"
else
  # specific tag
  logger::log "Using user-provided release tag: ${AUTHENTIK_SETUP_VERSION}"
  AUTHENTIK_SETUP_ARCHIVE_URL="https://github.com/${AUTHENTIK_SETUP_GITHUB_REPO}/releases/download/${AUTHENTIK_SETUP_VERSION}/${AUTHENTIK_SETUP_ARCHIVE_NAME}"
  logger::log "Release asset URL: ${AUTHENTIK_SETUP_ARCHIVE_URL}"
fi


###############################################################################
# DOWNLOAD & EXTRACT RELEASE (DIRECTLY INTO TMP)
###############################################################################
logger::log "Downloading and extracting to tmp dir: ${AUTHENTIK_SETUP_TMP_DIR}"
mkdir -p "${AUTHENTIK_SETUP_TMP_DIR}" || logger::err "Cannot create tmp dir"

curl -fsSL "${AUTHENTIK_SETUP_ARCHIVE_URL}" \
  | tar -xz -C "${AUTHENTIK_SETUP_TMP_DIR}" \
  || logger::err "Failed to download/extract archive"


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
  "${AUTHENTIK_SETUP_TMP_DIR}/" "./" \
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
