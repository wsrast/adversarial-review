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
~/dev/ao/reviews/
```

Create one subdirectory per review:

```text
~/dev/ao/reviews/YYYYMMDD-HHMM-<target-slug>/
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
  02-gemini/
    registration.yaml
    round-01.md
rounds/
  round-01-contributor.md
implementation-summary.md
final.md
prompts/
  01-claude-round-01.md
  02-gemini-round-01.md
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
review_dir: "/Users/wesleyrastjc/dev/ao/reviews/20260529-1530-tsconfig-strategy"
adversaries:
  - id: 1
    agent: "Claude"
    model: "unknown"
    status: "pending"
    dir: "adversaries/01-claude"
  - id: 2
    agent: "Gemini"
    model: "unknown"
    status: "pending"
    dir: "adversaries/02-gemini"
skipped_adversaries:
  - agent: "Codex"
    reason: "same-as-contributor"
contributor:
  agent: "Codex"
  model: "GPT-5"
  status: "active"
human_gates:
  implementation_requires_approval: true
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
- `blocked`

## Contributor Workflow

1. Use a goal/autonomous-continuation workflow when available so the human does
   not need to relay every round.
2. Create the session directory under `~/dev/ao/reviews/`.
3. Write `target.md` with the review target, relevant paths, repo root, and
   scope. For a branch/diff review, include the exact base/head or command used
   to inspect changes.
4. Build the adversary list. Exclude the current Contributor runtime before
   assigning IDs.
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
     claude -p --add-dir /path/to/target --add-dir ~/dev/ao/reviews -- "prompt"
     ```

   - If Claude is expected to write files directly, add an explicit write-capable
     permission mode as well:

     ```sh
     claude -p --permission-mode acceptEdits --add-dir /path/to/target --add-dir ~/dev/ao/reviews -- "prompt"
     ```

     Without `--`, Claude may treat the prompt as another directory. Without a
     write-capable permission mode, Claude may parse the prompt correctly but
     still wait for write approval that cannot complete in non-interactive mode.
7. Invoke each adversary with the available CLI/integration. If an agent cannot
   be invoked directly, record it as `blocked` and notify the human only if the
   review cannot continue usefully.
8. Wait for all adversary files for the round. Treat a missing final verdict
   line as an incomplete response.
9. Write the Contributor response in `rounds/round-N-contributor.md`, accepting,
   rejecting, or modifying each concern with concrete next changes.
10. Continue Adversary -> Contributor rounds until all adversaries end a round
   with `Agreed`, or until a blocker requires human judgment.
11. When agreement is reached, implement the agreed changes unless the session
    requires human approval first.
12. Write `implementation-summary.md` with changed files, commands run, and
    unresolved risks.
13. Send each adversary a verification prompt. Each writes
    `verification-<n>.md` in their directory. Use `<n>` as a sequential
    verification attempt counter unless the session explicitly chooses a
    round-based naming convention.
14. If every adversary verifies with `Agreed`, write `final.md` and set
    `status: closed`. If any adversary disagrees, return to review rounds.
15. On closure, keep the session directory as an audit artifact. The Contributor
    may suggest archiving old sessions, but should not delete them without user
    instruction.

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

When a phone/thread notification capability is available, notify the human at
human gates with a short summary, the proposed action, and the exact approval
needed. Then wait for the approval in the authorized thread/app channel.

## Implementation Rules

Only the Contributor implements agreed changes unless the user explicitly asks
otherwise. Respect repository safety rules: do not revert unrelated user work,
do not stage ignored review artifacts, and do not run destructive commands
without explicit approval.

After implementation, verification is mandatory. Closure requires every
Adversary to verify the implemented changes with `Agreed`.
