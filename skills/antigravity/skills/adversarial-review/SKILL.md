---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/dev/ao/reviews. Use when the user invokes /contributor or /adversary, asks Antigravity to participate in a multi-agent adversarial review, wants critique of a file, branch, plan, design, implementation, or concept, or wants a structured back-and-forth review with implementation and verification.
---

# Adversarial Review

Use this skill to run or participate in the contributor-managed adversarial
review protocol.

Read `references/PROTOCOL.md` for the authoritative protocol. In the source
repository, the same protocol lives at `skills/shared/PROTOCOL.md`.

## Antigravity Runtime Rule

When Antigravity is the Contributor, do not invoke Antigravity as an Adversary. If the
user names Antigravity as an adversary in an Antigravity-led session, skip it in
`session.yaml` with reason `same-as-contributor`.

## Entry Points

The user or Contributor invokes these workflows by instructing the agent to run the `contributor` or `adversary` skill. The agent routes these requests using the following argument schemas:

- `contributor` skill: `<target> [with Codex, Claude, Copilot]` (acts as the Contributor and orchestrates the review).
- `adversary` skill: `<session-dir> <assigned-id> <round-or-verification>` (acts only as the assigned Adversary worker).

Follow `references/PROTOCOL.md` exactly for session layout, state, turn order,
human gates, implementation, and verification.
