# gitlab setup module
set -Euo pipefail

@module logger.bash

###############################################################################
# CONFIGURATION (ALL VARIABLES MUST BE HERE)
###############################################################################

# Application Identity
GITLAB_SETUP_APP_NAME="${GITLAB_SETUP_APP_NAME:-gitlab}"

# GitHub Repository (owner/repo)
GITLAB_SETUP_GITHUB_REPO="${GITLAB_SETUP_GITHUB_REPO:-ldev1281/docker-compose-gitlab}"

# Install target directories
GITLAB_SETUP_TARGET_PARENT_DIR="${GITLAB_SETUP_TARGET_PARENT_DIR:-/docker}"
GITLAB_SETUP_TARGET_DIR="${GITLAB_SETUP_TARGET_DIR:-${GITLAB_SETUP_TARGET_PARENT_DIR}/${GITLAB_SETUP_APP_NAME}}"

# Init script path (absolute, по умолчанию tools/init.bash в целевой директории)
GITLAB_SETUP_INIT_PATH="${GITLAB_SETUP_INIT_PATH:-${GITLAB_SETUP_TARGET_DIR}/tools/init.bash}"

# Release version (empty → latest)
GITLAB_SETUP_VERSION="${GITLAB_SETUP_VERSION:-}"

# Tmp directory for archive extraction (content goes directly here)
GITLAB_SETUP_TMP_DIR="${GITLAB_SETUP_TMP_DIR:-$(mktemp -d)}"

# Release asset name (GitHub release file)
GITLAB_SETUP_ARCHIVE_NAME="${GITLAB_SETUP_ARCHIVE_NAME:-docker-compose-${GITLAB_SETUP_APP_NAME}.tar.gz}"

# Backup root directory
GITLAB_SETUP_BACKUP_ROOT="${GITLAB_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
GITLAB_SETUP_BACKUP_DIR="${GITLAB_SETUP_BACKUP_DIR:-${GITLAB_SETUP_BACKUP_ROOT}/${GITLAB_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"


###############################################################################
# START
###############################################################################

logger::log "Setting up ${GITLAB_SETUP_APP_NAME} via docker-compose (release mode)"
logger::log "Target directory: ${GITLAB_SETUP_TARGET_DIR}"

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
logger::log "Ensuring target directory exists: ${GITLAB_SETUP_TARGET_DIR}"
mkdir -p "${GITLAB_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${GITLAB_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE ASSET URL
###############################################################################
if [ -z "${GITLAB_SETUP_VERSION}" ]; then
  # latest release
  GITLAB_SETUP_ARCHIVE_URL="https://github.com/${GITLAB_SETUP_GITHUB_REPO}/releases/latest/download/${GITLAB_SETUP_ARCHIVE_NAME}"
  logger::log "Using latest release asset: ${GITLAB_SETUP_ARCHIVE_URL}"
else
  # specific tag
  logger::log "Using user-provided release tag: ${GITLAB_SETUP_VERSION}"
  GITLAB_SETUP_ARCHIVE_URL="https://github.com/${GITLAB_SETUP_GITHUB_REPO}/releases/download/${GITLAB_SETUP_VERSION}/${GITLAB_SETUP_ARCHIVE_NAME}"
  logger::log "Release asset URL: ${GITLAB_SETUP_ARCHIVE_URL}"
fi


###############################################################################
# DOWNLOAD & EXTRACT RELEASE (DIRECTLY INTO TMP)
###############################################################################
logger::log "Downloading and extracting to tmp dir: ${GITLAB_SETUP_TMP_DIR}"
mkdir -p "${GITLAB_SETUP_TMP_DIR}" || logger::err "Cannot create tmp dir"

curl -fsSL "${GITLAB_SETUP_ARCHIVE_URL}" \
  | tar -xz -C "${GITLAB_SETUP_TMP_DIR}" \
  || logger::err "Failed to download/extract archive"


###############################################################################
# BACKUP REMOVED/OVERWRITTEN FILES
###############################################################################
logger::log "Preparing backup directory: ${GITLAB_SETUP_BACKUP_DIR}"
mkdir -p "${GITLAB_SETUP_BACKUP_DIR}" \
  || logger::err "Failed to create backup directory"


###############################################################################
# SYNC WITH RSYNC (PRESERVE .env & vol)
###############################################################################
logger::log "Syncing release → ${GITLAB_SETUP_TARGET_DIR}"
logger::log "Backup of removed/overwritten files → ${GITLAB_SETUP_BACKUP_DIR}"

rsync -a \
  --delete \
  --backup \
  --backup-dir="${GITLAB_SETUP_BACKUP_DIR}" \
  --suffix=".bak" \
  --exclude '.env' \
  --exclude 'vol' \
  "${GITLAB_SETUP_TMP_DIR}/" "${GITLAB_SETUP_TARGET_DIR}/" \
  || logger::err "Failed to sync release files"


###############################################################################
# INIT SCRIPT
###############################################################################
if [ -x "${GITLAB_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (exec): ${GITLAB_SETUP_INIT_PATH}"
  "${GITLAB_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${GITLAB_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script (bash): ${GITLAB_SETUP_INIT_PATH}"
  bash "${GITLAB_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found: ${GITLAB_SETUP_INIT_PATH}"
fi
