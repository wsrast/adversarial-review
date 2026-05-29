---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/dev/ao/reviews. Use when the user invokes /contributor or /adversary, asks Gemini to participate in a Codex/Claude/Gemini adversarial review, wants critique of a file, branch, plan, design, implementation, or concept, or wants a structured back-and-forth review with implementation and verification.
---

# Adversarial Review

## Purpose

One Contributor orchestrates the review. Adversaries critique the target and
write only to their assigned files inside a dedicated session directory under
`~/dev/ao/reviews/`.

Most Gemini invocations should be worker-mode `/adversary` calls launched by a
Contributor. If invoked as `/contributor`, Gemini may orchestrate the same
protocol.

## Commands

- `/contributor <target> [with <adversaries>]`: act as the Contributor and
  orchestrator.
- `/adversary <session-dir> <assigned-id> <round>`: act only as the assigned
  Adversary for the session and round.

Never invoke the same agent/runtime as both Contributor and Adversary in one
session. A Gemini Contributor must not call Gemini as an Adversary. If the user
names Gemini as an adversary while Gemini is contributing, record it as skipped
with reason `same-as-contributor`.

## Session Directory

Review artifacts live outside project files:

```text
~/dev/ao/reviews/YYYYMMDD-HHMM-<target-slug>/
```

Expected layout:

```text
session.yaml
target.md
contributor.md
adversaries/
  02-gemini/
    registration.yaml
    round-01.md
    verification-01.md
rounds/
implementation-summary.md
final.md
prompts/
```

Only the Contributor edits `session.yaml`, `contributor.md`, `rounds/`,
`implementation-summary.md`, and `final.md`. Adversaries edit only their own
subdirectory.

## Adversary Duties

When called as `/adversary`:

1. Read `session.yaml`, `target.md`, the assigned prompt in `prompts/`, and
   relevant target files.
2. Create or update only your assigned adversary directory.
3. Write `registration.yaml` if missing, including `id`, `agent`, `model`, and
   `status: registered`.
4. Write the assigned round file, for example
   `adversaries/02-gemini/round-01.md`, or the assigned verification file.
5. Prioritize blockers, correctness risks, hidden assumptions, missing
   evidence, operational/security/maintainability risks, and concrete
   improvements.
6. End with exactly one verdict line:
   - `Not agreed`
   - `Conditionally agreed`
   - `Agreed`

Do not edit shared session files, the target, Contributor files, or other
Adversary files. Do not play the Contributor in worker mode.

## Contributor Duties

When called as `/contributor`, own the full session:

1. Create the review directory under `~/dev/ao/reviews/`.
2. Create `session.yaml`, `target.md`, per-agent directories, and prompts.
3. Exclude the current Contributor runtime from the adversary list, then invoke
   or instruct each remaining adversary.
4. Wait for all adversaries before writing each Contributor response.
5. Continue rounds until all adversaries agree.
6. Implement agreed changes only when allowed by tool policy and human gates.
7. Request verification from all adversaries.
8. Close only after every adversary verifies with `Agreed`.

Use goal/autonomous continuation if available. Ask the human only for required
tool approvals, destructive actions, external escalation, or unresolved human
judgment.
