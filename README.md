# Adversarial Review Skill

Source of truth for the global `adversarial-review` skills and slash-command
wrappers used by Codex, Claude, and Gemini.

## Layout

```text
skills/
  codex/adversarial-review/
  claude/adversarial-review/
  gemini/adversarial-review/
commands/
  codex/
  claude/
  gemini/
scripts/
  install.sh
```

Review sessions created by the skill live outside project repos at:

```text
~/dev/ao/reviews/<session>/
```

## Install

After changing files in this repo, install them to the global agent locations:

```sh
scripts/install.sh
```

Then restart any CLI/app that caches slash commands or skills.

## Rule

Edit this repository first. Treat `~/.codex`, `~/.claude`, and `~/.gemini`
copies as installed artifacts.

