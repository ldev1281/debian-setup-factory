@module logger.bash

logger::log "About to simulate a failure..."
logger::err "Intentional failure from failing.bash"
echo "This line should not be executed."
