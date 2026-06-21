#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.agents/config.yaml"
START_DOC="$ROOT_DIR/.agents/commands/sdd/start.md"
CLOSE_DOC="$ROOT_DIR/.agents/commands/sdd/close.md"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/sdd-config.sh"

prompt_base_branch() {
  local current_value="main"
  local input_value="${1:-}"

  current_value="$(sdd_config_get_base_branch "$CONFIG_FILE")"

  if [ -n "$input_value" ]; then
    printf '%s\n' "$input_value"
    return 0
  fi

  if [ -t 0 ]; then
    printf '请输入主干分支名 [%s]: ' "$current_value" >&2
    read -r input_value || true
    printf '%s\n' "${input_value:-$current_value}"
    return 0
  fi

  echo "[info] 未检测到交互输入，沿用主干分支：$current_value" >&2
  printf '%s\n' "$current_value"
}

validate_base_branch() {
  local branch="$1"

  if [ -z "$branch" ]; then
    echo "[error] 主干分支名不能为空" >&2
    exit 1
  fi

  case "$branch" in
    *[!A-Za-z0-9._/-]*)
      echo "[error] 主干分支名包含非法字符：$branch" >&2
      echo "[hint] 允许字母、数字、点、下划线、斜杠和中划线" >&2
      exit 1
      ;;
  esac
}

replace_line() {
  local file="$1"
  local from_text="$2"
  local to_text="$3"

  FROM_TEXT="$from_text" TO_TEXT="$to_text" perl -0pi -e '
    my $from = $ENV{FROM_TEXT};
    my $to = $ENV{TO_TEXT};

    if (index($_, $from) < 0) {
      die "expected text not found in $ARGV\n";
    }

    s/\Q$from\E/$to/g;
  ' "$file"
}

update_docs() {
  local current_branch_label="$1"
  local branch="$2"

  replace_line \
    "$START_DOC" \
    "检测当前分支是否为受保护主分支（当前模板配置：\`$current_branch_label\`）：" \
    "检测当前分支是否为受保护主分支（当前模板配置：\`$branch\`）："

  replace_line \
    "$CLOSE_DOC" \
    "- 任一仓库在受保护主分支（当前模板配置：\`$current_branch_label\`） → 强制中止，回退到 8.2 让用户重选“暂不提交”或先切换分支后重跑 close" \
    "- 任一仓库在受保护主分支（当前模板配置：\`$branch\`） → 强制中止，回退到 8.2 让用户重选“暂不提交”或先切换分支后重跑 close"
}

main() {
  local branch
  local current_branch_label

  branch="$(prompt_base_branch "${1:-}")"
  validate_base_branch "$branch"
  current_branch_label="$(sdd_config_get_base_branch "$CONFIG_FILE")"

  update_docs "$current_branch_label" "$branch"
  sdd_config_set_base_branch "$branch" "$CONFIG_FILE"

  echo "=== SDD_BASE_BRANCH_REPORT ==="
  echo "BASE_BRANCH=$branch"
  echo "CONFIG_FILE=.agents/config.yaml"
  echo "UPDATED_DOCS=.agents/commands/sdd/start.md .agents/commands/sdd/close.md"
  echo "=== END ==="
}

main "${1:-}"
