# proxy client setup module
set -Euo pipefail

@module logger.bash

logger::log "Setting up proxy client via docker-compose"

#
# Defaults (override via environment variables)
#
PROXY_CLIENT_SETUP_REPO_URL="${PROXY_CLIENT_SETUP_REPO_URL:-https://github.com/ldev1281/docker-compose-proxy-client.git}"
PROXY_CLIENT_SETUP_TARGET_PARENT_DIR="${PROXY_CLIENT_SETUP_TARGET_PARENT_DIR:-/docker}"
PROXY_CLIENT_SETUP_TARGET_DIR="${PROXY_CLIENT_SETUP_TARGET_DIR:-${PROXY_CLIENT_SETUP_TARGET_PARENT_DIR}/proxy-client}"
PROXY_CLIENT_SETUP_GIT_BRANCH="${PROXY_CLIENT_SETUP_GIT_BRANCH:-}"
PROXY_CLIENT_SETUP_INIT_PATH="${PROXY_CLIENT_SETUP_INIT_PATH:-./tools/init.bash}"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Dependencies
logger::log "Installing dependencies (git, ca-certificates, curl)"
apt update || logger::err "apt update failed"
apt install -y git ca-certificates curl || logger::err "Failed to install required packages"

# Prepare target directory
logger::log "Ensuring target directory exists: ${PROXY_CLIENT_SETUP_TARGET_DIR}"
mkdir -p "${PROXY_CLIENT_SETUP_TARGET_DIR}" || logger::err "Failed to create target directory"
cd "${PROXY_CLIENT_SETUP_TARGET_DIR}" || logger::err "Failed to enter target directory"

# Clone or update repository
if [ -d ".git" ]; then
    logger::log "Git repository already present, pulling latest changes"
    git fetch --all || logger::err "git fetch failed"
    if [ -n "${PROXY_CLIENT_SETUP_GIT_BRANCH}" ]; then
        git checkout "${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Failed to checkout branch ${PROXY_CLIENT_SETUP_GIT_BRANCH}"
        git pull --ff-only origin "${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "git pull failed"
    else
        git pull --ff-only || logger::err "git pull failed"
    fi
else
    logger::log "Cloning ${PROXY_CLIENT_SETUP_REPO_URL} into ${PROXY_CLIENT_SETUP_TARGET_DIR}"
    if [ -n "${PROXY_CLIENT_SETUP_GIT_BRANCH}" ]; then
        git clone --depth 1 --branch "${PROXY_CLIENT_SETUP_GIT_BRANCH}" "${PROXY_CLIENT_SETUP_REPO_URL}" . || logger::err "git clone failed"
    else
        git clone --depth 1 "${PROXY_CLIENT_SETUP_REPO_URL}" . || logger::err "git clone failed"
    fi
fi

# Post-clone/init
if [ -x "${PROXY_CLIENT_SETUP_INIT_PATH}" ]; then
    logger::log "Running init script: ${PROXY_CLIENT_SETUP_INIT_PATH}"
    "${PROXY_CLIENT_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${PROXY_CLIENT_SETUP_INIT_PATH}" ]; then
    logger::log "Running init script via bash: ${PROXY_CLIENT_SETUP_INIT_PATH}"
    bash "${PROXY_CLIENT_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
    logger::err "Init script not found at ${PROXY_CLIENT_SETUP_INIT_PATH}"
fi

logger::log "proxy-client setup complete"
