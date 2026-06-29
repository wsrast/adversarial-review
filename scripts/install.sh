#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/install.sh [--check] [--no-backup] [--cleanup]

Installs adversarial-review skills and command wrappers.

Options:
  --cleanup         Clean up and deprecate legacy Gemini configuration files (TOML and skill folders).

Environment overrides:
  CODEX_HOME        default: $HOME/.codex
  CLAUDE_HOME       default: $HOME/.claude
  COPILOT_HOME      default: $HOME/.copilot (GitHub Copilot CLI personal skills)
  ANTIGRAVITY_HOME  default: $HOME/.gemini/config (coupled under .gemini for agy CLI auto-discovery)
  GEMINI_HOME       default: $HOME/.gemini (used for legacy cleanup)
USAGE
}

check_only=0
backup=1
run_cleanup=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      check_only=1
      ;;
    --no-backup)
      backup=0
      ;;
    --cleanup)
      run_cleanup=1
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
# shellcheck source=/dev/null
source "$repo_dir/adversaries.manifest"
timestamp="$(date +%Y%m%d-%H%M%S)"
check_failed=0

# Resolve the Antigravity plugin dir from the manifest (the sole plugin-kind
# agent). plugin_dir is used by backup routing and the cleanup safety checks.
# ANTIGRAVITY_HOME default (~/.gemini/config) is nested under ~/.gemini for agy
# CLI auto-discovery; that default lives in adversaries.manifest.
antigravity_home="$HOME/.gemini/config"
for i in "${!adv_slug[@]}"; do
  [[ "${adv_kind[$i]}" == "plugin" ]] && antigravity_home="$(adv_home_resolved "$i")"
done
plugin_dir="$antigravity_home/plugins/adversarial-review-plugin"

canonicalize() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  elif [[ -f "$path" ]]; then
    local dir
    dir="$(dirname "$path")"
    local base
    base="$(basename "$path")"
    if [[ -d "$dir" ]]; then
      echo "$(cd "$dir" && pwd -P)/$base"
    else
      echo "$path"
    fi
  else
    echo "$path"
  fi
}

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

is_under_plugin_dir() {
  local path="$1"
  local c_plugin_dir
  local c_path
  c_plugin_dir="$(canonicalize "$plugin_dir")"
  c_path="$(canonicalize "$path")"

  # Check if c_path is inside or equal to c_plugin_dir
  local check_plugin="${c_plugin_dir}/"
  local check_path="${c_path}/"

  if [[ "$check_path" == "$check_plugin"* ]]; then
    return 0
  fi
  return 1
}

