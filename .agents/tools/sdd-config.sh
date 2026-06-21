#!/usr/bin/env bash

set -euo pipefail

SDD_CONFIG_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SDD_ROOT_DIR="$(cd -- "$SDD_CONFIG_SCRIPT_DIR/../.." && pwd)"
SDD_CONFIG_FILE_DEFAULT="$SDD_ROOT_DIR/config.toml"

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

  mkdir -p "$(dirname "$config_file")"

  {
    printf 'base_branch = "main"\n'
    printf 'repos = [\n'
    printf '  # "git@github.com:your-org/your-repo.git",\n'
    printf ']\n'
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
      /^base_branch[[:space:]]*=/ {
        sub(/^base_branch[[:space:]]*=[[:space:]]*/, "", $0)
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
    /^base_branch[[:space:]]*=/ {
      print "base_branch = \"" branch "\""
      replaced = 1
      next
    }
    {
      print
    }
    END {
      if (!replaced) {
        print "base_branch = \"" branch "\""
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
    /^repos[[:space:]]*=[[:space:]]*\[/ {
      in_repos = 1
      line = $0
      sub(/^repos[[:space:]]*=[[:space:]]*\[/, "", line)
      if (line ~ /\]/) {
        sub(/\].*$/, "", line)
        gsub(/,/, "\n", line)
        print line
        in_repos = 0
      } else if (line !~ /^[[:space:]]*$/) {
        print line
      }
      next
    }
    in_repos {
      line = $0
      sub(/#.*/, "", line)
      if (line ~ /\]/) {
        sub(/\].*$/, "", line)
        in_repos = 0
      }
      gsub(/,/, "\n", line)
      print line
      next
    }
  ' "$config_file" | while IFS= read -r repo; do
    repo="$(sdd_config_strip_quotes "$repo")"
    repo="$(sdd_config_trim "$repo")"
    if [ -n "$repo" ]; then
      printf '%s\n' "$repo"
    fi
  done
}
