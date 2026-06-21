#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="${1:-.}"
cd "$ROOT_DIR"

run_if_script_exists() {
  local label="$1"
  local script_name="$2"

  if [ ! -f package.json ]; then
    echo "[skip] $label: package.json not found"
    return 0
  fi

  if node -e "const p=require('./package.json'); process.exit(p.scripts && p.scripts['$script_name'] ? 0 : 1)" 2>/dev/null; then
    echo "[run] $label"
    npm run "$script_name" --silent
  else
    echo "[skip] $label: script \"$script_name\" not configured"
  fi
}

count_incomplete_tasks() {
  local task_file="$1"
  if [ ! -f "$task_file" ]; then
    echo 0
    return
  fi

  grep -Ec '^\s*- \[ \]' "$task_file" || true
}

echo "=== SDD_VERIFY ==="
run_if_script_exists "lint" "lint"
run_if_script_exists "typecheck" "typecheck"
run_if_script_exists "test" "test"

active_change="$(find openspec/changes -mindepth 1 -maxdepth 1 -type d ! -name archive | head -1 || true)"
if [ -n "$active_change" ] && [ -f "$active_change/tasks.md" ]; then
  pending="$(count_incomplete_tasks "$active_change/tasks.md")"
  echo "PENDING_TASKS=$pending"
else
  echo "PENDING_TASKS=UNKNOWN"
fi

echo "=== END ==="