backup_dst() {
  local dst="$1"
  [[ "$backup" -eq 1 && -f "$dst" ]] || return 0

  local dst_bak_path
  if is_under_plugin_dir "$dst"; then
    # Route backups of plugin-internal paths outside the plugin scan directory
    local backups_dir="$antigravity_home/plugin-backups"
    mkdir -p "$backups_dir"
    local relative_path="${dst#"$plugin_dir"/}"
    local flat_name="${relative_path//\//_}"
    dst_bak_path="$backups_dir/${flat_name}.bak.$timestamp"
  else
    dst_bak_path="$dst.bak.$timestamp"
  fi
  cp "$dst" "$dst_bak_path"
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
      check_failed=1
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

# install_plugin <slug> <home>: install a plugin-kind agent. Loops the plugin's
# skills directory (skills/<slug>/skills/*) instead of a hardcoded file list, so
# adding a plugin skill needs no installer edit.
install_plugin() {
  local slug="$1"
  local home_dir="$2"
  local pdir="$home_dir/plugins/adversarial-review-plugin"
  local skdir name

  install_file "$repo_dir/skills/$slug/plugin.json" "$pdir/plugin.json"
  for skdir in "$repo_dir/skills/$slug/skills"/*/; do
    [[ -d "$skdir" ]] || continue
    name="$(basename "$skdir")"
    install_file "$skdir/SKILL.md" "$pdir/skills/$name/SKILL.md"
    install_file "$repo_dir/skills/shared/PROTOCOL.md" "$pdir/skills/$name/references/PROTOCOL.md"
  done
  # Remove legacy plugin commands if present (older pre-release structures).
  delete_file_or_dir "$pdir/commands"
}

is_safe_to_delete() {
  local target="$1"
  # A missing target is conflict-free (safe to skip/no-op). Treat a broken
  # symlink as present (-L) so it is not silently left behind.
  [[ -e "$target" || -L "$target" ]] || return 0

  local c_plugin_dir
  local c_target
  c_plugin_dir="$(canonicalize "$plugin_dir")"
  c_target="$(canonicalize "$target")"

  # Never delete the filesystem root, including paths that resolve to it.
  if [[ "$c_target" == "/" ]]; then
    return 1
  fi

  # Bidirectional containment check with directory boundary safety (appending /)
  local check_plugin="${c_plugin_dir}/"
  local check_target="${c_target}/"

  if [[ "$check_plugin" == "$check_target"* ]]; then
    return 1
  fi
  if [[ "$check_target" == "$check_plugin"* ]]; then
    return 1
  fi
  return 0
}

delete_file_or_dir() {
  local target="$1"
  # -L so a broken symlink (for which -e is false) is still removed.
  [[ -e "$target" || -L "$target" ]] || return 0

  if [[ "$check_only" -eq 1 ]]; then
    echo "DELETE $target"
    return 0
  fi

  if [[ "$backup" -eq 1 ]]; then
    local dst_bak_path
    if is_under_plugin_dir "$target"; then
      # Write backups of plugin-internal paths outside the plugin scan directory
      local backups_dir="$antigravity_home/plugin-backups"
      mkdir -p "$backups_dir"
      local relative_path="${target#"$plugin_dir"/}"
      local flat_name="${relative_path//\//_}"
      dst_bak_path="$backups_dir/${flat_name}.bak.$timestamp"
    else
      dst_bak_path="$target.bak.$timestamp"
    fi
    cp -r "$target" "$dst_bak_path"
    echo "Backed up $target to $dst_bak_path"
  fi

  rm -rf "$target"
  echo "Deleted $target"
}

# Generated, roster-derived files must match the manifest before installing.
if ! "$repo_dir/scripts/generate.sh" --check; then
  if [[ "$check_only" -eq 1 ]]; then
    check_failed=1
  else
    echo "Generated files are stale. Run scripts/generate.sh and commit, then re-run." >&2
    exit 1
  fi
fi

# Install every adversary from the manifest. skill-kind installs the skill (+
# command wrappers when has_commands); plugin-kind installs the plugin tree.
for i in "${!adv_slug[@]}"; do
  slug="${adv_slug[$i]}"
  home="$(adv_home_resolved "$i")"
  case "${adv_kind[$i]}" in
    skill)  install_skill "$slug" "$home" ;;
    plugin) install_plugin "$slug" "$home" ;;
    *) echo "Unknown install_kind '${adv_kind[$i]}' for $slug" >&2; exit 1 ;;
  esac
  if [[ "${adv_cmds[$i]}" == "yes" ]]; then
    install_file "$repo_dir/commands/$slug/adversary.md" "$home/commands/adversary.md"
    install_file "$repo_dir/commands/$slug/contributor.md" "$home/commands/contributor.md"
  fi
  # Per-slug extras: Codex ships an agent descriptor alongside its skill.
  if [[ "$slug" == "codex" ]]; then
    install_file "$repo_dir/skills/codex/adversarial-review/agents/openai.yaml" "$home/skills/adversarial-review/agents/openai.yaml"
  fi
done

# Clean up legacy Gemini files if they exist to complete the deprecation (opt-in via --cleanup)
if [[ "$run_cleanup" -eq 1 ]]; then
  legacy_gemini_home="${GEMINI_HOME:-$HOME/.gemini}"
  legacy_skills="$legacy_gemini_home/skills/adversarial-review"
  legacy_adv="$legacy_gemini_home/commands/adversary.toml"
  legacy_contr="$legacy_gemini_home/commands/contributor.toml"

  if is_safe_to_delete "$legacy_skills"; then
    delete_file_or_dir "$legacy_skills"
  else
    echo "Warning: legacy skills path ($legacy_skills) overlaps with plugin_dir. Skipping directory deletion."
  fi

  if is_safe_to_delete "$legacy_adv"; then
    delete_file_or_dir "$legacy_adv"
  else
    echo "Warning: legacy adversary command ($legacy_adv) overlaps with plugin_dir. Skipping deletion."
  fi

  if is_safe_to_delete "$legacy_contr"; then
    delete_file_or_dir "$legacy_contr"
  else
    echo "Warning: legacy contributor command ($legacy_contr) overlaps with plugin_dir. Skipping deletion."
  fi
fi

if [[ "$check_only" -eq 0 ]]; then
  mkdir -p "$HOME/dev/ao/reviews"
fi

if [[ "$check_only" -eq 1 ]]; then
  if [[ "$check_failed" -eq 1 ]]; then
    echo "Check FAILED: installed copies differ from the repo, or generation drift." >&2
    exit 1
  fi
  echo "Check complete: all installed copies match."
else
  echo "Installed adversarial-review skills and commands."
fi
