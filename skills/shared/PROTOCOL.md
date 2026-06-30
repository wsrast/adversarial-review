# Adversarial Review Protocol

## Purpose

Run a structured review where one Contributor orchestrates all state and one or
more Adversaries critique the target. The Contributor owns the session, turn
order, implementation, verification, and closure.

Preferred managed mode: Adversaries return their review on stdout and the
Contributor writes the canonical session files. Direct adversary file writes are
allowed only when the target CLI has explicit file-write permission configured.

Prefer a fully managed flow: the human starts the review once, then the
Contributor runs rounds until agreement, pausing only for required tool
approvals, destructive actions, or explicit human judgment gates.

## Commands

- `/contributor <target> [with <adversaries>]`: primary entrypoint. Act as the
  Contributor and orchestrator.
- `/adversary <session-dir> <assigned-id> <round>`: worker entrypoint. Act only
  as the assigned Adversary for the session and round.

Never invoke the same agent/runtime as both Contributor and Adversary in the
same session. A Contributor must filter the current runtime out of the
adversary list before assigning IDs. If the user names the current agent as an
adversary, record it as skipped with reason `same-as-contributor`.

## Session Location

Never place review artifacts beside project files. Store sessions under:

```text
~/.config/reviews/
```

Create one subdirectory per review:

```text
~/.config/reviews/YYYYMMDD-HHMM-<target-slug>/
```

Recommended layout:

```text
session.yaml
target.md
contributor.md
adversaries/
  01-claude/
    registration.yaml
    round-01.md
    verification-01.md
  02-antigravity/
    registration.yaml
    round-01.md
rounds/
  round-01-contributor.md
implementation-summary.md
final.md
prompts/
  01-claude-round-01.md
  02-antigravity-round-01.md
```

Only the Contributor edits `session.yaml`, `contributor.md`,
`rounds/*-contributor.md`, `implementation-summary.md`, `final.md`, and
`prompts/*`. In preferred managed mode, the Contributor also writes adversary
stdout into the assigned adversary files. In direct-write mode, Adversaries edit
only their assigned subdirectory.

Directory names use zero-padded IDs plus a lowercase agent slug. The explicit
`dir` field in `session.yaml` is authoritative when in doubt.

## Session State

Use `session.yaml` as the source of truth.

```yaml
target: "infra-plan/tsconfig-strategy.md"
status: "registering"
round: 1
created_by: "Codex"
review_dir: "~/.config/reviews/20260529-1530-tsconfig-strategy"
adversaries:
  - id: 1
    agent: "Claude"
    model: "unknown"
    status: "pending"
    dir: "adversaries/01-claude"
  - id: 2
    agent: "Antigravity"
    model: "unknown"
    status: "pending"
    dir: "adversaries/02-antigravity"
skipped_adversaries:
  - agent: "Codex"
    reason: "same-as-contributor"
  # reason values: same-as-contributor | not-installed (CLI absent at review
  # time; a later-added client is picked up on the next review, no reinstall)
contributor:
  agent: "Codex"
  model: "GPT-5"
  status: "active"
human_gates:
  implementation_requires_approval: true
  # Optional. Default false: an adversary that fails operationally is dropped
  # automatically (see Adversary Failure Handling). Set true only if the user
  # asks for a human in the loop on adversary drop-outs.
  adversary_failure_requires_approval: false
```

Statuses:

- `registering`
- `round-N-adversaries`
- `round-N-contributor`
- `agreed`
- `awaiting-human-approval`
- `implementing`
- `implemented`
- `verifying`
- `closed`
- `blocked` (per-adversary: dropped after an operational failure; session-level:
  halted for the human because no working adversary remains)

## Supported Agents

The roster below is generated from `adversaries.manifest` by `scripts/generate.sh`.
To add an adversary, add one manifest row, author its invocation block in this
file, then run `scripts/generate.sh` and `scripts/install.sh`.

<!-- BEGIN GENERATED: agent-cli-map -->

