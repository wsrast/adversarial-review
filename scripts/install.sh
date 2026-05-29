#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

install_file() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

install_file "$repo_dir/skills/codex/adversarial-review/SKILL.md" "$HOME/.codex/skills/adversarial-review/SKILL.md"
install_file "$repo_dir/skills/codex/adversarial-review/agents/openai.yaml" "$HOME/.codex/skills/adversarial-review/agents/openai.yaml"
install_file "$repo_dir/commands/codex/adversary.md" "$HOME/.codex/commands/adversary.md"
install_file "$repo_dir/commands/codex/contributor.md" "$HOME/.codex/commands/contributor.md"

install_file "$repo_dir/skills/claude/adversarial-review/SKILL.md" "$HOME/.claude/skills/adversarial-review/SKILL.md"
install_file "$repo_dir/commands/claude/adversary.md" "$HOME/.claude/commands/adversary.md"
install_file "$repo_dir/commands/claude/contributor.md" "$HOME/.claude/commands/contributor.md"

install_file "$repo_dir/skills/gemini/adversarial-review/SKILL.md" "$HOME/.gemini/skills/adversarial-review/SKILL.md"
install_file "$repo_dir/commands/gemini/adversary.toml" "$HOME/.gemini/commands/adversary.toml"
install_file "$repo_dir/commands/gemini/contributor.toml" "$HOME/.gemini/commands/contributor.toml"

mkdir -p "$HOME/dev/ao/reviews"

echo "Installed adversarial-review skills and commands."
