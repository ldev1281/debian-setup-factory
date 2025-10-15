# bitwarden module (both bw and bws)

@module logger.bash

# ---------------- Bitwarden helpers (namespace: bitwarden::) ----------------

# Basic listing
bitwarden::list_projects() {
    bws project list || return 1
}

bitwarden::project_id_by_name() {
    local name="${1:?usage: bitwarden::project_id_by_name <name>}"
    local id
    id="$(bitwarden::list_projects | jq -r --arg n "$name" '.[] | select(.name==$n) | .id' | head -n1)" || return 1
    [[ -z "$id" ]] && return 1
    printf '%s\n' "$id"
}

# Secret listing (optionally by project)
bitwarden::list_secrets() {
    local project_id="${1-}"
    if [[ -n "$project_id" ]]; then
        bws secret list "$project_id" || return 1
    else
        bws secret list || return 1
    fi
}

# Get secret VALUE by id
bitwarden::get_secret_by_id() {
    local secret_id="${1:?usage: bitwarden::get_secret_by_id <secret_id>}"
    bws secret get "$secret_id" | jq -r '.value' || return 1
}

# Get secret VALUE by KEY (optionally scoped to a project)
# Get secret VALUE by KEY (optionally scoped to a project)
bitwarden::get_secret() {
    local key="${1:?usage: bitwarden::get_secret <key> [project_id] [--first]}"
    local project_id="${2-}"
    local mode_first="${3-}"
    local stream ids count

    stream="$(bitwarden::list_secrets "$project_id")" || return 1
    ids="$(jq -r --arg k "$key" '.[] | select(.key==$k) | .id' <<<"$stream")" || return 1
    count=$(wc -w <<<"$ids" | awk '{print $1}')

    if [[ "$count" -eq 0 ]]; then
        logger::log "No secret found with key \"$key\""
        if [[ -t 0 || -t 1 ]]; then
            local value reply

            printf 'Type a value for key "%s" and press Enter (leave empty and press Enter to skip): ' "$key" >&2
            IFS= read -r -s value
            printf '\n' >&2

            if [[ -z "$value" ]]; then
                return 1
            fi

            printf 'Save this value to Bitwarden? [y/N]: ' >&2
            IFS= read -r reply
            if [[ "$reply" =~ ^[Yy]$ || "$reply" =~ ^[Yy][Ee][Ss]$ ]]; then
                if [[ -n "$project_id" ]]; then
                    bitwarden::create_secret "$project_id" "$key" "$value" \
                        || logger::log "Failed to create secret \"$key\" in project \"$project_id\""
                else
                    logger::log "Project ID was not provided to bitwarden::get_secret; skipping save."
                fi
            fi

            printf '%s\n' "$value"
            return 0
        fi

        return 1

    elif [[ "$count" -gt 1 && "$mode_first" != "--first" ]]; then
        logger::log "Multiple secrets with key \"$key\"; refine (pass project id) or use --first"
        return 1
    fi

    bitwarden::get_secret_by_id "$(awk '{print $1; exit}' <<<"$ids")"
}

# Create a secret (KEY, VALUE) in a project
bitwarden::create_secret() {
  local project_id="${1:?usage: bitwarden::create_secret <project_id> <key> <value> [note] }"
  local key="${2:?}"
  local value="${3:?}"
  local note="${4-}"
  if [[ -n "$note" ]]; then
    bws secret create "$key" "$value" "$project_id" --note "$note" >/dev/null || return 1
  else
    bws secret create "$key" "$value" "$project_id" >/dev/null || return 1
  fi
}

# Edit an existing secret by id (change value/key/note/project)
bitwarden::edit_secret() {
  local secret_id="${1:?usage: bitwarden::edit_secret <secret_id> [--key K] [--value V] [--note N] [--project-id PID]}"
  bws secret edit "$@" >/dev/null || return 1
}

# Upsert by KEY within a project: create if not found, else update value (and optionally note)
bitwarden::upsert_secret() {
  local project_id="${1:?usage: bitwarden::upsert_secret <project_id> <key> <value> [note] }"
  local key="${2:?}"
  local value="${3:?}"
  local note="${4-}"
  local sid
  sid="$(bitwarden::list_secrets "$project_id" | jq -r --arg k "$key" '.[] | select(.key==$k) | .id' | head -n1)" || return 1
  if [[ -n "$sid" ]]; then
    if [[ -n "$note" ]]; then
      bitwarden::edit_secret "$sid" --value "$value" --note "$note" || return 1
    else
      bitwarden::edit_secret "$sid" --value "$value" || return 1
    fi
  else
    bitwarden::create_secret "$project_id" "$key" "$value" "$note" || return 1
  fi
}

# ---------------- main ----------------

while :; do
    read -p "Type your machine access token BWS_ACCESS_TOKEN [${BWS_ACCESS_TOKEN:-}]: " input
    BWS_ACCESS_TOKEN=${input:-${BWS_ACCESS_TOKEN:-}}
    if [ -n "$BWS_ACCESS_TOKEN" ]; then
        export BWS_ACCESS_TOKEN
        break
    else
        echo "BWS_ACCESS_TOKEN can't be empty"
        continue
    fi
done

read -p "Type your project name BWS_PROJECT_NAME (optionally) [${BWS_PROJECT_NAME:-}]: " input
BWS_PROJECT_NAME=${input:-${BWS_PROJECT_NAME:-}}

BWS_PROJECT_ID=""
if [[ -n "$BWS_PROJECT_NAME" ]]; then
  if ! BWS_PROJECT_ID="$(bitwarden::project_id_by_name "$BWS_PROJECT_NAME")"; then
    logger::err "Project '$BWS_PROJECT_NAME' not found"
  fi
fi

export BWS_PROJECT_NAME BWS_PROJECT_ID
