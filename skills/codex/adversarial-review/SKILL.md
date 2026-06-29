---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/.config/reviews. Use when the user invokes /contributor or /adversary, asks Codex to orchestrate the other agents as adversaries, wants adversarial critique of a file, branch, plan, design, implementation, or concept, or wants a structured back-and-forth review with implementation and verification.
---

# Adversarial Review

Use this skill to run or participate in the contributor-managed adversarial
review protocol.

Read `references/PROTOCOL.md` for the authoritative protocol. In the source
repository, the same protocol lives at `skills/shared/PROTOCOL.md`.

## Codex Runtime Rule

When Codex is the Contributor, do not invoke the Codex CLI as an Adversary. Use
non-Codex adversaries (any other available agent; see Supported Agents). If the user names Codex as an
adversary in a Codex-led session, skip it in `session.yaml` with reason
`same-as-contributor`.

## Entry Points

- `/contributor <target> [with Claude, Copilot, Antigravity]`: act as the Contributor and
  orchestrate the review.
- `/adversary <session-dir> <assigned-id> <round-or-verification>`: act only as
  the assigned Adversary worker.

Follow `references/PROTOCOL.md` exactly for session layout, state, turn order,
human gates, implementation, and verification.
