---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/dev/ao/reviews. Use when the user invokes /contributor or /adversary, asks Codex to orchestrate Claude/Gemini adversaries, wants adversarial critique of a file, branch, plan, design, implementation, or concept, or wants a structured back-and-forth review with implementation and verification.
---

# Adversarial Review

## Purpose

Run a structured review where one Contributor orchestrates all state and one or
more Adversaries critique the target. The Contributor owns the session, turn
order, implementation, verification, and closure. Adversaries write only to
their assigned files.

Prefer a fully managed flow: the human starts the review once, then the
Contributor runs rounds until agreement, pausing only for required tool
approvals, destructive actions, or explicit human judgment gates.

## Commands

- `/contributor <target> [with <adversaries>]`: primary entrypoint. Act as the
  Contributor and orchestrator.
- `/adversary <session-dir> <assigned-id> <round>`: worker entrypoint. Act only
  as the assigned Adversary for the session and round.

The target may be a file, directory, branch diff, git changes, plan, design,
implementation, or concept. If the user does not name adversaries, default to
Claude and Gemini when their CLIs or integrations are available; otherwise use
the available non-Contributor agents and record the limitation.

Never invoke the same agent/runtime as both Contributor and Adversary in the
same session. In this Codex desktop environment, do not call the Codex CLI as an
Adversary when Codex is the Contributor; that is redundant and wastes tokens.
Likewise, a Claude Contributor should not invoke Claude as an Adversary, and a
Gemini Contributor should not invoke Gemini as an Adversary. If the user names
the current agent as an adversary, record it as skipped with reason
`same-as-contributor`.

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
    round-02.md
    verification-01.md
  02-gemini/
    registration.yaml
    round-01.md
rounds/
  round-01-contributor.md
  round-02-contributor.md
implementation-summary.md
final.md
prompts/
  01-claude-round-01.md
  02-gemini-round-01.md
```

Only the Contributor edits `session.yaml`, `contributor.md`,
`rounds/*-contributor.md`, `implementation-summary.md`, and `final.md`.
Adversaries edit only their own subdirectory.

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

1. If a goal tool or `/goal` capability is available, create or continue a goal
   for the full review. Use it to persist through routine rounds without
   asking the human to babysit.
2. Create the session directory under `~/dev/ao/reviews/`.
3. Write `target.md` with the review target, relevant paths, repo root, and
   scope. For a branch/diff review, include the exact base/head or command used
   to inspect changes.
4. Create `session.yaml` and assign adversary IDs before invoking agents.
   Exclude the current Contributor runtime from the adversary list before IDs
   are assigned.
5. For each adversary, create a prompt in `prompts/` that includes:
   - session directory
   - assigned ID and agent name
   - target summary
   - exact output file path for the round
   - instruction to use `/adversary` worker mode
   - instruction not to edit shared session files
6. Invoke each intended adversary with the available CLI/integration. If an
   agent cannot be invoked directly, record it as `blocked` and notify the
   human only if the review cannot continue usefully.
7. Wait for all adversary files for the round.
8. Write the Contributor response in `rounds/round-N-contributor.md`, accepting,
   rejecting, or modifying each concern with concrete next changes.
9. Continue Adversary -> Contributor rounds until all adversaries end a round
   with `Agreed`, or until a blocker requires human judgment.
10. When agreement is reached, implement the agreed changes unless the session
    requires human approval first.
11. Write `implementation-summary.md` with changed files, commands run, and
    unresolved risks.
12. Send each adversary a verification prompt. Each writes
    `verification-<n>.md` in their directory.
13. If every adversary verifies with `Agreed`, write `final.md` and set
    `status: closed`. If any adversary disagrees, return to review rounds.

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
4. Write only to the assigned round or verification file.
5. End with exactly one verdict line:
   - `Not agreed`
   - `Conditionally agreed`
   - `Agreed`

Do not edit `session.yaml`, the target, Contributor files, or another
Adversary's files. Do not play the Contributor.

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
