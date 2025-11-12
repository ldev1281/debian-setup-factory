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
PROXY_CLIENT_SETUP_GIT_BRANCH="${PROXY_CLIENT_SETUP_GIT_BRANCH:-main}"
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
    logger::log "Git repository already present, updating branch ${PROXY_CLIENT_SETUP_GIT_BRANCH}"

    git config remote.origin.tagOpt --no-tags || true
    git config --unset-all remote.origin.fetch 2>/dev/null || true
    git config --add remote.origin.fetch "+refs/heads/${PROXY_CLIENT_SETUP_GIT_BRANCH}:refs/remotes/origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Failed to set refspec for ${PROXY_CLIENT_SETUP_GIT_BRANCH}"

    git fetch --prune origin || logger::err "git fetch failed"
    git fetch origin "${PROXY_CLIENT_SETUP_GIT_BRANCH}:refs/remotes/origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Remote branch '${PROXY_CLIENT_SETUP_GIT_BRANCH}' not found on origin"

    git switch -C "${PROXY_CLIENT_SETUP_GIT_BRANCH}" "origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Failed to switch to ${PROXY_CLIENT_SETUP_GIT_BRANCH}"
    git branch --set-upstream-to="origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}" "${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Failed to set upstream to origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}"

    git pull --ff-only || logger::err "git pull failed"

else
    logger::log "Cloning ${PROXY_CLIENT_SETUP_REPO_URL} into ${PROXY_CLIENT_SETUP_TARGET_DIR}"

    git clone --single-branch --branch "${PROXY_CLIENT_SETUP_GIT_BRANCH}" "${PROXY_CLIENT_SETUP_REPO_URL}" . || logger::err "git clone failed"

    git config remote.origin.tagOpt --no-tags || true
    git config --unset-all remote.origin.fetch 2>/dev/null || true
    git config --add remote.origin.fetch "+refs/heads/${PROXY_CLIENT_SETUP_GIT_BRANCH}:refs/remotes/origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Failed to set refspec for ${PROXY_CLIENT_SETUP_GIT_BRANCH}"

    git fetch --prune origin || logger::err "git fetch failed"
    git branch --set-upstream-to="origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}" "${PROXY_CLIENT_SETUP_GIT_BRANCH}" || logger::err "Failed to set upstream to origin/${PROXY_CLIENT_SETUP_GIT_BRANCH}"
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
