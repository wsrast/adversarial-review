#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/install.sh [--check] [--no-backup]

Installs adversarial-review skills and command wrappers.

Environment overrides:
  CODEX_HOME   default: $HOME/.codex
  CLAUDE_HOME  default: $HOME/.claude
  GEMINI_HOME  default: $HOME/.gemini
USAGE
}

check_only=0
backup=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      check_only=1
      ;;
    --no-backup)
      backup=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
claude_home="${CLAUDE_HOME:-$HOME/.claude}"
gemini_home="${GEMINI_HOME:-$HOME/.gemini}"
timestamp="$(date +%Y%m%d-%H%M%S)"

require_parent() {
  local dst="$1"
  local parent
  parent="$(dirname "$dst")"
  mkdir -p "$parent"
}

same_file() {
  local src="$1"
  local dst="$2"
  [[ -f "$dst" ]] && cmp -s "$src" "$dst"
}

backup_dst() {
  local dst="$1"
  [[ "$backup" -eq 1 && -f "$dst" ]] || return 0
  cp "$dst" "$dst.bak.$timestamp"
}

install_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -f "$src" ]]; then
    echo "Missing source: $src" >&2
    exit 1
  fi

  if [[ "$check_only" -eq 1 ]]; then
    if same_file "$src" "$dst"; then
      echo "OK $dst"
    else
      echo "DIFF $dst"
      if [[ -f "$dst" ]]; then
        diff -u "$dst" "$src" || true
      else
        echo "Destination missing: $dst"
      fi
    fi
    return 0
  fi

  require_parent "$dst"
  if same_file "$src" "$dst"; then
    echo "Unchanged $dst"
    return 0
  fi
  backup_dst "$dst"
  cp "$src" "$dst"
  echo "Installed $dst"
}

install_skill() {
  local agent="$1"
  local home_dir="$2"
  local skill_src="$repo_dir/skills/$agent/adversarial-review"
  local skill_dst="$home_dir/skills/adversarial-review"

  install_file "$skill_src/SKILL.md" "$skill_dst/SKILL.md"
  install_file "$repo_dir/skills/shared/PROTOCOL.md" "$skill_dst/references/PROTOCOL.md"
}

install_skill codex "$codex_home"
install_file "$repo_dir/skills/codex/adversarial-review/agents/openai.yaml" "$codex_home/skills/adversarial-review/agents/openai.yaml"
install_file "$repo_dir/commands/codex/adversary.md" "$codex_home/commands/adversary.md"
install_file "$repo_dir/commands/codex/contributor.md" "$codex_home/commands/contributor.md"

install_skill claude "$claude_home"
install_file "$repo_dir/commands/claude/adversary.md" "$claude_home/commands/adversary.md"
install_file "$repo_dir/commands/claude/contributor.md" "$claude_home/commands/contributor.md"

install_skill gemini "$gemini_home"
install_file "$repo_dir/commands/gemini/adversary.toml" "$gemini_home/commands/adversary.toml"
install_file "$repo_dir/commands/gemini/contributor.toml" "$gemini_home/commands/contributor.toml"

mkdir -p "$HOME/dev/ao/reviews"

if [[ "$check_only" -eq 1 ]]; then
  echo "Check complete."
else
  echo "Installed adversarial-review skills and commands."
fi
