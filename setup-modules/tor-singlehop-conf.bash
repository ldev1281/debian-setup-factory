# tor hidden service (Single Hop) setup module
set -Euo pipefail

@module logger.bash
@module bitwarden.bash

logger::log "Configuring tor hidden service (Single Hop)"

#
# Defaults
#
TOR_SINGLEHOP_CONF_HS_NAME="${TOR_SINGLEHOP_CONF_HS_NAME:=singlehop}"
_TOR_SINGLEHOP_CONF_HS_DIR="/var/lib/tor-instances/${TOR_SINGLEHOP_CONF_HS_NAME}"
TOR_SINGLEHOP_CONF_HS_FRP_HOST="${TOR_SINGLEHOP_CONF_HS_FRP_HOST:=127.0.0.1}"
TOR_SINGLEHOP_CONF_HS_FRP_PORT="${TOR_SINGLEHOP_CONF_HS_FRP_PORT:=7000}"
TOR_SINGLEHOP_CONF_HS_FRP_LISTEN="${TOR_SINGLEHOP_CONF_HS_FRP_LISTEN:=7000}"
TOR_SINGLEHOP_CONF_HS_DANTE_HOST="${TOR_SINGLEHOP_CONF_HS_DANTE_HOST:=127.0.0.1}"
TOR_SINGLEHOP_CONF_HS_DANTE_PORT="${TOR_SINGLEHOP_CONF_HS_DANTE_PORT:=1080}"
TOR_SINGLEHOP_CONF_HS_DANTE_LISTEN="${TOR_SINGLEHOP_CONF_HS_DANTE_LISTEN:=1080}"

# Check for root
[ "${EUID:-$(id -u)}" -eq 0 ] || logger::err "Script must be run with root privileges"

#
# Hidden service (Single Hop) tor configuration for Dante and FRP
#
logger::log "Hidden service (Single Hop) tor configuration"

#
# Creating new tor instance with a separate config, working directory and user
#
tor-instance-create ${TOR_SINGLEHOP_CONF_HS_NAME} || "failed to setup tor@${TOR_SINGLEHOP_CONF_HS_NAME}"

# Directory with separate configuration files
install -m 0755 -d /etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc.d/

# AppArmor rule to allow this directory and its files
echo "/etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc.d/ r," >/etc/apparmor.d/local/system_tor
echo "/etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc.d/* r," >>/etc/apparmor.d/local/system_tor
apparmor_parser -r /etc/apparmor.d/system_tor

# Enable hidden service in single hop mode and include configs with %include option
{
    echo "# Tor configuration (Single Hop) for Dante and FRP"
    echo ""
    echo "# Disable client mode"
    echo "SocksPort 0"
    echo ""
    echo "# Hidden Service configuration"
    echo "HiddenServiceDir ${_TOR_SINGLEHOP_CONF_HS_DIR}"
    echo "HiddenServiceSingleHopMode 1"
    echo "HiddenServiceNonAnonymousMode 1"
    echo ""
    echo "# Include separate configs if any"
    echo "%include /etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc.d/"
    echo ""
} >/etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc

#
# FRP ports forwarding
#
{
    echo "# FRP server"
    echo "HiddenServicePort ${TOR_SINGLEHOP_CONF_HS_FRP_LISTEN} ${TOR_SINGLEHOP_CONF_HS_FRP_HOST}:${TOR_SINGLEHOP_CONF_HS_FRP_PORT}"
    echo ""

} >/etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc.d/10-frp.conf

#
# Dante ports forwarding
#
{
    echo "# Dante socks5 server"
    echo "HiddenServicePort ${TOR_SINGLEHOP_CONF_HS_DANTE_LISTEN} ${TOR_SINGLEHOP_CONF_HS_DANTE_HOST}:${TOR_SINGLEHOP_CONF_HS_DANTE_PORT}"
    echo ""
} >/etc/tor/instances/${TOR_SINGLEHOP_CONF_HS_NAME}/torrc.d/20-dante.conf

# Enable and start the services
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable tor@${TOR_SINGLEHOP_CONF_HS_NAME} || logger::err "Failed to enable tor@${TOR_SINGLEHOP_CONF_HS_NAME} service"
systemctl restart tor@${TOR_SINGLEHOP_CONF_HS_NAME} || logger::err "Failed to start tor@${TOR_SINGLEHOP_CONF_HS_NAME} service"

#
# testing hidden service setup. first check for hostname file, then try to connect
#
logger::log "Testing hidden service setup"
_TOR_SINGLEHOP_CONF_HS_TEST_ATTEMPTS=0
_TOR_SINGLEHOP_CONF_HS_TEST_RESTARTS=0

while ! test -f "$_TOR_SINGLEHOP_CONF_HS_DIR/hostname"; do

    ((_TOR_SINGLEHOP_CONF_HS_TEST_ATTEMPTS++))
    logger::log "still waiting hidden service (Single Hop) up..."

    if ((_TOR_SINGLEHOP_CONF_HS_TEST_ATTEMPTS % 6 == 0)); then
        ((_TOR_SINGLEHOP_CONF_HS_TEST_RESTARTS++))
        if ((_TOR_SINGLEHOP_CONF_HS_TEST_RESTARTS <= 1)); then
            logger::log "restarting tor@${TOR_SINGLEHOP_CONF_HS_NAME}..."
            systemctl restart tor@${TOR_SINGLEHOP_CONF_HS_NAME} || logger::err "Failed to start tor@${TOR_SINGLEHOP_CONF_HS_NAME} service"
        else
            logger::err "failed to setup tor@${TOR_SINGLEHOP_CONF_HS_NAME}"
        fi
    fi

    sleep 5
done

TOR_SINGLEHOP_CONF_HS_HOSTNAME="$(cat ${_TOR_SINGLEHOP_CONF_HS_DIR}/hostname)"

#
# Done!
#
logger::log "tor hidden service (Single Hop) up! installation complete"
