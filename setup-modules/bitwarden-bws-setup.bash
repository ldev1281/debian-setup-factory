# secrets-manager-cli setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing Bitwarden Secrets Manager CLI"

# Defaults
BWS_VERSION="${BWS_VERSION:-1.0.0}"
BWS_INSTALL_DIR="${BWS_INSTALL_DIR:-/usr/local/bin}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Install required dependencies
apt update && apt install -y curl unzip jq || logger::err "Failed to install required packages"

# Download and extract Bitwarden CLI
TMP_DIR="/tmp/bitwarden_bws_setup.$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || logger::err "Failed to enter temporary directory"

ARCHIVE_FILE="bws-x86_64-unknown-linux-gnu-${BWS_VERSION}.zip"
ARCHIVE_URL="https://github.com/bitwarden/sdk-sm/releases/download/bws-v${BWS_VERSION}/${ARCHIVE_FILE}"
logger::log "Downloading Bitwarden Secrets Manager CLI from: ${ARCHIVE_URL}"
curl -fsSL -o "${ARCHIVE_FILE}" "${ARCHIVE_URL}" || logger::err "Failed to download Bitwarden Secrets Manager CLI archive"

unzip -q "${ARCHIVE_FILE}" || logger::err "Failed to extract Bitwarden Secrets Manager CLI archive"

# Install binary
install -m 755 bws "${BWS_INSTALL_DIR}/bws" || logger::err "Failed to install Bitwarden Secrets Manager CLI"

# Clean up
rm -rf "$TMP_DIR" || true

logger::log "Bitwarden Secrets Manager CLI v${BWS_VERSION} installation complete"
