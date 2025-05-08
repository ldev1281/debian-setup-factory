#!/bin/bash
set -e

# Check that the recipe path is provided and the file exists
if [[ ! -f "$1" ]]; then
    echo "Usage: $0 path/to/recipe" >&2
    exit 1
fi

RECIPE_PATH="$1"

# Resolve absolute path to the directory containing this script
SCRIPT_DIR="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
MODULE_DIR="$SCRIPT_DIR/../setup-modules"

# Prevent recursive loops
declare -A INCLUDED_MODULES=()

# Function to embed a module with @module support
embed_module() {
    local module_name="$1"
    local module_path="$MODULE_DIR/$module_name"

    if [[ ! -f "$module_path" ]]; then
        echo "Module not found: $module_path" >&2
        exit 1
    fi

    # Prevent double-inclusion
    if [[ -n "${INCLUDED_MODULES[$module_path]}" ]]; then
        return
    fi
    INCLUDED_MODULES["$module_path"]=1

    echo "# ---- BEGIN: $module_name ----"

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^@module[[:space:]]+(.+)$ ]]; then
            submodule="${BASH_REMATCH[1]}"
            embed_module "$submodule"
        else
            echo "$line"
        fi
    done < "$module_path"

    echo "# ---- END: $module_name ----"
    echo
}

# Script header for the generated output
echo "#!/bin/bash"
echo "# Generated from $(basename "$RECIPE_PATH") on $(date)"
echo

# Read and process recipe line-by-line
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    if [[ "$line" =~ ^@module[[:space:]]+(.+)$ ]]; then
        embed_module "${BASH_REMATCH[1]}"
    else
        echo "$line"
    fi
done < "$RECIPE_PATH"
