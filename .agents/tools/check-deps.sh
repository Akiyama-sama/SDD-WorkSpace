#!/usr/bin/env bash

set -euo pipefail

report_line() {
  printf '%s=%s\n' "$1" "$2"
}

check_command() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    "$name" --version 2>/dev/null | head -1
  else
    echo "MISSING"
  fi
}

ensure_openspec() {
  if command -v openspec >/dev/null 2>&1; then
    openspec --version 2>/dev/null | head -1
    return
  fi

  echo "[info] openspec 未安装，尝试通过 npm 安装..."
  if npm install -g @fission-ai/openspec@latest >/dev/null 2>&1; then
    openspec --version 2>/dev/null | head -1
  else
    echo "INSTALL_FAILED"
  fi
}

check_superpowers() {
  local root="${HOME}/.codex/plugins"
  if find "$root" -maxdepth 4 -name 'SKILL.md' 2>/dev/null | grep -q 'superpowers'; then
    echo "AVAILABLE"
  else
    echo "OPTIONAL_MISSING"
  fi
}

echo "=== SDD_ENV_REPORT ==="
report_line "NODE" "$(check_command node)"
report_line "NPM" "$(check_command npm)"
report_line "GIT" "$(check_command git)"
report_line "OPENSPEC" "$(ensure_openspec)"
report_line "SUPERPOWERS" "$(check_superpowers)"
echo "=== END ==="
