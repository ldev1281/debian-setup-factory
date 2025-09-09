# authentik setup module
set -Euo pipefail

@module logger.bash

logger::log "Setting up Authentik via docker-compose"

#
# Defaults (override via environment variables)
#
AUTHENTIK_SETUP_REPO_URL="${AUTHENTIK_SETUP_REPO_URL:-https://github.com/ldev1281/docker-compose-authentik.git}"
AUTHENTIK_SETUP_TARGET_PARENT_DIR="${AUTHENTIK_SETUP_TARGET_PARENT_DIR:-/docker}"
AUTHENTIK_SETUP_TARGET_DIR="${AUTHENTIK_SETUP_TARGET_DIR:-${AUTHENTIK_SETUP_TARGET_PARENT_DIR}/authentik}"
AUTHENTIK_SETUP_GIT_BRANCH="${AUTHENTIK_SETUP_GIT_BRANCH:-}"
AUTHENTIK_SETUP_INIT_PATH="${AUTHENTIK_SETUP_INIT_PATH:-./tools/init.bash}"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Dependencies
logger::log "Installing dependencies (git, ca-certificates, curl)"
apt update || logger::err "apt update failed"
apt install -y git ca-certificates curl || logger::err "Failed to install required packages"

# Prepare target directory
logger::log "Ensuring target directory exists: ${AUTHENTIK_SETUP_TARGET_DIR}"
mkdir -p "${AUTHENTIK_SETUP_TARGET_DIR}" || logger::err "Failed to create target directory"
cd "${AUTHENTIK_SETUP_TARGET_DIR}" || logger::err "Failed to enter target directory"

# Clone or update repository
if [ -d ".git" ]; then
    logger::log "Git repository already present, pulling latest changes"
    git fetch --all || logger::err "git fetch failed"
    if [ -n "${AUTHENTIK_SETUP_GIT_BRANCH}" ]; then
        git checkout "${AUTHENTIK_SETUP_GIT_BRANCH}" || logger::err "Failed to checkout branch ${AUTHENTIK_SETUP_GIT_BRANCH}"
        git pull --ff-only origin "${AUTHENTIK_SETUP_GIT_BRANCH}" || logger::err "git pull failed"
    else
        git pull --ff-only || logger::err "git pull failed"
    fi
else
    logger::log "Cloning ${AUTHENTIK_SETUP_REPO_URL} into ${AUTHENTIK_SETUP_TARGET_DIR}"
    if [ -n "${AUTHENTIK_SETUP_GIT_BRANCH}" ]; then
        git clone --depth 1 --branch "${AUTHENTIK_SETUP_GIT_BRANCH}" "${AUTHENTIK_SETUP_REPO_URL}" . || logger::err "git clone failed"
    else
        git clone --depth 1 "${AUTHENTIK_SETUP_REPO_URL}" . || logger::err "git clone failed"
    fi
fi

# Post-clone/init
if [ -x "${AUTHENTIK_SETUP_INIT_PATH}" ]; then
    logger::log "Running init script: ${AUTHENTIK_SETUP_INIT_PATH}"
    "${AUTHENTIK_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${AUTHENTIK_SETUP_INIT_PATH}" ]; then
    logger::log "Running init script via bash: ${AUTHENTIK_SETUP_INIT_PATH}"
    bash "${AUTHENTIK_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
    logger::err "Init script not found at ${AUTHENTIK_SETUP_INIT_PATH}"
fi

logger::log "Authentik setup complete"
