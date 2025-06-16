# Docker engine setup module
set -Euo pipefail

@module logger.bash

logger::log "Installing docker engine"

# check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# uninstall all conflicting packages
#
logger::log "uninstall all conflicting packages"

for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
    apt remove -y $pkg || true
done


#
# Install required dependencies
#
logger::log "Installing dependencies"

apt update || logger::err "apt update failed"
apt install -y lsb-release ca-certificates curl gnupg2 || logger::err "Failed to install required packages"

#
# Configuring apt & installing docker
# 
logger::log "Configuring apt and installing docker"

# GPG signature
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg |
    gpg --dearmor --yes --output /etc/apt/keyrings/docker-keyring.gpg || logger::err "Failed to download Docker GPG signature"

# apt sources list
{
    echo "deb [signed-by=/etc/apt/keyrings/docker-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs 2>/dev/null) stable"
    echo ""
} > /etc/apt/sources.list.d/docker.list

# installing docker
apt update || logger::err "apt update failed"
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || logger::err "Failed to install Docker packages"


#
# Autorun
#
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable docker || logger::err "Failed to enable docker service"
systemctl restart docker || logger::err "Failed to start docker service"


#
# Done!
#
logger::log "Docker installation complete"