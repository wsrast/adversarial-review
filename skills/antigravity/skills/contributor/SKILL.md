---
name: contributor
description: Orchestrate a contributor-managed adversarial review session.
---

Invoke the `adversarial-review` skill and act as the **Contributor
orchestrator** for the target.

Follow the 'adversarial-review' skill in this plugin and read `references/PROTOCOL.md` exactly:

- Create or continue a review session under `~/dev/ao/reviews/<session>/`.
- Use autonomous continuation/goal mode when available so the human does not
  need to relay every round.
- Assign adversary IDs, create per-agent directories, and write prompts under
  `prompts/`.
- Invoke intended adversaries through available CLIs/integrations. Default to
  the other available adversaries when none are named (see Supported Agents).
- Do not invoke Antigravity as an Adversary when Antigravity is the
  Contributor. If Antigravity is named as an adversary, skip it with reason
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

## Arguments

The user will invoke this skill with the argument: `<target> [with Codex, Claude, Copilot]`.
Parse the target and any optional comma-separated adversaries from the prompt text, then use them to orchestrate the review.
