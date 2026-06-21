#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="${1:-$ROOT_DIR/.agents/config.yaml}"
TARGET_ROOT="${2:-$ROOT_DIR/workspace-repos}"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/sdd-config.sh"

mkdir -p "$TARGET_ROOT"

failed=""
cloned_any=0

if ! sdd_config_list_repos "$CONFIG_FILE" | grep -q .; then
  echo "=== CLONE_REPORT ==="
  echo "STATUS=SKIPPED"
  echo "REASON=NO_REPOS_CONFIGURED"
  echo "CONFIG_FILE=.agents/config.yaml"
  echo "=== END ==="
  exit 0
fi

while IFS= read -r repo; do
  repo="${repo#"${repo%%[![:space:]]*}"}"
  repo="${repo%"${repo##*[![:space:]]}"}"

  if [ -z "$repo" ] || [[ "$repo" == \#* ]]; then
    continue
  fi

  name="$(basename "$repo" .git)"
  dest="$TARGET_ROOT/$name"

  if [ -d "$dest/.git" ]; then
    echo "[skip] $name already exists"
    continue
  fi

  echo "[clone] $repo"
  if ! git clone "$repo" "$dest"; then
    failed="$failed $name"
  else
    cloned_any=1
  fi
done < <(sdd_config_list_repos "$CONFIG_FILE")

echo "=== CLONE_REPORT ==="
if [ -z "$failed" ]; then
  if [ "$cloned_any" -eq 1 ]; then
    echo "STATUS=OK"
  else
    echo "STATUS=SKIPPED"
    echo "REASON=ALL_REPOS_ALREADY_PRESENT"
  fi
else
  echo "STATUS=PARTIAL"
  echo "FAILED=${failed# }"
fi
echo "CONFIG_FILE=.agents/config.yaml"
echo "=== END ==="
