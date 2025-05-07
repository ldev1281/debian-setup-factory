# logger module

# Set default log tag if not defined
LOG_TAG="${LOG_TAG:-setup-script}"

logger::log() {
  logger -t "$LOG_TAG" "$1"
  echo "[*] $1"
}

logger::err() {
  logger -t "$LOG_TAG" "[ERROR] $1"
  echo "[!] ERROR: $1" >&2
  exit 1
}
