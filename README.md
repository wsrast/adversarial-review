# Adversarial Review Skill

<!-- BEGIN GENERATED: roster-blurb -->
Source of truth for the global `adversarial-review` skills and slash-command wrappers. Supported agents: Codex, Claude, Copilot, Antigravity.
<!-- END GENERATED: roster-blurb -->

## Why this exists

Most coding harnesses ship a built-in `/review` that asks **the same model that
wrote the code** to critique it. That has two problems this project is built to
avoid.

**1. An agent should not review its own work.** LLMs systematically favor their
own outputs when acting as judge — a measured effect variously called
*self-enhancement bias* ([Zheng et al., 2023](https://arxiv.org/abs/2306.05685))
and *self-preference bias*, which is amplified by the fact that models can
recognize their own generations ([Panickssery et al., 2024](https://arxiv.org/abs/2404.13076)).
Conversely, having *multiple, independent* models critique and debate a result
measurably improves factuality and reasoning and reduces hallucinations
([Du et al., 2023](https://arxiv.org/abs/2305.14325)). This tool enforces that
structurally: the Contributor (the agent orchestrating the change) is always
excluded from its own adversary panel, and review is delegated to **different
vendors' models** (Codex, Claude, Copilot, Antigravity). Diversity catches
failure modes a single model — or a harness grading its own homework — misses.

**2. It runs on your subscriptions, not metered API tokens.** Because the
Contributor *shells out to each agent's own CLI* (`claude`, `codex`, `copilot`,
`agy`), every review round runs on whatever plan that CLI is already signed in
to — a flat-rate Pro/Max/Team subscription or a Copilot seat — instead of
per-token API billing. A multi-round, multi-agent adversarial review adds no
API spend.

**Further benefits over a built-in `/review`:**

- **Adversarial and structured, not a one-shot comment dump.** Skeptical
  senior-peer review with explicit verdicts (`Not agreed` / `Conditionally
  agreed` / `Agreed`), Contributor rebuttals, rounds that continue until
  agreement, and a **mandatory verification round after implementation**.
- **Durable audit trail.** Every prompt, round, verdict, and final decision is
  persisted under `~/.config/reviews/<session>/` for later inspection.
- **Unattended-safe.** Operational failures (token/quota, network) auto-drop the
  affected adversary and continue; it only halts for a human when no reviewer
  remains, or when you opt in to a human gate.
- **Vendor-agnostic and extensible.** Adding a new agent is one row in
  `adversaries.manifest`; the same protocol drives every CLI.

## Layout

```text
adversaries.manifest        # single source of truth for the adversary roster
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
  generate.sh               # regenerates roster-derived content from the manifest
  install.sh
```

The shared protocol is the source of truth for session layout, status values,
turn order, human gates, implementation, and verification.

## Adding an adversary

The adversary roster lives in one place: `adversaries.manifest` (a
bash-sourceable registry of slug, CLI binary, install home, install kind, and
whether it has command wrappers). Roster-derived content — the `[with …]` lists
in skills/commands, the README blurb above, and the agent→CLI table in
`PROTOCOL.md` — is generated from it.

To add an adversary:

1. Add one row to `adversaries.manifest`.
2. Author its non-interactive invocation block in `skills/shared/PROTOCOL.md`.
3. Run `scripts/generate.sh` (regenerates the roster-derived files), then
   `scripts/install.sh`.

`scripts/generate.sh --check` exits non-zero if any generated file has drifted
from the manifest (use it in CI / a pre-commit hook); `scripts/install.sh` runs
that check first and refuses to install stale generated files.

Review sessions created by the skill live outside project repos at:

```text
~/.config/reviews/<session>/
```

## Install

After changing files in this repo, install them to the global agent locations:

```sh
scripts/install.sh
```

Then restart any CLI/app that caches slash commands or skills.

The installer does not require the agent CLIs to be present — it installs each
agent's skill/command files unconditionally, so you can install this repo first
and add a client (e.g. `copilot`, `agy`) later. (Availability is then resolved
at review time, not install time — see [Running reviews](#running-reviews).)

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

## Running reviews

The exact non-interactive invocation for each CLI (`claude`, `codex`, `copilot`,
`agy`) — flags, argument-ordering quirks, and capture mode — is documented
authoritatively in `skills/shared/PROTOCOL.md`. That is the single source of
truth, so it is not duplicated here. Operational notes:

- Before running managed reviews, open/approve the target repository and
  `~/.config/reviews/` as trusted/allowed directories in each CLI. The
  Contributor pauses and asks when a CLI requires interactive trust.
- Prefer stdout-capture mode: the adversary prints its review and the Contributor
  writes the canonical session file, so no worker needs cross-directory writes.
- An adversary whose CLI is absent at review time is skipped (`not-installed`)
  and the review proceeds with whoever is available.

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
  `copilot -p "prompt" -s --allow-all-tools --add-dir <target> --add-dir ~/.config/reviews`.

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
