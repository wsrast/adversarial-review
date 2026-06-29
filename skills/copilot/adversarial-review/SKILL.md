---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/.config/reviews. Use when the user invokes /contributor or /adversary, asks Copilot to participate in a multi-agent adversarial review, wants critique of a file, branch, plan, design, implementation, or concept, or wants a structured back-and-forth review with implementation and verification.
---

# Adversarial Review

Use this skill to run or participate in the contributor-managed adversarial
review protocol.

Read `references/PROTOCOL.md` for the authoritative protocol. In the source
repository, the same protocol lives at `skills/shared/PROTOCOL.md`.

## Copilot Runtime Rule

When Copilot is the Contributor, do not invoke the Copilot CLI as an Adversary.
Use non-Copilot adversaries (any other available agent; see Supported Agents). If the user
names Copilot as an adversary in a Copilot-led session, skip it in
`session.yaml` with reason `same-as-contributor`.

## Entry Points

Copilot CLI exposes only built-in slash commands (`/skills`, `/agent`, …), not
user-defined command wrappers. Invoke these workflows by asking Copilot to use
the `adversarial-review` skill with the appropriate role and arguments:

- Contributor: `<target> [with Codex, Claude, Antigravity]` — act as the
  Contributor and orchestrate the review.
- Adversary: `<session-dir> <assigned-id> <round-or-verification>` — act only as
  the assigned Adversary worker.

Follow `references/PROTOCOL.md` exactly for session layout, state, turn order,
human gates, implementation, and verification.
