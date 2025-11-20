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

# Release version (empty → latest)
GITLAB_SETUP_VERSION="${GITLAB_SETUP_VERSION:-}"

# Init script path
GITLAB_SETUP_INIT_PATH="${GITLAB_SETUP_INIT_PATH:-./tools/init.bash}"

# Tmp directory for archive extraction
GITLAB_SETUP_TMP_DIR="${GITLAB_SETUP_TMP_DIR:-$(mktemp -d)}"

# Archive filename inside tmp
GITLAB_SETUP_ARCHIVE_FILE="${GITLAB_SETUP_ARCHIVE_FILE:-${GITLAB_SETUP_TMP_DIR}/${GITLAB_SETUP_APP_NAME}-release.tar.gz}"

# Backup root directory
GITLAB_SETUP_BACKUP_ROOT="${GITLAB_SETUP_BACKUP_ROOT:-/var/lib/limbo-backup/artefacts/restore-archives}"

# Backup directory (per-run)
GITLAB_SETUP_BACKUP_DIR="${GITLAB_SETUP_BACKUP_DIR:-${GITLAB_SETUP_BACKUP_ROOT}/${GITLAB_SETUP_APP_NAME}_$(date +%Y%m%d_%H%M%S)}"

###############################################################################
# START
###############################################################################

logger::log "Setting up ${GITLAB_SETUP_APP_NAME} via docker-compose (release mode)"

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
logger::log "Ensuring target directory exists: ${GITLAB_SETUP_TARGET_DIR}"
mkdir -p "${GITLAB_SETUP_TARGET_DIR}" || logger::err "Cannot create target dir"
cd "${GITLAB_SETUP_TARGET_DIR}" || logger::err "Cannot enter target dir"


###############################################################################
# DETERMINE RELEASE VERSION
###############################################################################
if [ -z "${GITLAB_SETUP_VERSION}" ]; then
  GITLAB_SETUP_API_URL="https://api.github.com/repos/${GITLAB_SETUP_GITHUB_REPO}/releases/latest"
  logger::log "Determining latest release tag from ${GITLAB_SETUP_API_URL}"

  GITLAB_SETUP_VERSION="$(
    curl -fsSL "${GITLAB_SETUP_API_URL}" | jq -r '.tag_name' 2>/dev/null || echo ""
  )"

  [ -n "${GITLAB_SETUP_VERSION}" ] || logger::err "Failed to detect latest tag"
  logger::log "Latest release tag: ${GITLAB_SETUP_VERSION}"
else
  logger::log "Using user-provided release tag: ${GITLAB_SETUP_VERSION}"
fi

GITLAB_SETUP_ARCHIVE_URL="https://github.com/${GITLAB_SETUP_GITHUB_REPO}/archive/refs/tags/${GITLAB_SETUP_VERSION}.tar.gz"
logger::log "Archive URL: ${GITLAB_SETUP_ARCHIVE_URL}"


###############################################################################
# DOWNLOAD & EXTRACT RELEASE
###############################################################################
logger::log "Downloading: ${GITLAB_SETUP_ARCHIVE_URL}"
curl -fsSL "${GITLAB_SETUP_ARCHIVE_URL}" -o "${GITLAB_SETUP_ARCHIVE_FILE}" \
  || logger::err "Failed to download archive"

logger::log "Extracting archive into: ${GITLAB_SETUP_TMP_DIR}"
tar -xzf "${GITLAB_SETUP_ARCHIVE_FILE}" -C "${GITLAB_SETUP_TMP_DIR}" \
  || logger::err "Failed to extract archive"

GITLAB_SETUP_EXTRACTED_SUBDIR="$(find "${GITLAB_SETUP_TMP_DIR}" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[ -n "${GITLAB_SETUP_EXTRACTED_SUBDIR}" ] || logger::err "Extracted directory not found"

logger::log "Extracted directory: ${GITLAB_SETUP_EXTRACTED_SUBDIR}"


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
  "${GITLAB_SETUP_EXTRACTED_SUBDIR}/" "./" \
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