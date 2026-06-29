# Adversarial Review Skill

Source of truth for the global `adversarial-review` skills (used by Codex, Claude, Antigravity, and GitHub Copilot) and slash-command wrappers (used by Codex and Claude).

## Layout

```text
skills/shared/PROTOCOL.md
skills/
  codex/adversarial-review/
  claude/adversarial-review/
  copilot/adversarial-review/
  antigravity/
    plugin.json
    skills/
      adversarial-review/
      adversary/
      contributor/
commands/
  codex/
  claude/
scripts/
  install.sh
```

The shared protocol is the source of truth for session layout, status values,
turn order, human gates, implementation, and verification.

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

The installer does not require the agent CLIs to be present — it installs each
agent's skill/command files unconditionally. Adversary availability is checked
at review time (not install time), so you can install this repo first and add a
client (e.g. `copilot`, `agy`) later; the next review picks it up with no
reinstall. An adversary whose CLI is absent at review time is skipped with reason
`not-installed`, and the review proceeds with whoever is available.

Before running managed reviews through Claude or Antigravity CLI, open/approve the
target repository and `~/dev/ao/reviews/` as trusted or allowed directories in
those CLIs. The Contributor should pause and ask for this when a CLI requires
interactive trust.

For CLI adversaries, prefer stdout-capture mode: ask the adversary to print its
review, then let the Contributor write the canonical session file. This avoids
making every worker responsible for cross-directory file writes.

When invoking Claude CLI non-interactively with `--add-dir`, put `--` before the
prompt because `--add-dir` accepts multiple directory arguments:

```sh
claude -p --add-dir /path/to/target --add-dir ~/dev/ao/reviews -- "prompt"
```

If Claude should write files directly, also provide a write-capable permission
mode:

```sh
claude -p --permission-mode acceptEdits --add-dir /path/to/target --add-dir ~/dev/ao/reviews -- "prompt"
```

The `--` separator fixes argument parsing. The permission mode controls whether
non-interactive file writes can proceed without a prompt.

To check whether installed copies match the repo without writing:

```sh
scripts/install.sh --check
```

The installer creates timestamped `.bak.<timestamp>` backups before overwriting
changed installed files. Use `--no-backup` only when you intentionally do not
want backups.

Destination roots and legacy folders can be overridden:

```sh
CODEX_HOME=~/.codex CLAUDE_HOME=~/.claude COPILOT_HOME=~/.copilot ANTIGRAVITY_HOME=~/.gemini/config GEMINI_HOME=~/.gemini scripts/install.sh
```

Specify `GEMINI_HOME` (defaulting to `~/.gemini`) to locate legacy Gemini installations for cleanups and deprecation.

## Agent Surfaces

Codex:

- skill: `~/.codex/skills/adversarial-review/`
- commands: `~/.codex/commands/adversary.md`,
  `~/.codex/commands/contributor.md`

Claude:

- skill: `~/.claude/skills/adversarial-review/`
- commands: `~/.claude/commands/adversary.md`,
  `~/.claude/commands/contributor.md`

GitHub Copilot (using copilot CLI):

- skill: `~/.copilot/skills/adversarial-review/`
- Copilot discovers personal `SKILL.md` files from `~/.copilot/skills/`. It has
  no user-defined slash-command wrappers (only built-in commands like `/skills`),
  so there are no command files to install.
- Invoke as a CLI adversary with
  `copilot -p "prompt" -s --allow-all-tools --add-dir <target> --add-dir ~/dev/ao/reviews`.

Antigravity (using agy CLI):

- Plugin is installed under: `~/.gemini/config/plugins/adversarial-review-plugin/`
- Local plugins placed under `plugins/` are automatically discovered and loaded by `agy` on startup, but will not show in `agy plugin list` (which only lists marketplace-imported/installed plugins).
- The plugin registers three skills:
  - `adversarial-review`: `skills/adversarial-review/SKILL.md`
  - `adversary`: `skills/adversary/SKILL.md` (registers the `adversary` skill capability)
  - `contributor`: `skills/contributor/SKILL.md` (registers the `contributor` skill capability)

## Sessions

Closed sessions are audit artifacts. Archive or delete them only when you no
longer need the review trail.

## Rule

Edit this repository first. Treat `~/.codex`, `~/.claude`, and `~/.gemini/config`
copies as installed artifacts.

## Sharing

This repository is published under the MIT license (see `LICENSE`).
