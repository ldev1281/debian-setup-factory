# bitwarden-cli setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing Bitwarden CLI"

# Defaults
BW_VERSION="${BW_VERSION:-1.22.1}"
BW_INSTALL_DIR="${BW_INSTALL_DIR:-/usr/local/bin}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Install required dependencies
apt update && apt install -y curl unzip jq || logger::err "Failed to install required packages"

# Download and extract Bitwarden CLI
TMP_DIR="/tmp/bitwarden_bw_setup.$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || logger::err "Failed to enter temporary directory"

ARCHIVE_FILE="bw-linux-${BW_VERSION}.zip"
ARCHIVE_URL="https://github.com/bitwarden/cli/releases/download/v${BW_VERSION}/${ARCHIVE_FILE}"

logger::log "Downloading Bitwarden CLI from: ${ARCHIVE_URL}"
curl -fsSL -o "${ARCHIVE_FILE}" "${ARCHIVE_URL}" || logger::err "Failed to download Bitwarden CLI archive"

unzip -q "${ARCHIVE_FILE}" || logger::err "Failed to extract Bitwarden CLI archive"

# Install binary
install -m 755 bw "${BW_INSTALL_DIR}/bw" || logger::err "Failed to install Bitwarden CLI"

# Clean up
rm -rf "$TMP_DIR" || true

logger::log "Bitwarden CLI v${BW_VERSION} installation complete"
