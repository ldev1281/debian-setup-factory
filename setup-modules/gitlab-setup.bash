# gitlab setup module
set -Euo pipefail

@module logger.bash

logger::log "Setting up GitLab via docker-compose"

#
# Defaults (override via environment variables)
#
GITLAB_SETUP_REPO_URL="${GITLAB_SETUP_REPO_URL:-https://github.com/ldev1281/docker-compose-gitlab.git}"
GITLAB_SETUP_TARGET_PARENT_DIR="${GITLAB_SETUP_TARGET_PARENT_DIR:-/docker}"
GITLAB_SETUP_TARGET_DIR="${GITLAB_SETUP_TARGET_DIR:-${GITLAB_SETUP_TARGET_PARENT_DIR}/gitlab}"
GITLAB_SETUP_GIT_BRANCH="${GITLAB_SETUP_GIT_BRANCH:-}"
GITLAB_SETUP_INIT_PATH="${GITLAB_SETUP_INIT_PATH:-./tools/init.bash}"

# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

# Dependencies
logger::log "Installing dependencies (git, ca-certificates, curl)"
apt update || logger::err "apt update failed"
apt install -y git ca-certificates curl || logger::err "Failed to install required packages"

# Prepare target directory
logger::log "Ensuring target directory exists: ${GITLAB_SETUP_TARGET_DIR}"
mkdir -p "${GITLAB_SETUP_TARGET_DIR}" || logger::err "Failed to create target directory"
cd "${GITLAB_SETUP_TARGET_DIR}" || logger::err "Failed to enter target directory"

# Clone or update repository
if [ -d ".git" ]; then
  logger::log "Git repository already present, pulling latest changes"
  git fetch --all || logger::err "git fetch failed"
  if [ -n "${GITLAB_SETUP_GIT_BRANCH}" ]; then
    git checkout "${GITLAB_SETUP_GIT_BRANCH}" || logger::err "Failed to checkout branch ${GITLAB_SETUP_GIT_BRANCH}"
    git pull --ff-only origin "${GITLAB_SETUP_GIT_BRANCH}" || logger::err "git pull failed"
  else
    git pull --ff-only || logger::err "git pull failed"
  fi
else
  logger::log "Cloning ${GITLAB_SETUP_REPO_URL} into ${GITLAB_SETUP_TARGET_DIR}"
  if [ -n "${GITLAB_SETUP_GIT_BRANCH}" ]; then
    git clone --depth 1 --branch "${GITLAB_SETUP_GIT_BRANCH}" "${GITLAB_SETUP_REPO_URL}" . || logger::err "git clone failed"
  else
    git clone --depth 1 "${GITLAB_SETUP_REPO_URL}" . || logger::err "git clone failed"
  fi
fi

# Post-clone/init
if [ -x "${GITLAB_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script: ${GITLAB_SETUP_INIT_PATH}"
  "${GITLAB_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${GITLAB_SETUP_INIT_PATH}" ]; then
  logger::log "Running init script via bash: ${GITLAB_SETUP_INIT_PATH}"
  bash "${GITLAB_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
  logger::err "Init script not found at ${GITLAB_SETUP_INIT_PATH}"
fi
