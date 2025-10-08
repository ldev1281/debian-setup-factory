# firefly setup module
set -Euo pipefail


@module logger.bash


logger::log "Setting up Firefly via docker-compose"


#
# Defaults (override via environment variables)
#
FIREFLY_SETUP_REPO_URL="${FIREFLY_SETUP_REPO_URL:-https://github.com/ldev1281/docker-compose-firefly.git}"
FIREFLY_SETUP_TARGET_PARENT_DIR="${FIREFLY_SETUP_TARGET_PARENT_DIR:-/docker}"
FIREFLY_SETUP_TARGET_DIR="${FIREFLY_SETUP_TARGET_DIR:-${FIREFLY_SETUP_TARGET_PARENT_DIR}/firefly}"
FIREFLY_SETUP_GIT_BRANCH="${FIREFLY_SETUP_GIT_BRANCH:-}"
FIREFLY_SETUP_INIT_PATH="${FIREFLY_SETUP_INIT_PATH:-./tools/init.bash}"


# Require root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"


# Dependencies
logger::log "Installing dependencies (git, ca-certificates, curl)"
apt update || logger::err "apt update failed"
apt install -y git ca-certificates curl || logger::err "Failed to install required packages"


# Prepare target directory
logger::log "Ensuring target directory exists: ${FIREFLY_SETUP_TARGET_DIR}"
mkdir -p "${FIREFLY_SETUP_TARGET_DIR}" || logger::err "Failed to create target directory"
cd "${FIREFLY_SETUP_TARGET_DIR}" || logger::err "Failed to enter target directory"


# Clone or update repository
if [ -d ".git" ]; then
logger::log "Git repository already present, pulling latest changes"
git fetch --all || logger::err "git fetch failed"
if [ -n "${FIREFLY_SETUP_GIT_BRANCH}" ]; then
git checkout "${FIREFLY_SETUP_GIT_BRANCH}" || logger::err "Failed to checkout branch ${FIREFLY_SETUP_GIT_BRANCH}"
git pull --ff-only origin "${FIREFLY_SETUP_GIT_BRANCH}" || logger::err "git pull failed"
else
git pull --ff-only || logger::err "git pull failed"
fi
else
logger::log "Cloning ${FIREFLY_SETUP_REPO_URL} into ${FIREFLY_SETUP_TARGET_DIR}"
if [ -n "${FIREFLY_SETUP_GIT_BRANCH}" ]; then
git clone --depth 1 --branch "${FIREFLY_SETUP_GIT_BRANCH}" "${FIREFLY_SETUP_REPO_URL}" . || logger::err "git clone failed"
else
git clone --depth 1 "${FIREFLY_SETUP_REPO_URL}" . || logger::err "git clone failed"
fi
fi


# Post-clone/init
if [ -x "${FIREFLY_SETUP_INIT_PATH}" ]; then
logger::log "Running init script: ${FIREFLY_SETUP_INIT_PATH}"
"${FIREFLY_SETUP_INIT_PATH}" || logger::err "Init script failed"
elif [ -f "${FIREFLY_SETUP_INIT_PATH}" ]; then
logger::log "Running init script via bash: ${FIREFLY_SETUP_INIT_PATH}"
bash "${FIREFLY_SETUP_INIT_PATH}" || logger::err "Init script failed"
else
logger::err "Init script not found at ${FIREFLY_SETUP_INIT_PATH}"
fi


logger::log "Firefly setup complete"