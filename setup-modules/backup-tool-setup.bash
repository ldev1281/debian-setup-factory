# backup-tool setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing backup-tool"

#
# Defaults
#
BACKUP_TOOL_VERSION="${BACKUP_TOOL_VERSION:-0.6}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Download & install .deb
#
logger::log "Downloading and installing backup-tool packages"

TMP_DIR="/tmp/backup_tool_setup.$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || logger::err "Failed to enter temporary directory"

DEB_FILE="limbo-backup_v${BACKUP_TOOL_VERSION}_all.deb"
DEB_URL="https://github.com/ldev1281/backup-tool/releases/download/v${BACKUP_TOOL_VERSION}/${DEB_FILE}"

curl -fsSL -o "${TMP_DIR}/${DEB_FILE}" "${DEB_URL}" || logger::err "Failed to download backup-tool package"

apt update || logger::err "apt update failed"
apt install -y "${TMP_DIR}/${DEB_FILE}" || logger::err "Failed to install backup-tool"

#
# Done!
#
logger::log "backup-tool installation complete"
