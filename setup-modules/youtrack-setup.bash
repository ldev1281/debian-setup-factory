# youtrack setup module
set -Euo pipefail

@module logger.bash

logger::log "Setting up YouTrack via docker-compose"

#
# Defaults (override via environment variables)
#
YOUTRACK_SETUP_REPO_URL="${YOUTRACK_SETUP_REPO_URL:-https://github.com/ldev1281/docker-compose-youtrack.git}"
YOUTRACK_SETUP_TARGET_PARENT_DIR="${YOUTRACK_SETUP_TARGET_PARENT_DIR:-/docker}"
YOUTRACK_SETUP_TARGET_DIR="${YOUTRACK_SETUP_TARGET_DIR:-${YOUTRACK_SETUP_TARGET_PARENT_DIR}/youtrack}"
YOUTRACK_SETUP_GIT_BRANCH="${YOUTRACK_SETUP_GIT_BRANCH:-}"
YOUTRACK_SETUP_INIT_PATH="${YOUTRACK_SETUP_INIT_PATH:-./tools/init.bash}"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Dependencies
logger::log "Installing dependencies (git, ca-certificates, curl)"
apt update || logger::err "apt update failed"
apt install -y git ca-certificates curl || logger::err "Failed to install required packages"

# Prepare target directory
logger::log "Ensuring target directory exists: ${YOUTRACK_SETUP_TARGET_DIR}"
mkdir -p "${YOUTRACK_SETUP_TARGET_DIR}" || logger::err "Failed to create target directory"
cd "${YOUTRACK_SETUP_TARGET_DIR}" || logger::err "Failed to enter target directory"

# Clone or update repository
if [ -d ".git" ]; then
  logger::log "Git repository already present, pulling latest changes"
  git fetch --all || logger::err "git fetch failed"
  if [ -n "${YOUTRACK_SETUP_GIT_BRANCH}" ]; then
    git checkout "${YOUTRACK_SETUP_GIT_BRANCH}" || logger::err "Failed to checkout branch ${YOUTRACK_SETUP_GIT_BRANCH}"
    git pull --ff-only origin "${YOUTRACK_SETUP_GIT_BRANCH}" || logger::err "git pull failed"
  else
    git pull --ff-only || logger::err "git pull failed"
  fi
else
  logger::log "Cloning ${YOUTRACK_SETUP_REPO_URL} into ${YOUTRACK_SETUP_TARGET_DIR}"
  if [ -n "${YOUTRACK_SETUP_GIT_BRANCH}" ]; then
    git clone --depth 1 --branch "${YOUTRACK_SETUP_GIT_BRANCH}" "${YOUTRACK_SETUP_REPO_URL}" . || logger::err "git clone failed"
  else
    git clone --depth 1 "${YOUTRACK_SETUP_REPO_URL}" . || logger::err "git clone failed"
  fi
fi

# Post-clone/init
if [ -x "${YOUTRACK_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script: ${YOUTRACK_SETUP_INIT_PATH}"
  "${YOUTRACK_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${YOUTRACK_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script via bash: ${YOUTRACK_SETUP_INIT_PATH}"
  bash "${YOUTRACK_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found at ${YOUTRACK_SETUP_INIT_PATH}"
fi
