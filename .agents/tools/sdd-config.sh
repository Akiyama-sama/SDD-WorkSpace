#!/usr/bin/env bash

set -euo pipefail

SDD_CONFIG_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SDD_ROOT_DIR="$(cd -- "$SDD_CONFIG_SCRIPT_DIR/../.." && pwd)"
SDD_CONFIG_FILE_DEFAULT="$SDD_ROOT_DIR/.agents/config.yaml"
SDD_LEGACY_BASE_BRANCH_FILE="$SDD_ROOT_DIR/.agents/base-branch.txt"
SDD_LEGACY_REPOS_FILE="$SDD_ROOT_DIR/.agents/repos.txt"

sdd_config_trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s\n' "$value"
}

sdd_config_strip_quotes() {
  local value
  value="$(sdd_config_trim "$1")"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  printf '%s\n' "$value"
}

sdd_config_write_default() {
  local config_file="${1:-$SDD_CONFIG_FILE_DEFAULT}"
  local base_branch="main"

  mkdir -p "$(dirname "$config_file")"

  if [ -f "$SDD_LEGACY_BASE_BRANCH_FILE" ]; then
    base_branch="$(tr -d '\r\n' < "$SDD_LEGACY_BASE_BRANCH_FILE")"
  fi

  {
    printf 'base_branch: %s\n' "$base_branch"
    printf 'repos:\n'

    if [ -f "$SDD_LEGACY_REPOS_FILE" ]; then
      while IFS= read -r repo; do
        repo="$(sdd_config_trim "$repo")"
        if [ -z "$repo" ] || [[ "$repo" == \#* ]]; then
          continue
        fi
        printf '  - %s\n' "$repo"
      done < "$SDD_LEGACY_REPOS_FILE"
    else
      printf '  # - git@github.com:your-org/your-repo.git\n'
    fi
  } > "$config_file"
}

sdd_config_ensure_file() {
  local config_file="${1:-$SDD_CONFIG_FILE_DEFAULT}"

  if [ ! -f "$config_file" ]; then
    sdd_config_write_default "$config_file"
  fi
}

sdd_config_get_base_branch() {
  local config_file="${1:-$SDD_CONFIG_FILE_DEFAULT}"
  local value

  sdd_config_ensure_file "$config_file"

  value="$(
    awk '
      /^base_branch:[[:space:]]*/ {
        sub(/^base_branch:[[:space:]]*/, "", $0)
        print
        exit
      }
    ' "$config_file"
  )"
  value="$(sdd_config_strip_quotes "$value")"

  if [ -z "$value" ]; then
    value="main"
  fi

  printf '%s\n' "$value"
}

sdd_config_set_base_branch() {
  local branch="$1"
  local config_file="${2:-$SDD_CONFIG_FILE_DEFAULT}"
  local tmp_file

  sdd_config_ensure_file "$config_file"

  tmp_file="$(mktemp)"
  awk -v branch="$branch" '
    BEGIN {
      replaced = 0
    }
    /^base_branch:[[:space:]]*/ {
      print "base_branch: " branch
      replaced = 1
      next
    }
    {
      print
    }
    END {
      if (!replaced) {
        print "base_branch: " branch
      }
    }
  ' "$config_file" > "$tmp_file"

  mv "$tmp_file" "$config_file"
}

sdd_config_list_repos() {
  local config_file="${1:-$SDD_CONFIG_FILE_DEFAULT}"

  sdd_config_ensure_file "$config_file"

  awk '
    BEGIN {
      in_repos = 0
    }
    /^repos:[[:space:]]*$/ {
      in_repos = 1
      next
    }
    in_repos && /^[[:space:]]*-[[:space:]]*/ {
      sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", $0)
      gsub(/^["'"'"']|["'"'"']$/, "", $0)
      if ($0 != "") {
        print $0
      }
      next
    }
    in_repos && /^[^[:space:]#-]/ {
      in_repos = 0
    }
  ' "$config_file"
}
