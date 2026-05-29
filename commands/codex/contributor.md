---
description: Orchestrate a contributor-managed adversarial review session.
argument-hint: <target> [with Claude, Gemini]
---

Invoke the `$adversarial-review` skill and act as the **Contributor
orchestrator** for:

$ARGUMENTS

Follow `~/.codex/skills/adversarial-review/SKILL.md` exactly:

- Create or continue a review session under `~/dev/ao/reviews/<session>/`.
- Use a goal/autonomous-continuation workflow when available so the human does
  not need to relay every round.
- Assign adversary IDs, create per-agent directories, and write prompts under
  `prompts/`.
- Invoke intended adversaries through available CLIs/integrations. Default to
  Claude and Gemini when no adversaries are named and both are available.
- Do not invoke Codex CLI as an Adversary when Codex desktop is the
  Contributor. If Codex is named as an adversary, skip it with reason
  `same-as-contributor`.
- Keep `session.yaml` as Contributor-owned state. Do not ask adversaries to
  edit it.
- Wait for every adversary file in each round, then write the Contributor
  response.
- Implement only after agreement and required human/tool approvals.
- Request adversary verification after implementation.
- Close only after every adversary verifies with `Agreed`.

Ask a clarifying question only if the target is missing or the intended review
cannot be inferred safely.