| Agent | CLI binary | Install kind |
| --- | --- | --- |
| Codex | `codex` | skill |
| Claude | `claude` | skill |
| Copilot | `copilot` | skill |
| Antigravity | `agy` | plugin |

<!-- END GENERATED: agent-cli-map -->

## Contributor Workflow

1. Use a goal/autonomous-continuation workflow when available so the human does
   not need to relay every round.
2. Create the session directory under `~/.config/reviews/`.
3. Write `target.md` with the review target, relevant paths, repo root, and
   scope. For a branch/diff review, include the exact base/head or command used
   to inspect changes.
4. Build the adversary list. Exclude the current Contributor runtime before
   assigning IDs. Then check availability **at review time, not install time** —
   a client may be added after the repo was installed, and each review should
   pick that up with no reinstall. Probe each candidate's CLI when the review
   starts (`command -v <cli>`); see the agent→CLI map under "Supported Agents".
   - If a candidate's CLI is absent, record it under `skipped_adversaries` with
     reason `not-installed` and do not assign it an ID. If the user explicitly
     named that adversary, surface the `not-installed` skip in your summary
     rather than silently spinning up a doomed invocation.
   - An installed CLI that later fails mid-review is a different case — that is a
     runtime `blocked` drop (step 7 / Adversary Failure Handling), not a skip.
   - If the probe leaves no available adversaries, halt for the human (see
     Adversary Failure Handling); a review with no working adversary validates
     nothing.
5. Create `session.yaml`, adversary directories, and per-agent prompts.
6. Before invoking CLI-based adversaries, verify the target repository and
   review session directory are trusted/allowed in that CLI. If trust must be
   granted interactively, pause at a human gate and ask the human to mark the
   directories trusted before continuing.
   - Prefer stdout-capture mode for CLI adversaries. Ask the adversary to print
     the review to stdout, then the Contributor writes the output to the
     assigned file.
   - For Claude CLI, pass both the target repo and review root with `--add-dir`
     and terminate variadic directory arguments with `--` before the prompt.
     This fixes argument parsing because `--add-dir` accepts multiple
     directories. Example:

     ```sh
     claude -p --add-dir /path/to/target --add-dir ~/.config/reviews -- "prompt"
     ```

   - If Claude is expected to write files directly, add an explicit write-capable
     permission mode as well:

     ```sh
     claude -p --permission-mode acceptEdits --add-dir /path/to/target --add-dir ~/.config/reviews -- "prompt"
     ```

     Without `--`, Claude may treat the prompt as another directory. Without a
     write-capable permission mode, Claude may parse the prompt correctly but
     still wait for write approval that cannot complete in non-interactive mode.
    - For Antigravity CLI (`agy`), run with `-p` or `--print` for non-interactive
      execution, pass directories via `--add-dir` (repeatable), and redirect stdin
      from `/dev/null` to prevent blocking. **Flag syntax is strict in `agy` (verified
      against `agy 1.0.13`) and getting it wrong fails silently — agy exits 0, ignores
      the prompt, and emits unrelated text instead of the review:**
      - Pass every value-taking flag in **equals form** (`--add-dir=/path`,
        `--print-timeout=20m`). Space-separated values (`--add-dir /path`) leak the
        flag tokens into the prompt and derail the run.
      - Put `--print-timeout` **before** `-p`/`--print`; after `-p` it is not consumed
        and corrupts the prompt. (Default timeout is 5m if omitted.)
      - Put the prompt last as a single trailing positional argument. Do not use `--`.
      - If direct file-write or automated tool execution is absolutely required,
        `--dangerously-skip-permissions` can be passed to auto-approve all tool
        permission requests without prompting; use only as a last resort within
        already-trusted target and review directories.
      - Always sanity-check the captured output actually contains a review and a
        verdict line; a stdout that discusses CLI flags or is unrelated to the target
        means the invocation was mis-parsed.

      Verified-working example:

     ```sh
     agy --print-timeout=20m --add-dir=/path/to/target --add-dir="$HOME/.config/reviews" -p "prompt" < /dev/null
     ```
    - For GitHub Copilot CLI (`copilot`), run with `-p`/`--prompt` for
      non-interactive execution and pass `--allow-all-tools` — it is **required**
      for non-interactive mode so the agent's read/shell tools run without a
      confirmation prompt (otherwise it blocks). Grant file access to the target
      and review roots with `--add-dir <dir>` (repeatable; space form is fine).
      Add `-s`/`--silent` so stdout contains only the agent response (no progress
      lines or stats), which is what the Contributor captures. Verified against
      `GitHub Copilot CLI 1.0.65`. Example:

     ```sh
     copilot -p "prompt" -s --allow-all-tools --add-dir /path/to/target --add-dir "$HOME/.config/reviews"
     ```

      `--allow-all-tools` permits shell execution — the same kind of escalation
      as Claude's `acceptEdits` or `agy --dangerously-skip-permissions`, and it
      falls under the "CLI workspace trust or file-access approval" human gate
      above: only use it within already-trusted target and review directories.
      Keep the adversary prompt read-only (review, do not modify). Where the
      installed `copilot` supports it, narrow the grant instead of allowing
      everything — e.g. deny mutating tools (`--deny-tool 'shell(git push)'`) or
      pass an explicit `--allow-tool` allowlist — so a review cannot write or push.
      As with every CLI adversary, sanity-check that the captured stdout is an
      actual review ending in a verdict line.
    - For Codex CLI (`codex`), run `codex exec -s read-only -C <target>` for a
      read-only non-interactive review, pass the prompt as the trailing argument,
      and capture the final message with `-o <file>`. **Always redirect stdin
      from `/dev/null`** — `codex exec` also reads stdin (appending it as a
      `<stdin>` block) and will block indefinitely waiting for EOF when stdin is
      left open (e.g. in a background/non-interactive run). Add `--add-dir <dir>`
      for any extra readable roots (e.g. the review session dir). Example:

     ```sh
     codex exec -s read-only -C /path/to/target --add-dir "$HOME/.config/reviews" \
       -o out.txt "prompt" < /dev/null
     ```
