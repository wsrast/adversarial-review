---
description: Orchestrate a contributor-managed adversarial review session.
argument-hint: <target> [with Claude, Copilot, Antigravity]
---

Invoke the `$adversarial-review` skill and act as the **Contributor
orchestrator** for:

$ARGUMENTS

Follow `~/.codex/skills/adversarial-review/SKILL.md` exactly:

- Create or continue a review session under `~/.config/reviews/<session>/`.
- Use a goal/autonomous-continuation workflow when available so the human does
  not need to relay every round.
- Assign adversary IDs, create per-agent directories, and write prompts under
  `prompts/`.
- Invoke intended adversaries through available CLIs/integrations. Default to
  the other available adversaries when none are named (see Supported Agents).
- Do not invoke Codex CLI as an Adversary when Codex desktop is the
  Contributor. If Codex is named as an adversary, skip it with reason
  `same-as-contributor`.
- Keep `session.yaml` as Contributor-owned state. Do not ask adversaries to
  edit it.
- Wait for every non-blocked adversary's file in each round, then write the
  Contributor response.
- If an adversary fails operationally (token/quota, network, cannot be invoked),
  drop it automatically and continue with the rest; halt for the human only if
  no adversary would remain, or the session opts into human-gated failures (see
  PROTOCOL.md).
- Implement only after agreement and required human/tool approvals.
- Request adversary verification after implementation.
- Close only after every non-blocked adversary verifies with `Agreed`.

Ask a clarifying question only if the target is missing or the intended review
cannot be inferred safely.
