---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/dev/ao/reviews. Use when the user invokes /contributor or /adversary, asks Claude to participate in a Codex/Antigravity/Copilot/Claude adversarial review, wants critique of a file, branch, plan, design, implementation, or concept, or wants a structured back-and-forth review with implementation and verification.
---

# Adversarial Review

Use this skill to run or participate in the contributor-managed adversarial
review protocol.

Read `references/PROTOCOL.md` for the authoritative protocol. In the source
repository, the same protocol lives at `skills/shared/PROTOCOL.md`.

## Claude Runtime Rule

When Claude is the Contributor, do not invoke Claude as an Adversary. If the
user names Claude as an adversary in a Claude-led session, skip it in
`session.yaml` with reason `same-as-contributor`.

## Entry Points

- `/contributor <target> [with Codex, Antigravity, Copilot]`: act as the Contributor and
  orchestrate the review.
- `/adversary <session-dir> <assigned-id> <round-or-verification>`: act only as
  the assigned Adversary worker.

Follow `references/PROTOCOL.md` exactly for session layout, state, turn order,
human gates, implementation, and verification.