7. Invoke each adversary with the available CLI/integration. If an adversary
   fails operationally (cannot be invoked, errors out, exhausts its token/credit
   quota, or hits a network/timeout failure), drop it automatically per
   "Adversary Failure Handling": mark that adversary `blocked` with a reason and
   continue with the remaining non-blocked adversaries. Do not pause unless an
   exception in that section applies.
8. Wait for the round's adversary files from all non-blocked adversaries. Treat a
   missing or non-unique final verdict line, or output that is not a review of
   the target, as an incomplete response — re-invoke once if cheap, otherwise
   drop that adversary as an operational failure (do not count it as a verdict).
9. Write the Contributor response in `rounds/round-N-contributor.md`, accepting,
   rejecting, or modifying each concern with concrete next changes.
10. Continue Adversary -> Contributor rounds until all non-blocked adversaries
   end a round with `Agreed`, or until a blocker requires human judgment.
11. When agreement is reached, implement the agreed changes unless the session
    requires human approval first.
12. Write `implementation-summary.md` with changed files, commands run, and
    unresolved risks.
13. Send each adversary a verification prompt. Each writes
    `verification-<n>.md` in their directory. Use `<n>` as a sequential
    verification attempt counter unless the session explicitly chooses a
    round-based naming convention.
14. If every non-blocked adversary verifies with `Agreed`, write `final.md`
    (recording any blocked/dropped adversaries and why) and set `status: closed`.
    If any disagrees, return to review rounds. If every adversary ended up
    blocked, do not close: set the session `status: blocked` and halt for the
    human — a review with no working adversary validates nothing.
15. On closure, keep the session directory as an audit artifact. The Contributor
    may suggest archiving old sessions, but should not delete them without user
    instruction.

## Adversary Failure Handling

