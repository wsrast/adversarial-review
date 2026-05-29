# Adversarial Review Skill

Source of truth for the global `adversarial-review` skills and slash-command
wrappers used by Codex, Claude, and Gemini.

## Layout

```text
skills/shared/PROTOCOL.md
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

Before running managed reviews through Claude or Gemini CLI, open/approve the
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

Destination roots can be overridden:

```sh
CODEX_HOME=~/.codex CLAUDE_HOME=~/.claude GEMINI_HOME=~/.gemini scripts/install.sh
```

## Agent Surfaces

Codex:

- skill: `~/.codex/skills/adversarial-review/`
- commands: `~/.codex/commands/adversary.md`,
  `~/.codex/commands/contributor.md`

Claude:

- skill: `~/.claude/skills/adversarial-review/`
- commands: `~/.claude/commands/adversary.md`,
  `~/.claude/commands/contributor.md`

Gemini:

- skill reference files are installed to `~/.gemini/skills/adversarial-review/`
- command wrappers are installed to `~/.gemini/commands/*.toml`
- the command wrappers are the reliable entrypoint; the Gemini skill files are
  installed so prompts and agents can read the same local protocol

## Sessions

Closed sessions are audit artifacts. Archive or delete them only when you no
longer need the review trail.

## Rule

Edit this repository first. Treat `~/.codex`, `~/.claude`, and `~/.gemini`
copies as installed artifacts.

## Sharing

Add a license before publishing this repository outside your own machines or
organization.
