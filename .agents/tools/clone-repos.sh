#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="${1:-$ROOT_DIR/config.toml}"
TARGET_ROOT="${2:-$ROOT_DIR/repos}"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/sdd-config.sh"

mkdir -p "$TARGET_ROOT"

failed=""
cloned_any=0
repo_list=""

repo_list="$(sdd_config_list_repos "$CONFIG_FILE")"

if [ -z "$repo_list" ]; then
  echo "=== CLONE_REPORT ==="
  echo "STATUS=SKIPPED"
  echo "REASON=NO_REPOS_CONFIGURED"
  echo "CONFIG_FILE=config.toml"
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
done <<< "$repo_list"

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
echo "CONFIG_FILE=config.toml"
echo "=== END ==="
