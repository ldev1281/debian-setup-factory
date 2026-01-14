# veracrypt setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing veracrypt"

#
# Defaults
#
VERACRYPT_SETUP_VERSION="${VERACRYPT_SETUP_VERSION:-1.26.20}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Configuring apt & installing veracrypt
#
logger::log "Downloading and installing veracrypt packages"

# Download and install deb package
TMP_DIR="/tmp/veracrypt_setup.$$"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || logger::err "Failed to enter temporary directory"

DEB_FILE="veracrypt-console-${VERACRYPT_SETUP_VERSION}-Debian-12-amd64.deb"
DEB_URL="https://launchpad.net/veracrypt/trunk/${VERACRYPT_SETUP_VERSION}/+download/${DEB_FILE}"

curl -fsSL -o "${TMP_DIR}/${DEB_FILE}" "$DEB_URL" || logger::err "Failed to download veracrypt package"

apt update || logger::err "apt update failed"
apt install -y "${TMP_DIR}/${DEB_FILE}" || logger::err "Failed to install veracrypt package"

#
# Done!
#
logger::log "veracrypt installation complete"
