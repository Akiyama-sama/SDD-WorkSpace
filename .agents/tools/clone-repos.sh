#!/usr/bin/env bash

set -euo pipefail

REPO_LIST_FILE="${1:-.agents/repos.txt}"
TARGET_ROOT="${2:-$(pwd)/workspace-repos}"

if [ ! -f "$REPO_LIST_FILE" ]; then
  echo "[error] 仓库清单不存在：$REPO_LIST_FILE"
  echo "[hint] 新建该文件，每行一个 git 地址，例如："
  echo "       git@github.com:your-org/your-repo.git"
  exit 1
fi

mkdir -p "$TARGET_ROOT"

failed=""

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
  fi
done < "$REPO_LIST_FILE"

echo "=== CLONE_REPORT ==="
if [ -z "$failed" ]; then
  echo "STATUS=OK"
else
  echo "STATUS=PARTIAL"
  echo "FAILED=${failed# }"
fi
echo "=== END ==="
