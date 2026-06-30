---
name: adversarial-review
description: Run a contributor-managed adversarial review using dedicated session directories under ~/.config/reviews. Use when the user invokes /contributor or /adversary, or wants a structured multi-agent back-and-forth review of a file, branch, plan, design, implementation, or concept with implementation and verification.
---

# Adversarial Review

Use this skill to run or participate in the contributor-managed adversarial
review protocol.

Read `references/PROTOCOL.md` for the authoritative protocol. In the source
repository, the same protocol lives at `skills/shared/PROTOCOL.md`.

This is the agent-neutral copy used for project-local installs. It is discovered
by whichever client is run in the project (Codex/Copilot/Antigravity via
`.agents/skills/`; Claude via `.claude/skills/`), so it names no specific agent.

## Runtime Rule

Whichever agent acts as the Contributor must not also act as an Adversary: filter
the current runtime out of the adversary list before assigning IDs. If the user
names the current agent as an adversary, skip it in `session.yaml` with reason
`same-as-contributor`.

## Entry Points

- Contributor: `<target> [with <other agents>]` — orchestrate the review.
- Adversary: `<session-dir> <assigned-id> <round-or-verification>` — act only as
  the assigned Adversary worker.

Follow `references/PROTOCOL.md` exactly for session layout, state, turn order,
human gates, implementation, and verification.
