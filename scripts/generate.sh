#!/usr/bin/env bash
set -euo pipefail

# generate.sh — regenerate roster-derived content from adversaries.manifest.
#
# Two pure-bash mechanisms (no sed -i; portable BSD/GNU; bash 3.2 compatible):
#   1. Inline "[with X, Y, Z]" rewrite — replaces the bracket roster on any line,
#      preserving all surrounding hand-authored prose. The owning slug is derived
#      from the file path, and the list is the OTHER adversaries in manifest order.
#   2. Block-marker replacement — replaces content between
#      "<!-- BEGIN GENERATED: <name> -->" and "<!-- END GENERATED: <name> -->".
#
# Usage:
#   scripts/generate.sh            regenerate in place
#   scripts/generate.sh --check    report drift and exit non-zero if any (no writes)

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$repo_dir/adversaries.manifest"

check_only=0
[ "${1:-}" = "--check" ] && check_only=1
drift=0

# emit <target> <newcontent-tmpfile>: in check mode report drift; else atomic write.
emit() {
  local target="$1" tmp="$2"
  if [ "$check_only" -eq 1 ]; then
    if ! cmp -s "$tmp" "$target"; then echo "DRIFT $target"; drift=1; fi
    rm -f "$tmp"
  else
    if cmp -s "$tmp" "$target" 2>/dev/null; then echo "unchanged $target"; rm -f "$tmp";
    else mv "$tmp" "$target"; echo "generated $target"; fi
  fi
}

# rewrite_brackets <target> <slug>: rewrite the "[with ...]" roster on each line
# to the OTHER adversaries of <slug>. Preserves everything else.
rewrite_brackets() {
  local target="$1" slug="$2" others line tmp
  others="$(adv_others_display "$slug")"
  tmp="$(mktemp)"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      *"[with "*"]"*)
        printf '%s\n' "${line%%\[with *}[with ${others}]${line#*\]}" ;;
      *) printf '%s\n' "$line" ;;
    esac
  done < "$target" > "$tmp"
  emit "$target" "$tmp"
}

# replace_block <target> <name> <contentfile>: replace between markers.
# Fails (exit 1) on missing, duplicate, or unterminated markers.
replace_block() {
  local target="$1" name="$2" contentfile="$3"
  local begin="<!-- BEGIN GENERATED: ${name} -->"
  local end="<!-- END GENERATED: ${name} -->"
  local in_block=0 nbegin=0 nend=0 line tmp
  tmp="$(mktemp)"
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "$begin" ]; then
      nbegin=$((nbegin+1)); in_block=1
      printf '%s\n' "$begin"; cat "$contentfile"
      continue
    fi
    if [ "$line" = "$end" ]; then
      nend=$((nend+1)); in_block=0
      printf '%s\n' "$end"; continue
    fi
    [ "$in_block" -eq 1 ] && continue
    printf '%s\n' "$line"
  done < "$target" > "$tmp"
  if [ "$nbegin" -ne 1 ] || [ "$nend" -ne 1 ] || [ "$in_block" -ne 0 ]; then
    echo "ERROR: marker '$name' in $target must appear exactly once and be terminated (begin=$nbegin end=$nend)" >&2
    rm -f "$tmp"; exit 1
  fi
  emit "$target" "$tmp"
}

# --- Mechanism 1: inline roster brackets -------------------------------------
for i in "${!adv_slug[@]}"; do
  slug="${adv_slug[$i]}"
  if [ "${adv_kind[$i]}" = "skill" ]; then
    rewrite_brackets "$repo_dir/skills/$slug/adversarial-review/SKILL.md" "$slug"
  fi
  if [ "${adv_cmds[$i]}" = "yes" ]; then
    rewrite_brackets "$repo_dir/commands/$slug/contributor.md" "$slug"
  fi
done
# Antigravity plugin skills that carry a roster (adversary/ is roster-free).
rewrite_brackets "$repo_dir/skills/antigravity/skills/adversarial-review/SKILL.md" antigravity
rewrite_brackets "$repo_dir/skills/antigravity/skills/contributor/SKILL.md" antigravity

# --- Mechanism 2: block markers ----------------------------------------------
# README description roster (one sentence).
roster_names=""
for i in "${!adv_slug[@]}"; do
  if [ -z "$roster_names" ]; then roster_names="${adv_name[$i]}"; else roster_names="$roster_names, ${adv_name[$i]}"; fi
done
cf="$(mktemp)"
printf 'Source of truth for the global `adversarial-review` skills and slash-command wrappers. Supported agents: %s.\n' "$roster_names" > "$cf"
replace_block "$repo_dir/README.md" "roster-blurb" "$cf"

# PROTOCOL agent->CLI map table.
cf="$(mktemp)"
{
  echo
  echo "| Agent | CLI binary | Install kind |"
  echo "| --- | --- | --- |"
  for i in "${!adv_slug[@]}"; do
    printf '| %s | `%s` | %s |\n' "${adv_name[$i]}" "${adv_cli[$i]}" "${adv_kind[$i]}"
  done
  echo
} > "$cf"
replace_block "$repo_dir/skills/shared/PROTOCOL.md" "agent-cli-map" "$cf"

if [ "$check_only" -eq 1 ]; then
  if [ "$drift" -ne 0 ]; then
    echo "Generation drift detected. Run scripts/generate.sh and commit." >&2
    exit 1
  fi
  echo "Generation check: no drift."
else
  echo "Generation complete."
fi