Distinguish an *operational failure* from a *review verdict*. An operational
failure is when an adversary cannot produce a valid review: it cannot be invoked
(including a CLI that is not installed), errors out, exhausts its token/credit
quota, hits a network/timeout failure (after the CLI's own retries), or returns
an incomplete response — no single valid verdict line, or output that is not a
review of the target. A verdict (`Agreed`, `Conditionally agreed`, `Not agreed`)
is a substantive position and is NEVER treated as a failure.

A not-installed CLI is ideally caught proactively at selection (step 4) and
recorded as a `skipped_adversaries` entry with reason `not-installed`; a CLI that
is installed but fails during the review is a runtime `blocked` drop. Both remove
the adversary from round-completion and closure checks; the difference is only
when it was detected.

Default behavior — auto-drop, unattended-safe. When an adversary fails
operationally, the Contributor drops it automatically and keeps going: set that
adversary's `status: blocked` with a `blocked_reason`, and continue the round
with the remaining non-blocked adversaries. Do NOT pause the review for an
operational failure. A dropped adversary is excluded from round-completion and
closure checks unless it is later re-invoked successfully. The rationale is that
an unattended review should not stall on one adversary's token snafu or network
blip while other adversaries can still do the job.

Two exceptions require halting for the human instead of auto-dropping:

1. No adversary would remain. If removing this adversary would leave zero
   available adversaries (counting both selection-time `not-installed` skips and
   runtime `blocked` drops), do not proceed: set the session `status: blocked`,
   notify the human, and wait. This is the one case where a failure halts the
   review, because nothing could validate the change.
2. The session opts into human-gated failures. If the user asked for a human in
   the loop on adversary failures, set
   `human_gates.adversary_failure_requires_approval: true`; then pause at a human
   gate before dropping ANY adversary, regardless of how many would remain.

Record every drop in `final.md` so the audit trail shows which adversaries
participated and which were blocked, and why.

## Adversary Workflow

Act only as the assigned Adversary.

1. Read `session.yaml`, `target.md`, prior Contributor responses, and any
   assigned prompt.
2. Write `registration.yaml` in your assigned directory if missing:

   ```yaml
   id: 1
   agent: "Claude"
   model: "unknown"
   status: "registered"
   ```

3. Inspect the target rigorously.
4. In preferred managed mode, print the review to stdout and do not write files;
   the Contributor will save it. In direct-write mode, write only to the
   assigned round or verification file.
5. End with exactly one verdict line:
   - `Not agreed`
   - `Conditionally agreed`
   - `Agreed`

Do not edit `session.yaml`, the target, Contributor files, or another
Adversary's files. Do not play the Contributor in worker mode.

## Review Quality

Adversaries prioritize:

- blockers and correctness risks
- hidden assumptions
- missing evidence or verification
- operational, security, maintainability, and migration risks
- places where the stated goal and actual shape diverge
- concrete improvements that would make the design harder to misuse

The Contributor must:

- answer every material adversarial point
- accept good criticism even when the original wording overreaches
- reject only with evidence
- identify exact changes, owners, and verification
- keep unresolved objections explicit

## Human Gates And Notifications

Do not ask for routine approvals during ordinary review rounds. Pause only for:

- destructive commands
- tool policy requiring approval
- external network/install escalation
- CLI workspace trust or file-access approval for target/review directories
- applying agreed changes when `implementation_requires_approval` is true
- product/design judgment the agents cannot resolve
- an adversary failure that hits an exception in "Adversary Failure Handling"
  (no non-blocked adversary would remain, or
  `adversary_failure_requires_approval` is true)

An adversary's operational failure is NOT a pause by default — drop it and
continue per "Adversary Failure Handling". Only the two exceptions above turn a
failure into a human gate.

When a phone/thread notification capability is available, notify the human at
human gates with a short summary, the proposed action, and the exact approval
needed. Then wait for the approval in the authorized thread/app channel.

## Implementation Rules

Only the Contributor implements agreed changes unless the user explicitly asks
otherwise. Respect repository safety rules: do not revert unrelated user work,
do not stage ignored review artifacts, and do not run destructive commands
without explicit approval.

After implementation, verification is mandatory. Closure requires every
non-blocked Adversary to verify the implemented changes with `Agreed`. If every
adversary has been dropped, halt for the human instead of closing (see Adversary
Failure Handling).
