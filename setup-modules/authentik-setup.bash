# authentik setup module
set -Euo pipefail

@module logger.bash

logger::log "Setting up Authentik via docker-compose"

#
# Defaults (override via environment variables)
#
MODULE_NAME="${MODULE_NAME:-authentik}"
REPO_URL="${REPO_URL:-https://github.com/ldev1281/docker-compose-authentik.git}"
TARGET_PARENT_DIR="${TARGET_PARENT_DIR:-/docker}"
TARGET_DIR="${TARGET_DIR:-${TARGET_PARENT_DIR}/authentik}"
GIT_BRANCH="${GIT_BRANCH:-}"
POST_CLONE_INIT_PATH="${POST_CLONE_INIT_PATH:-./tools/init.bash}"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Dependencies
logger::log "Installing dependencies (git, ca-certificates, curl)"
apt update || logger::err "apt update failed"
apt install -y git ca-certificates curl || logger::err "Failed to install required packages"

# Prepare target directory
logger::log "Ensuring target directory exists: ${TARGET_DIR}"
mkdir -p "${TARGET_DIR}" || logger::err "Failed to create target directory"
cd "${TARGET_DIR}" || logger::err "Failed to enter target directory"

# Clone or update repository
if [ -d ".git" ]; then
    logger::log "Git repository already present, pulling latest changes"
    git fetch --all || logger::err "git fetch failed"
    if [ -n "${GIT_BRANCH}" ]; then
        git checkout "${GIT_BRANCH}" || logger::err "Failed to checkout branch ${GIT_BRANCH}"
        git pull --ff-only origin "${GIT_BRANCH}" || logger::err "git pull failed"
    else
        git pull --ff-only || logger::err "git pull failed"
    fi
else
    logger::log "Cloning ${REPO_URL} into ${TARGET_DIR}"
    if [ -n "${GIT_BRANCH}" ]; then
        git clone --depth 1 --branch "${GIT_BRANCH}" "${REPO_URL}" . || logger::err "git clone failed"
    else
        git clone --depth 1 "${REPO_URL}" . || logger::err "git clone failed"
    fi
fi

# Post-clone/init
if [ -x "${POST_CLONE_INIT_PATH}" ]; then
    logger::log "Running init script: ${POST_CLONE_INIT_PATH}"
    "${POST_CLONE_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${POST_CLONE_INIT_PATH}" ]; then
    logger::log "Running init script via bash: ${POST_CLONE_INIT_PATH}"
    bash "${POST_CLONE_INIT_PATH}" || logger::err "Init script failed"
else
    logger::err "Init script not found at ${POST_CLONE_INIT_PATH}"
fi

logger::log "${MODULE_NAME} setup complete"
